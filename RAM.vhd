library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RAM is
    generic (
        DATA_WIDTH : integer := 32;
        ADDR_WIDTH : integer := 6
    );
    port (
        clk    : in std_logic;
        
        -- Puerto A (Usado para Instrucciones en tu CPU)
        we_a   : in std_logic;
        addr_a : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
        din_a  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        dout_a : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        
        -- Puerto B (Usado para Stack/Datos en tu CPU)
        we_b   : in std_logic;
        addr_b : in std_logic_vector(ADDR_WIDTH - 1 downto 0);
        din_b  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        dout_b : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity RAM;

architecture rtl of RAM is
    -- Definición del tipo de array para la memoria
    -- Profundidad calculada automáticamente basada en ADDR_WIDTH (2^6 = 64 palabras)
    type ram_type is array (0 to (2**ADDR_WIDTH)-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    
    -- Inicialización de la memoria en ceros (útil para simulación, aunque en síntesis depende de la FPGA)
    signal ram_block : ram_type := (others => (others => '0'));

begin

    process(clk)
    begin
        if rising_edge(clk) then
            -----------------------------------------------------
            -- Operación del Puerto A
            -----------------------------------------------------
            if we_a = '1' then
                ram_block(to_integer(unsigned(addr_a))) <= din_a;
                -- Modo Read-During-Write: En este template, la salida reflejará el dato escrito
                -- o el dato anterior dependiendo de la síntesis, pero para asegurar consistencia
                -- generalmente se infiere "Read First" o "Write First" según la herramienta.
            end if;
            -- Lectura sincrónica (Synchronous Read)
            dout_a <= ram_block(to_integer(unsigned(addr_a)));

            -----------------------------------------------------
            -- Operación del Puerto B
            -----------------------------------------------------
            if we_b = '1' then
                ram_block(to_integer(unsigned(addr_b))) <= din_b;
            end if;
            -- Lectura sincrónica (Synchronous Read)
            dout_b <= ram_block(to_integer(unsigned(addr_b)));
            
        end if;
    end process;

end architecture rtl;