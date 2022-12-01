library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb is
end entity;

architecture behavioural of tb is
    component Decoder is
        generic (
            input_width : integer := 2;
            output_width : integer := 2 ** 2
        );
        port (
            address: in std_logic_vector(input_width - 1 downto 0);
            one_hot_encoding_out: out std_logic_vector(output_width - 1 downto 0)
        );
    end component;

    signal add : std_logic_vector(1 downto 0) := (others => '0');
    signal one_hot : std_logic_vector(3 downto 0) := (others => '0');

begin
    dut: Decoder
        port map(add, one_hot);

    test_process: process
    begin
        add <= "00";
        wait for 10 ns;

        add <= "01";
        wait for 10 ns;

        add <= "10";
        wait for 10 ns;

        add <= "11";
        wait for 10 ns;

        report "Testing completed";
        wait;
    end process test_process;
end behavioural;