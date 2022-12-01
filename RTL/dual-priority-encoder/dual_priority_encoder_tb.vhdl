library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb is
end entity;

architecture behavioural of tb is
    component DualPriorityEncoder is
        generic (
            input_width : integer := 2 ** 2;
            output_width : integer := 2 
        );
        port (
            a: in std_logic_vector(input_width - 1 downto 0);
            y_first: out std_logic_vector(output_width - 1 downto 0);
            valid_first: out std_logic;
            y_second: out std_logic_vector(output_width - 1 downto 0);
            valid_second: out std_logic
        );
    end component;

    signal a_in: std_logic_vector(3 downto 0) := (others => '0');
    signal y_first_out, y_second_out: std_logic_vector(1 downto 0) := (others => '0');
    signal valid_first_out, valid_second_out: std_logic;

begin
    encoder: DualPriorityEncoder
        port map(
            a => a_in,
            y_first => y_first_out,
            valid_first => valid_first_out,
            y_second => y_second_out,
            valid_second => valid_second_out
        );

    test_process: process
    begin
        a_in <= "0000";
        wait for 10 ns;

        a_in <= "0001";
        wait for 10 ns;

        a_in <= "0010";
        wait for 10 ns;

        a_in <= "0011";
        wait for 10 ns;

        a_in <= "0100";
        wait for 10 ns;

        a_in <= "0101";
        wait for 10 ns;

        a_in <= "0110";
        wait for 10 ns;

        a_in <= "0111";
        wait for 10 ns;

        a_in <= "1000";
        wait for 10 ns;

        a_in <= "1001";
        wait for 10 ns;

        a_in <= "1010";
        wait for 10 ns;

        a_in <= "1011";
        wait for 10 ns;

        a_in <= "1100";
        wait for 10 ns;

        a_in <= "1101";
        wait for 10 ns;

        a_in <= "1110";
        wait for 10 ns;

        a_in <= "1111";
        wait for 10 ns;

        report "Testing completed";
        wait;
    end process test_process;

end architecture behavioural;