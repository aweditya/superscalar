library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity OperandExtractor is
    port(
        instruction: std_logic_vector(15 downto 0);

        operand1, operand2: std_logic_vector(4 downto 0);
        destination: std_logic_vector(4 downto 0)
    );
end entity OperandExtractor;

architecture behavioural of OperandExtractor is
    signal operand1_sig, operand2_sig: std_logic_vector(4 downto 0) := (others => '0');
    signal destination_sig: std_logic_vector(4 downto 0) := (others => '0');

begin
    get_operands_process: process(instruction) 
    begin
        if (instruction(15 downto 12) = "0001" or instruction(15 downto 12) = "0010") then
            -- ADD, ADC, ADZ, ADL, NDU, NDC, NDZ
            operand1_sig <= std_logic_vector(resize(unsigned(instruction(11 downto 9)), 5));
            operand2_sig <= std_logic_vector(resize(unsigned(instruction(8 downto 6)), 5));
            destination_sig <= std_logic_vector(resize(unsigned(instruction(5 downto 3)), 5));

        elsif (instruction(15 downto 12) = "0000") then
            -- ADI (arbitrarily setting operand2 to instruction(8-6))
            operand1_sig <= std_logic_vector(resize(unsigned(instruction(11 downto 9)), 5));
            operand2_sig <= std_logic_vector(resize(unsigned(instruction(8 downto 6)), 5));
            destination_sig <= std_logic_vector(resize(unsigned(instruction(8 downto 6)), 5));
        
        else 
            -- Default (there are more cases for other instructions)
            operand1_sig <= std_logic_vector(resize(unsigned(instruction(11 downto 9)), 5));
            operand2_sig <= std_logic_vector(resize(unsigned(instruction(8 downto 6)), 5));
            destination_sig <= std_logic_vector(resize(unsigned(instruction(5 downto 3)), 5));

        end if;
    end process get_operands_process;
end architecture behavioural;