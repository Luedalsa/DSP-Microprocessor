library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity divisor is
    Generic ( WIDTH : integer := 32 );
    Port ( 
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        start_i     : in  STD_LOGIC; -- Pulso de 1 ciclo para iniciar
        dividend_i  : in  STD_LOGIC_VECTOR (WIDTH-1 downto 0);
        divisor_i   : in  STD_LOGIC_VECTOR (WIDTH-1 downto 0);
        
        quotient_o  : out STD_LOGIC_VECTOR (WIDTH-1 downto 0);
        remainder_o : out STD_LOGIC_VECTOR (WIDTH-1 downto 0);
        busy_o      : out STD_LOGIC; -- '1' mientras calcula (CPU libre para otras cosas)
        done_o      : out STD_LOGIC  -- '1' cuando el resultado está listo
    );
end divisor;

architecture Behavioral of divisor is
    -- Estados de la FSM
    type state_type is (IDLE, CALC, FINISH);
    signal state : state_type;

    -- Registros internos
    -- Usamos un registro doble (2*WIDTH) para el algoritmo de restauración
    signal reg_work : unsigned(2*WIDTH-1 downto 0); 
    signal reg_div  : unsigned(WIDTH-1 downto 0);
    signal count    : integer range 0 to WIDTH; -- Contador de ciclos

begin

    process(clk, reset)
        -- MOVED: Variable declaration must be here
        variable v_work : unsigned(2*WIDTH downto 0);
    begin
        if reset = '1' then
            state       <= IDLE;
            busy_o      <= '0';
            done_o      <= '0';
            quotient_o  <= (others => '0');
            remainder_o <= (others => '0');
            reg_work    <= (others => '0');
            count       <= 0;
            
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    done_o <= '0';
                    if start_i = '1' then
                        -- Cargar operandos.
                        reg_work <= (others => '0');
                        reg_work(WIDTH-1 downto 0) <= unsigned(dividend_i);
                        reg_div  <= unsigned(divisor_i);
                        
                        count    <= WIDTH; -- 32 ciclos para 32 bits
                        busy_o   <= '1';   -- Marca ocupado
                        state    <= CALC;
                    else
                        busy_o   <= '0';
                    end if;

                when CALC =>
                    if count > 0 then
                        -- Lógica Correcta con Variables (Restoring Division)
                        
                        -- 1. Cargar variable con shift a la izquierda (concatena '0')
                        --    Usamos reg_work (valor actual) para el cálculo
                        v_work := unsigned(reg_work(2*WIDTH-1 downto 0)) & '0';
                        
                        -- 2. Resta de prueba (Check bit alto)
                        if v_work(2*WIDTH downto WIDTH) >= reg_div then
                            v_work(2*WIDTH downto WIDTH) := v_work(2*WIDTH downto WIDTH) - reg_div;
                            v_work(0) := '1';
                        end if;
                        
                        -- 3. Actualizar registro y contador
                        reg_work <= v_work(2*WIDTH-1 downto 0);
                        count    <= count - 1;
                        
                    else
                        state <= FINISH;
                    end if;

                when FINISH =>
                    busy_o      <= '0';
                    done_o      <= '1';
                    quotient_o  <= std_logic_vector(reg_work(WIDTH-1 downto 0));
                    remainder_o <= std_logic_vector(reg_work(2*WIDTH-1 downto WIDTH));
                    state       <= IDLE; 
            end case;
        end if;
    end process;

end Behavioral;