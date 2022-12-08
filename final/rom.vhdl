library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM is
    port(
		A: in std_logic_vector(15 downto 0);
		Dout: out std_logic_vector(31 downto 0)
	);
end entity ROM;

architecture behavioural of ROM is
	type mem_index is array(63 downto 0) of std_logic_vector(15 downto 0);
	signal mem: mem_index := (
		0 => "0000000001000111", -- ADI r0,r1,000111
		1 => "0000000010001000", -- ADI r0,r2,001000
		2 => "0001001010011000", -- ADD r1,r2,r3
		3 => "0001001011100000", -- ADD r1,r3,r4
		others => "0000000000000000"
	);
	signal addr: std_logic_vector(15 downto 0);

begin
	process (A, mem)
	begin	
		addr <= A;
	end process;

	Dout <= mem(to_integer(unsigned(addr))) & mem(to_integer(unsigned(addr)) + 1);
end architecture behavioural;