library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.definitions_pkg.all; -- Asegúrate de que este paquete esté compilado

entity bytebeat_cpu_tb is
end bytebeat_cpu_tb;

architecture behavior of bytebeat_cpu_tb is 

    -- Declaración del componente (Unit Under Test)
    component bytebeat_cpu
    port(
         CLOCK : in  std_logic;
         RESET : in  std_logic;
         INS_WRITE_ENABLED : in  std_logic;
         DATA_IN : in  std_logic_vector(31 downto 0);
         AUDIO_OUT : out  std_logic_vector(7 downto 0)
        );
    end component;
    
    -- Entradas
    signal CLOCK : std_logic := '0';
    signal RESET : std_logic := '0';
    signal INS_WRITE_ENABLED : std_logic := '0';
    signal DATA_IN : std_logic_vector(31 downto 0) := (others => '0');

    -- Salidas
    signal AUDIO_OUT : std_logic_vector(7 downto 0);

    -- Definición del periodo de reloj del CPU (Ej. 50 MHz -> 20 ns)
    -- Esto es independiente de la frecuencia de audio.
    constant CLOCK_period : time := 20 ns; 
 
begin
 
    -- Instancia de la UUT
    uut: bytebeat_cpu port map (
          CLOCK => CLOCK,
          RESET => RESET,
          INS_WRITE_ENABLED => INS_WRITE_ENABLED,
          DATA_IN => DATA_IN,
          AUDIO_OUT => AUDIO_OUT
        );

    -- Proceso de Reloj (Hardware Clock)
    CLOCK_process :process
    begin
        CLOCK <= '0';
        wait for CLOCK_period/2;
        CLOCK <= '1';
        wait for CLOCK_period/2;
    end process;
 
    -- =================================================================
    -- PROCESO DE GRABACIÓN DE AUDIO (DAC SIMULADO)
    -- =================================================================
    -- Modificado: Graba asíncronamente cada 125 us (8000 Hz)
    file_writer_process : process
        file file_pointer : text open write_mode is "audio_output.txt";
        variable line_el : line;
    begin
        -- Esperamos un poco antes de empezar a grabar para evitar el ruido del reset
        wait for 100 ns;

        loop
            -- Frecuencia de muestreo: 8000 Hz -> 125 us
            wait for 125 us; 
            
            -- Verificación de seguridad: Solo grabamos si NO estamos cargando el programa
            if INS_WRITE_ENABLED = '0' and RESET = '0' then
                -- Escribimos el valor entero de la salida actual en el archivo
                write(line_el, to_integer(unsigned(AUDIO_OUT)));
                writeline(file_pointer, line_el);
            end if;
            
            -- Si la simulación se detiene externamente, el loop se detiene.
        end loop;
    end process;

    -- Proceso de Estímulos (Carga y Control)
    stim_proc: process
        -- Helper para escribir instrucciones
        procedure write_instruction_with_data(constant raw_instr : in std_logic_vector(31 downto 0)) is
        begin
            DATA_IN <= raw_instr;
            wait for CLOCK_period;
        end procedure;

    begin		
        -- FASE 1: CARGA DEL PROGRAMA
        report "Iniciando Testbench...";
        
        RESET <= '1';
        INS_WRITE_ENABLED <= '1'; 
        wait for CLOCK_period * 5; -- Espera un poco más para estabilizar
        RESET <= '0';
        
        report "Cargando programa...";

        -- Secuencia de instrucciones reconstruida (Tu programa Bytebeat)
        write_instruction_with_data("0" & OP_AND &  "000000000000000000000001011");
        write_instruction_with_data("00000" & OP_PUSH  & "000000000000000000000110");
        write_instruction_with_data(OP_MOV & OP_POP  & "000000000000000000000110");
        write_instruction_with_data("0" & OP_MUL &  "000000000000000000000001011");
        --write_instruction_with_data(OP_LDI &        "000000000000000000000001011");
        write_instruction_with_data("0" & OP_SHR & OP_POP  & "000000000000000000000110");
        write_instruction_with_data("0" & OP_OR &  "000000000000000000000001011");
        write_instruction_with_data(OP_MOV & OP_PUSH  & "000000000000000000000110");
        --write_instruction_with_data(OP_LDI &        "000000000000000000000000010");
        write_instruction_with_data(OP_SWP & "000000000000000000000000000"); 
        write_instruction_with_data("0" & OP_ADD & OP_POP  & "000000000000000000000000");
        --write_instruction_with_data(OP_LDI &        "000000000000000000000000010");
        write_instruction_with_data("0" & OP_SHR & "000000000000000000000000000");
        write_instruction_with_data(OP_OUT & "000000000000000000000000000"); -- OUT resetea PC

        -- NOPs de relleno
        write_instruction_with_data((others => '0'));
        write_instruction_with_data((others => '0'));
        
        DATA_IN <= (others => '0');
        report "Carga finalizada." severity note;

        -- FASE 2: EJECUCIÓN
        report "Ejecutando Bytebeat...";
        INS_WRITE_ENABLED <= '0';
        
        -- Reset breve para iniciar PC en 0
        RESET <= '1';
        wait for CLOCK_period * 2;
        RESET <= '0';
        
        -- Ejecución prolongada para generar suficiente audio
        -- 4 segundos de audio a 8kHz = 32,000 muestras
        wait for 500 ms; 
        
        report "Simulación completada." severity note;
        assert false report "Fin normal de la simulación" severity failure;
        wait;
    end process;

end behavior;