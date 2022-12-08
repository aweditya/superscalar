library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PriorityEncoder is
    generic (
        input_width : integer := 2 ** 8;
        output_width : integer := 8 
    );
    port (
        a: in std_logic_vector(input_width - 1 downto 0);
        y: out std_logic_vector(output_width - 1 downto 0);
        all_ones: out std_logic
    );
end entity;

architecture behavioural of PriorityEncoder is
    signal first_zero : std_logic_vector(output_width - 1 downto 0) := (others => '0');
    
begin
    output_process : process(a)
        variable priority_encoding: std_logic_vector(output_width - 1 downto 0);
        variable valid : std_logic;
    begin
	     priority_encoding := (others => '0');
        valid := '1';

        priority_loop: for i in 0 to input_width-1 loop
            if a(i) = '0' then
                priority_encoding := std_logic_vector(to_unsigned(i, output_width));
            end if;

            valid := valid and a(i);
        end loop priority_loop;

        first_zero <= priority_encoding;
        valid := not valid;
        all_ones <= valid;

    end process output_process;

    y <= first_zero;
end behavioural;