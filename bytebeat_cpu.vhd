----------------------------------------------------------------------------------
-- Company:        Universidad de Guadalajara
-- Engineer:       Luis Eduardo Alvarez Sandoval
-- 
-- Create Date:    20:13:51 10/01/2025 
-- Design Name:    Algorithmic sample generator
-- Module Name:    cpu - Behavioral 
-- Project Name:   Algorithmic sample generator
-- Target Devices: Digital-analogic converters
-- Tool versions: 
-- Description:    Von Neumann architecture, basic pipelining
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

-- Arquitectura: Harvard Modificada con Pipelining básico.
-- Propósito: Generación algorítmica de muestras.
-- Características:
--   - ALU de un ciclo.
--   - Manejo de Pila (Push/Pop) en múltiples ciclos.
--   - Instrucción OUT reinicia el PC para el bucle de sampleo.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.definitions_pkg.all; -- Contiene las constantes de Opcodes (OP_LDI, OP_PUSH, etc.)

entity bytebeat_cpu is
    port (
        CLOCK             : in std_logic;
        RESET             : in std_logic; 
        INS_WRITE_ENABLED : in std_logic; -- '1' = Modo Carga (Escribe en RAM), '0' = Modo Ejecución
        DATA_IN           : in std_logic_vector(31 downto 0); -- Datos entrada para programación
        AUDIO_OUT         : out std_logic_vector(7 downto 0)  -- Salida al DAC de audio
    );
end entity bytebeat_cpu;

