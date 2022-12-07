library ieee;
use ieee.std_logic_1164.all;

entity CarryWriteChecker is
    port(
        instruction: in std_logic_vector(15 downto 0);
        carry_write: out std_logic
    );
end entity CarryWriteChecker;

architecture behavioural of CarryWriteChecker is
begin
    check_carry_write: process(instruction)
        variable opcode: std_logic_vector(3 downto 0);
    begin
        opcode := instruction(15 downto 12);
        if (opcode = "0001" or opcode = "0000") then
            -- ADD, ADC, ADZ, ADL, ADI
            carry_write <= '1';
        else
            -- Default
            carry_write <= '0';
        end if;
    end process check_carry_write;
end architecture behavioural;