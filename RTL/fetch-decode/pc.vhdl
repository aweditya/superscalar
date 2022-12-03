library ieee;
use ieee.std_logic_1164.all;

entity PC is
    port(
        clr: in std_logic;
        clk: in std_logic;
        pc_in: in std_logic_vector(15 downto 0);
        pc_out: out std_logic_vector(15 downto 0)
    );
end entity PC;

architecture behavioural of PC is
    signal pc_out_sig: std_logic_vector(15 downto 0);

begin
    process(clr, clk, pc_in) 
    begin
        if (clr = '1') then
            pc_out_sig <= (others => '0');

        else
            if (rising_edge(clk)) then
                pc_out_sig <= pc_in;

            end if;
        end if;
    end process;

    pc_out <= pc_out_sig;
end architecture behavioural;