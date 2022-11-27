library ieee;
use ieee.std_logic_1164.all;

entity reg1 is 
    port(
        wr: in std_logic;
		clk: in std_logic;
		data: in std_logic;
		clr: in std_logic;
		Op: out std_logic
		);
end reg1;

architecture reg_1 of reg1 is
begin
    process(wr, clk, data)
    begin
        if rising_edge(clk) then
            if wr='1' then
                Op <= data;
            else
                null;
            end if;
            if clr='1' then
                Op<='0';
            end if;
        else
            null;
        end if;
    end process;
end reg_1;

library ieee;
use ieee.std_logic_1164.all;

entity reg_gen is 
    generic(
        reg_size: integer := 16
    );
    port(
        wr: in std_logic;
		clk: in std_logic;
		data: in std_logic_vector(reg_size-1 downto 0);
		clr: in std_logic;
		Op: out std_logic(reg_size-1 downto 0);
    );
end reg_gen;

architecture genericreg of reg_gen is
    component reg1 is 
        port(
            wr: in std_logic;
            clk: in std_logic;
            data: in std_logic;
            clr: in std_logic;
            Op: out std_logic
            );
    end component reg1;
begin
    rs: for i in 0 to reg_size-1 generate
        x1: reg1 port map(wr => wr, clk => clk, data => data(i), clr => clr, Op => Op(i));
    end generate;
end genericreg;