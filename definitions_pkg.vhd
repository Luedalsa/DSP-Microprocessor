-- definitions_pkg.vhd
library ieee;
use ieee.std_logic_1164.all;

-- La utilidad de las instrucciones se basa en su relevancia con el bytebeat C-compatible
-- Cada instrucción tiene parámetros (su tamaño es dependiente)
-- "t" no es un registro de destino

package definitions_pkg is

    -- NOP (Sin operación)
    constant OP_NOP  : std_logic_vector(4 downto 0) := "00000";

    -- Operaciones Aritméticas
    constant OP_ADD  : std_logic_vector(3 downto 0) := "0001"; -- Suma no op_params ADD a, b ; Sólo se necesita 1 configuración
    constant OP_SUB  : std_logic_vector(3 downto 0) := "0010"; -- Resta op_params 1 bit: SUB a, b ; SUB b, a ; Sólo se necesitan 2 configuraciones
    constant OP_MUL  : std_logic_vector(3 downto 0) := "0011"; -- Multiplicación no op_params: MUL a, b ;
    constant OP_DIV  : std_logic_vector(3 downto 0) := "0100"; -- División op_params 1 bit: DIV a, b ; DIV b, a ; 
    constant OP_MOD  : std_logic_vector(3 downto 0) := "0101"; -- Módulo op_params 1 bit: MOD a, b ; MOD b, a ; 
    constant OP_GT   : std_logic_vector(3 downto 0) := "0110";
    constant OP_LT   : std_logic_vector(3 downto 0) := "0111";

    -- Operaciones Lógicas y a Nivel de Bit (Bitwise)
    constant OP_AND  : std_logic_vector(3 downto 0) := "1000"; -- AND lógico no op_params AND a, b ;
    constant OP_OR   : std_logic_vector(3 downto 0) := "1001"; -- OR lógico no op_params OR a, b ;
    constant OP_XOR  : std_logic_vector(3 downto 0) := "1010"; -- XOR lógico no op_params XOR a, b ;
    constant OP_NOT  : std_logic_vector(3 downto 0) := "1011"; -- NOT lógico op_params 1 bit: NOT a ; NOT b ;
    constant OP_SHR  : std_logic_vector(3 downto 0) := "1100"; -- Desplazamiento a la derecha (t >> n) op_params 1 bit: SHR a, b ; SHR b, a ; 
    constant OP_SHL  : std_logic_vector(3 downto 0) := "1101"; -- Desplazamiento a la izquierda (t << n) op_params 1 bit: SHL a, b ; SHL b, a ; 

    -- Operaciones de Transferencia de Datos
    constant OP_MOV  : std_logic_vector(4 downto 0) := "10000"; -- Mover dato op_params 1 bit: MOV a, t ; MOV b, t
    constant OP_LDI  : std_logic_vector(2 downto 0) := "111"; -- Cargar Inmediato (cargar un valor constante de 32 bit a un registro) op_params 33 bit: LDI a, c ; LDI b, c ;
	 
	 -- Operación de intercambio
	 constant OP_SWP : std_logic_vector(4 downto 0) := "10100";  -- Intercambia la salida del registro a y b

    -- Operaciones de Salto y Control de Flujo
    constant OP_JMP  : std_logic_vector(2 downto 0) := "001"; -- Salto Incondicional (Jump)
    constant OP_JZ   : std_logic_vector(2 downto 0) := "010"; -- Compara registro a con 0 y salta si es igual - op_params 4 bit: JZ dir
    constant OP_JNE  : std_logic_vector(2 downto 0) := "011"; -- Salto si no es igual

    -- Operaciones de Pila (Stack)
    constant OP_PUSH : std_logic_vector(2 downto 0) := "100"; -- Empujar a la pila, solo con a debido a optimizaciones en cálculos de ALU (siempre se guardan en a) ; no op_params: PUSH a
    constant OP_POP  : std_logic_vector(2 downto 0) := "101"; -- Sacar de la pila, siempre en b para usarse inmediatamente después de calcular un valor en a ; no op_params: POP b

    -- Operaciones de Entrada/Salida
    constant OP_OUT  : std_logic_vector(4 downto 0) := "11111"; -- Salida a un puerto (para el sonido)

end package definitions_pkg;