architecture structural of bytebeat_cpu is

    -- 1. COMPONENTES DEL SISTEMA
    component RAM is
        generic (
            DATA_WIDTH : integer := 32;
            ADDR_WIDTH : integer := 6
        );
        port (
				clk    : in std_logic;
				
				we_a   : in std_logic;
				addr_a : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
				din_a  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
				dout_a : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        
				we_b   : in std_logic;
				addr_b : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
				din_b  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
				dout_b : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
    end component;

    component alu is
        port (
            operand_A   : in  unsigned(31 downto 0);
            operand_B   : in  unsigned(31 downto 0);
            alu_op      : in  std_logic_vector(3 downto 0);
            result      : out unsigned(31 downto 0)
        );
    end component;

    -- 2. SEÑALES INTERNAS
    
    -- Contadores de Programa y Pila
    signal pc          : unsigned(5 downto 0);
    signal pc_old      : unsigned(5 downto 0); -- Respaldo para saltos o esperas de memoria
    --signal sp          : unsigned(5 downto 0) := (others => '1'); -- Stack Pointer (apunta al tope)
    --signal sp_sub      : unsigned(5 downto 0) := (others => '0'); -- Auxiliar para operaciones de pila
    
    -- Banderas de Control de Flujo
    signal was_jump    : std_logic;
    --signal was_pop     : std_logic;

    -- Máquina de Estados
    --type state_type is (FETCH_EXECUTE, WAIT_MEM, WRITE_BACK);
    --signal current_state : state_type := FETCH_EXECUTE;

    -- Señales de ALU y Registros
    signal alu_operand_a : unsigned(31 downto 0);
    signal alu_operand_b : unsigned(31 downto 0);
    signal alu_result    : unsigned(31 downto 0);
    signal alu_op_signal : std_logic_vector(3 downto 0);

    -- Registros de Propósito General
    signal reg_a : unsigned(31 downto 0) := (others => '0'); -- Acumulador principal
    signal reg_b : unsigned(31 downto 0) := (others => '0'); -- Operando secundario
    signal reg_t : unsigned(31 downto 0) := (others => '0'); -- Contador global de muestras (t)

    -- Interfaz de Memoria
    --signal ram_address      : std_logic_vector(5 downto 0);
	 signal rinstruction_address      : std_logic_vector(5 downto 0);
	 signal rdata_address      : std_logic_vector(5 downto 0);
    --signal ram_data_in      : std_logic_vector(31 downto 0);
	 signal rinstruction_in : std_logic_vector(31 downto 0);
	 signal rdata_in        : std_logic_vector(31 downto 0);
    --signal ram_data_out     : std_logic_vector(31 downto 0);
	 signal rinstruction_out : std_logic_vector(31 downto 0); -- Viene de dout_a
	 signal rdata_out        : std_logic_vector(31 downto 0); -- Viene de dout_b
    --signal ram_write_enable : std_logic;
	 signal rinstruction_we : std_logic;
	 signal rdata_we : std_logic;

begin

    -- Instanciación de Memoria RAM
    Memory_Unit : RAM
        generic map (
            DATA_WIDTH => 32,
            ADDR_WIDTH => 6
        )
        port map (
			  clk    => CLOCK,
		  
			  we_a   => rinstruction_we,
			  addr_a => rinstruction_address,
			  din_a  => rinstruction_in,
			  dout_a => rinstruction_out,
			  
			  we_b   => rdata_we,
			  addr_b => rdata_address,
			  din_b  => rdata_in,
			  dout_b => rdata_out
        );

    -- Instanciación de la ALU
    ALU_Unit : alu
        port map (
            operand_A => alu_operand_a,
            operand_B => alu_operand_b,
            alu_op    => alu_op_signal,
            result    => alu_result
        );

    -- Conexiones del Datapath a la ALU
    alu_operand_a <= reg_a;
    alu_operand_b <= reg_b;
    -- Extrae el opcode de la instrucción actual (bits 30-27) para controlar la ALU
    alu_op_signal <= rinstruction_out(30 downto 27); 

    -- PROCESO PRINCIPAL: UNIDAD DE CONTROL Y DATAPATH
    process(CLOCK, RESET)
    begin
        if RESET = '1' then
            pc            <= (others => '0');
            --pc_old        <= (others => '0');
            reg_t         <= (others => '0');
            AUDIO_OUT     <= (others => '0');
            rinstruction_address   <= (others => '0');
            --rdata_address   <= (others => '0');
            was_jump      <= '0';
            --was_pop       <= '0';
            --current_state <= FETCH_EXECUTE;
            
        elsif rising_edge(CLOCK) then
            
            -- Reiniciar bandera de salto por defecto
            was_jump <= '0';

            ------------------------------------------------------------
            -- MODO 1: EJECUCIÓN NORMAL (INS_WRITE_ENABLED = '0')
            ------------------------------------------------------------
            if INS_WRITE_ENABLED = '0' then 
                rinstruction_we <= '0';
                rdata_we <= '0';
                
                -- Avance normal del PC (Pipeline Fetch)
                pc <= pc + 1;
                pc_old <= pc;
                rinstruction_address <= std_logic_vector(pc(5 downto 0));

                --case current_state is

                    --when FETCH_EXECUTE =>
                        -- Detección de operaciones de Memoria/Stack que requieren ciclos de espera
                        -- Se comprueba si NO es carga inmediata (LDI) y si el bit de control (26) está activo
                        --if rinstruction_out(26) = '1' then 
                            --if was_jump = '0' then
                                --pc <= pc_old; -- Retener PC si hay acceso a memoria
                            --end if;
                            --current_state <= WAIT_MEM;
                        --end if;
                        
                        -- Decodificación de Instrucciones de Control (Stack, Jumps)
                        --if rinstruction_out(31 downto 27) /= OP_LDI then
                            case rinstruction_out(26 downto 24) is
                                when OP_PUSH =>
                                     --rdata_address      <= std_logic_vector(sp);
                                     rdata_in      <= std_logic_vector(reg_a);
                                     --sp               <= sp - 1;
                                     --sp_sub           <= sp_sub -1;
                                     rdata_we <= '1'; -- Escribir en Stack

                                when OP_POP =>
                                     --sp          <= sp + 1;
                                     --sp_sub      <= sp_sub + 1;
                                     --rdata_address <= std_logic_vector(sp_sub);
												 reg_b <= unsigned(rdata_out);
                                     --was_pop     <= '1'; -- Marcar para leer dato en WRITE_BACK

                                when OP_JMP =>
                                     pc       <= unsigned(rinstruction_out(5 downto 0));
                                     was_jump <= '1';

                                when OP_JZ =>
                                    if reg_a = x"00000000" then
                                     pc       <= unsigned(rinstruction_out(5 downto 0));
                                     was_jump <= '1';
                                     end if;

                                when OP_LDI => 
                                     -- Carga Inmediata: Toma 27 bits de la instrucción y los pone en B
                                     reg_b <= unsigned("00000000" & rinstruction_out(23 downto 0));

                                when others => null; -- NOP
                            end case;
                        --end if;

                        -- Ejecución de ALU y Movimiento de Datos
                        if rinstruction_out(31) = '0' then
                            -- Operaciones aritméticas estándar (resultado de ALU a Reg A)
                            if rinstruction_out(31 downto 27) /= OP_NOP then
                                reg_a <= alu_result;
                            end if;
                        else
                            -- Operaciones especiales (Bit 31 alto)
                            case rinstruction_out(31 downto 27) is
                                when OP_MOV =>
                                     reg_a <= reg_t; -- Mover contador de tiempo a A

                                when OP_SWP => 
                                     -- Intercambio de registros A y B (Swap) en un ciclo
                                     reg_a <= reg_b;
                                     reg_b <= reg_a;

                                when OP_OUT => 
                                     -- Salida de Audio (Bytebeat Core)
                                     AUDIO_OUT <= std_logic_vector(reg_a(7 downto 0));
                                     pc        <= (others => '0'); -- RESET DEL PC (Bucle infinito por sample)
                                     reg_t     <= reg_t + 1;       -- Siguiente instante de tiempo t

                                when others => null;
                            end case;
                        end if;

                    --when WAIT_MEM =>
                        -- Ciclo de espera para sincronización de memoria
                        --current_state <= WRITE_BACK;

                    --when WRITE_BACK => 
                        -- Finalización de lectura de memoria (POP)
                        --if was_pop = '1' then
                            --reg_b <= unsigned(ram_data_out);
                            --was_pop <= '0';
                        --end if;
                        --current_state <= FETCH_EXECUTE;

                --end case;

            ------------------------------------------------------------
            -- MODO 2: CARGA DE PROGRAMA (INS_WRITE_ENABLED = '1')
            ------------------------------------------------------------
            else 
                rinstruction_we <= '1';
                
                --case current_state is
                    --when FETCH_EXECUTE =>
                        -- Escribir instrucción externa en la dirección actual del PC
                        rinstruction_address <= std_logic_vector(pc(5 downto 0));
                        rinstruction_in <= DATA_IN;
                        pc <= pc + 1; -- Avanzar a siguiente dirección de memoria
                        
                    --when others => null;
                --end case;
            end if;
        end if;
    end process;

end architecture structural;