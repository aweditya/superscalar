library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DualPriorityEncoder is
    generic (
        input_width : integer := 2 ** 8;
        output_width : integer := 8
    );
    port (
        a: in std_logic_vector(input_width - 1 downto 0);
        y_first: out std_logic_vector(output_width - 1 downto 0);
        valid_first: out std_logic;
        y_second: out std_logic_vector(output_width - 1 downto 0);
        valid_second: out std_logic
    );
end entity DualPriorityEncoder;

architecture behavioural of DualPriorityEncoder is
    component PriorityEncoder is
        generic (
            input_width : integer := 2 ** 8;
            output_width : integer := 8 
        );
        port (
            a: in std_logic_vector(input_width - 1 downto 0);
            y: out std_logic_vector(output_width - 1 downto 0);
            all_ones: out std_logic
        );
    end component;

    component Decoder is 
        generic (
            input_width : integer := 8;
            output_width : integer := 2 ** 8
        );
        port (
            address: in std_logic_vector(input_width - 1 downto 0);
            one_hot_encoding_out: out std_logic_vector(output_width - 1 downto 0)
        );
    end component;

    signal address_first: std_logic_vector(output_width - 1 downto 0) := (others => '0');
    signal decoder_out: std_logic_vector(input_width - 1 downto 0) := (others => '0');
    signal second_encoder_in: std_logic_vector(input_width - 1 downto 0) := (others => '0');

begin
    first_encoder: PriorityEncoder
        generic map(
            input_width, 
            output_width
        )

        port map(
            a => a,
            y => address_first,
            all_ones => valid_first
        );

    dec: Decoder
        generic map(
            output_width,
            input_width
        )

        port map(
            address => address_first,
            one_hot_encoding_out => decoder_out
        );

    mark_process: process(a, decoder_out)
    begin
        second_encoder_in <= a or decoder_out;
    end process mark_process;

    second_encoder: PriorityEncoder
        generic map(
            input_width,
            output_width
        )

        port map(
            a => second_encoder_in,
            y => y_second,
            all_ones => valid_second
        );

    y_first <= address_first;

end behavioural;