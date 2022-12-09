library ieee;
use ieee.std_logic_1164.all;

entity IFID is 
    port(
			clk, clr : in std_logic;
			wr_IFID: in std_logic; 
			-- IFID_match : in std_logic;
			-- IFID_indexout : in integer;
			IFID_inc_D, IFID_PC_D: in std_logic_vector(15 downto 0);
			IFID_IMem_D: in std_logic_vector(31 downto 0);
			IFID_inc_Op, IFID_PC_Op: out std_logic_vector(15 downto 0);
			IFID_IMem_Op: out std_logic_vector(31 downto 0)
			-- IFID_indexout_Op : out integer;
			-- IFID_match_Op : out std_logic
		);
end IFID;

architecture arch of IFID is
	signal IFID_IMem: std_logic_vector(31 downto 0);
	signal IFID_PC, IFID_inc: std_logic_vector(15 downto 0);

begin	
	process(clk, clr, wr_IFID, IFID_inc_D, IFID_PC_D, IFID_IMem_D)
	begin
		if clr = '1' then
			IFID_IMem <= (others => '0');
			IFID_PC <= (others => '0');
			IFID_inc <= (0 => '1', others => '0');
		else
			if rising_edge(clk) then
				if wr_IFID = '1' then
					IFID_IMem <= IFID_IMem_D;
					IFID_inc <= IFID_inc_D;
					IFID_PC <= IFID_PC_D;
				end if;
			end if;
		end if;
	end process;

	IFID_IMem_Op <= IFID_IMem;
	IFID_inc_Op <= IFID_inc;
	IFID_PC_Op <= IFID_PC;
end arch;