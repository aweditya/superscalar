library ieee;
use ieee.std_logic_1164.all;

entity ZeroWriteChecker is
    port(
        instruction: in std_logic_vector(15 downto 0);
        zero_write: out std_logic
    );
end entity ZeroWriteChecker;

architecture behavioural of ZeroWriteChecker is
begin
    check_zero_write: process(instruction)
        variable opcode: std_logic_vector(3 downto 0);
    begin
        opcode := instruction(15 downto 12);
        if (opcode = "0001" or opcode = "0000" or opcode = "0010" or opcode = "0111") then
            -- ADD, ADC, ADZ, ADL, ADI, NDU, NDC, NDZ, LW
            zero_write <= '1';
        else
            -- Default
            zero_write <= '0';
        end if;
    end process check_zero_write;
end architecture behavioural;