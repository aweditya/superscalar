library ieee;
use ieee.std_logic_1164.all;

entity DestinationWriteChecker is
    port(
        instruction: in std_logic_vector(15 downto 0);
        dest_write: out std_logic
    );
end entity DestinationWriteChecker;

architecture behavioural of DestinationWriteChecker is
begin
    check_dest_write: process(instruction)
        variable opcode: std_logic_vector(3 downto 0);
    begin
        opcode := instruction(15 downto 12);
        if (opcode = "0001" or opcode = "0000" or opcode = "0010" or opcode = "0011") then
            -- ADD, ADC, ADZ, ADL, ADI, NDU, NDC, NDZ, LHI
            dest_write <= '1';
        else
            -- Default (there are more cases for other instructions)
            dest_write <= '0';
        end if;
    end process check_dest_write;
end architecture behavioural;