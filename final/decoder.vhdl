library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Decoder is
    generic (
        input_width : integer := 8;
        output_width : integer := 2 ** 8
    );
    port (
        address: in std_logic_vector(input_width - 1 downto 0);
        one_hot_encoding_out: out std_logic_vector(output_width - 1 downto 0)
    );
end entity Decoder;

architecture behavioural of Decoder is
    signal one_hot_encoding : std_logic_vector(output_width - 1 downto 0) := (others => '0');
begin
    one_hot_process: process(address)
    begin
        for i in 0 to output_width-1 loop
            if to_integer(unsigned(address)) = i then
                one_hot_encoding(i) <= '1';
            else 
                one_hot_encoding(i) <= '0';
            end if;
        end loop;
    
    end process one_hot_process;
    one_hot_encoding_out <= one_hot_encoding;

end behavioural;