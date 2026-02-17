-- definitions_pkg.vhd
library ieee;
use ieee.std_logic_1164.all;

-- "t" no es un registro de destino
-- OP de 4 bits son operaciones generales, OP de 3 bits son sub-operaciones
package definitions_pkg is

    constant ALU_OP  : std_logic := '0';
    -- Operaciones de la Unidad Aritmético Lógica (Combinacional)
	 
    constant OP_ADD  : std_logic_vector(3 downto 0) := "0001";
    -- Suma de registros: a + b
    constant OP_SUB  : std_logic_vector(3 downto 0) := "0010";
    -- Resta de registros: a - b | b - a
    constant OP_AND  : std_logic_vector(3 downto 0) := "1000";
    -- AND bit a bit
    constant OP_OR   : std_logic_vector(3 downto 0) := "1001";
    -- OR bit a bit
    constant OP_XOR  : std_logic_vector(3 downto 0) := "1010";
    -- XOR bit a bit
    constant OP_NOT  : std_logic_vector(3 downto 0) := "1011";
    -- NOT lógico: ~a | ~b
    constant OP_SHR  : std_logic_vector(3 downto 0) := "1100";
    -- Desplazamiento a la derecha (Shift Right)
    constant OP_SHL  : std_logic_vector(3 downto 0) := "1101";
    -- Desplazamiento a la izquierda (Shift Left)
    constant OP_GT   : std_logic_vector(3 downto 0) := "0110";
    -- Mayor que (Greater Than)
    constant OP_LT   : std_logic_vector(3 downto 0) := "0111";
    -- Menor que (Less Than)
	 
    constant GEN_OP  : std_logic := '1';
    -- Operaciones de propósito general y control (Y ALU desacoplada)

    constant OP_DIV  : std_logic_vector(3 downto 0) := "0011";
    -- División: a / b | b / a
    constant OP_MOD  : std_logic_vector(3 downto 0) := "0100";
    -- Módulo: a % b | b % a
    constant OP_RECD : std_logic_vector(3 downto 0) := "0101";
    -- Recuperar cociente de división desacoplada
    constant OP_MUL  : std_logic_vector(3 downto 0) := "0110";
    -- Multiplicación: a * b
    constant OP_RECM : std_logic_vector(3 downto 0) := "0111";
    -- Recuperar producto de multiplicación
    constant OP_NOP  : std_logic_vector(3 downto 0) := "0000";
    -- Sin operación (No Operation)
    constant OP_MOV  : std_logic_vector(3 downto 0) := "0000";
    -- Mover dato a registro 't'
    constant OP_SWP  : std_logic_vector(3 downto 0) := "0001";
    -- Intercambiar datos entre registros a y b
    constant OP_OUT  : std_logic_vector(3 downto 0) := "1111";
    -- Escribir dato a puerto de salida (ej. audio)
    constant OP_IN   : std_logic_vector(3 downto 0) := "1110";
    -- Leer dato de puerto de entrada (Próximo a implementar)
	 
	 --suboperaciones
	 
    constant OP_LDI  : std_logic_vector(2 downto 0) := "111";
    -- Cargar inmediato de 32 bits a registro
    constant OP_JMP  : std_logic_vector(2 downto 0) := "001";
    -- Salto incondicional
    constant OP_JZ   : std_logic_vector(2 downto 0) := "010";
    -- Salto si es cero (Jump if Zero)
    constant OP_JNE  : std_logic_vector(2 downto 0) := "011";
    -- Salto si no es igual (Jump if Not Equal)
    constant OP_PUSH : std_logic_vector(2 downto 0) := "100";
    -- Empujar registro 'a' a la pila
    constant OP_POP  : std_logic_vector(2 downto 0) := "101";
    -- Extraer de la pila al registro 'b'

end package definitions_pkg;