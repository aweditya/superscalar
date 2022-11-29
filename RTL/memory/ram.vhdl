library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is
    port(
	   wr: in std_logic;
		A: in std_logic_vector(15 downto 0);
		Din: in std_logic_vector(15 downto 0);
		clk, clr: in std_logic;
		Dout: out std_logic_vector(15 downto 0)
		);
end ram;

architecture mem1 of ram is
type mem_index is array(63 downto 0) of std_logic_vector(15 downto 0);
signal mem: mem_index := (0=>"0100000111111111", 1=>"0100001111111111", 2=>"0001000001010000", 3=>"0010000001011010", others => "0000000000000000");
signal addr: std_logic_vector(15 downto 0) := "0000000000000000";

begin
process(wr, clk, A, Din, clr, mem)
begin
  
  addr <= A;
	
  if rising_edge(clk) then
    if wr='1' then
	   mem(to_integer(unsigned(A)))<=Din;
	 else
		null;
	 end if;
	 if clr='1' then
		mem <= (others => "0000000000000000");
	 end if;
  else
    null;
  end if;
end process;
	Dout<=mem(to_integer(unsigned(addr)));
end mem1;