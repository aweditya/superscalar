library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb is
end entity;

architecture behavioural of tb is
    component PriorityEncoder is
        generic (
            input_width : integer := 2 ** 2;
            output_width : integer := 2 
        );
        port (
            a: in std_logic_vector(input_width - 1 downto 0);
            y: out std_logic_vector(output_width - 1 downto 0);
            all_ones: out std_logic
        );
    end component;

    signal a_in: std_logic_vector(3 downto 0) := (others => '0');
    signal y_out: std_logic_vector(1 downto 0) := (others => '0');
    signal all_ones_out: std_logic;

begin
    encoder: PriorityEncoder
        port map(a => a_in, y => y_out, all_ones => all_ones_out);

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