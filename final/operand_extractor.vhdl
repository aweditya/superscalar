library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity OperandExtractor is
    port(
        instruction: in std_logic_vector(15 downto 0);

        operand1, operand2: out std_logic_vector(2 downto 0);
        destination: out std_logic_vector(2 downto 0)
    );
end entity OperandExtractor;

architecture behavioural of OperandExtractor is
    signal operand1_sig, operand2_sig: std_logic_vector(2 downto 0) := (others => '0');
    signal destination_sig: std_logic_vector(2 downto 0) := (others => '0');

begin
    get_operands_process: process(instruction) 
    begin
        if (instruction(15 downto 12) = "0001" or instruction(15 downto 12) = "0010") then
            -- ADD, ADC, ADZ, ADL, NDU, NDC, NDZ
            operand1_sig <= instruction(11 downto 9);
            operand2_sig <= instruction(8 downto 6);
            destination_sig <= instruction(5 downto 3);

        elsif (instruction(15 downto 12) = "0000") then
            -- ADI (arbitrarily setting operand2 to instruction(8-6))
            operand1_sig <= instruction(11 downto 9);
            operand2_sig <= instruction(8 downto 6);
            destination_sig <= instruction(8 downto 6);
        
        elsif (instruction(15 downto 12) = "0011") then
            -- LHI (arbitrarily setting operand1 to instruction(11-9) and operand2 to instruction(8-6))
            operand1_sig <= instruction(11 downto 9);
            operand2_sig <= instruction(8 downto 6);
            destination_sig <= instruction(11 downto 9);

        else 
            -- Default (there are more cases for other instructions)
            operand1_sig <= instruction(11 downto 9);
            operand2_sig <= instruction(8 downto 6);
            destination_sig <= instruction(5 downto 3);
            
        end if;
    end process get_operands_process;
	 
    operand1 <= operand1_sig;
    operand2 <= operand2_sig;
    destination <= destination_sig;
end architecture behavioural;