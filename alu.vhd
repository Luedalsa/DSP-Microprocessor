library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.definitions_pkg.all; -- Importante para usar tus constantes (OP_ADD, etc.)

entity alu is
    port (
        operand_A   : in  unsigned(31 downto 0);
        operand_B   : in  unsigned(31 downto 0);
        alu_op      : in  std_logic_vector(3 downto 0);
        result      : out unsigned(31 downto 0)
    );
end entity alu;

architecture behavioral of alu is
begin

    process(operand_A, operand_B, alu_op)
    begin
        -- Valor por defecto para evitar latches inferidos
        result <= (others => '0');

        case alu_op is
            -- Aritmética Básica
            when OP_ADD => 
                result <= operand_A + operand_B;
                
            when OP_SUB => 
                result <= operand_A - operand_B;
                
            when OP_MUL => 
                -- Multiplicación devuelve el doble de bits, recortamos a los 32 bajos (wrap-around)
                result <= resize(operand_A * operand_B, 32);  -- <== caro pero no tanto
                
            --when OP_DIV =>
                -- Protección contra división por cero
                --if operand_B = 0 then
                    --result <= (others => '0');
                --else
                    --result <= operand_A / operand_B;  -- <== ESTO ES MUY CARO
                --end if;
                
            --when OP_MOD =>
                -- Protección contra módulo cero
                --if operand_B = 0 then
                    --result <= (others => '0');
                --else
                    --result <= operand_A mod operand_B;
                --end if;

            -- Comparaciones (Devuelven 1 si es verdadero, 0 si es falso, estilo C)
            when OP_GT =>
                if operand_A > operand_B then
                    result <= to_unsigned(1, 32);
                else
                    result <= (others => '0');
                end if;
                
            when OP_LT =>
                if operand_A < operand_B then
                    result <= to_unsigned(1, 32);
                else
                    result <= (others => '0');
                end if;

            -- Lógica Bitwise
            when OP_AND =>
                result <= operand_A and operand_B;
                
            when OP_OR =>
                result <= operand_A or operand_B;
                
            when OP_XOR =>
                result <= operand_A xor operand_B;
                
            when OP_NOT =>
                result <= not operand_A; -- Opera solo sobre A (el acumulador)

            -- Desplazamientos
            when OP_SHR =>
                -- Convierte B a entero para saber cuántos bits desplazar
                result <= shift_right(operand_A, to_integer(operand_B(4 downto 0)));
                
            when OP_SHL =>
                result <= shift_left(operand_A, to_integer(operand_B(4 downto 0)));

            when others =>
					 null;
        end case;
    end process;

end architecture behavioral;