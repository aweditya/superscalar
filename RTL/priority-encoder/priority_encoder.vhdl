library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PriorityEncoder is
    generic (
        input_width : integer := 2 ** 8;
        output_width : integer := 8 + 1
    );
    port (
        a: in std_logic_vector(input_width - 1 downto 0);
        y: out std_logic_vector(output_width - 1 downto 0)
    );
end entity;

architecture behavioural of PriorityEncoder is
    signal first_zero : std_logic_vector(output_width - 2 downto 0) := (others => '0');
    
begin
    output_process : process(a)
        variable valid : std_logic;
    begin
        valid := '1';

        priority_loop: for i in 0 to input_width-1 loop
            if a(i) = '0' then
                first_zero(output_width - 2 downto 0) <= std_logic_vector(to_unsigned(i, output_width - 1));
            end if;

            valid := valid and a(i);
        end loop priority_loop;

        valid := not valid;
        y(output_width - 1) <= valid;

    end process output_process;

    y(output_width - 2 downto 0) <= first_zero;
end behavioural;