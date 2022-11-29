library ieee;
use ieee.std_logic_1164.all;

entity IFID is 
    port(
			clk : in std_logic;
			wr_IFID, IFID_match : in std_logic;
			IFID_indexout : in integer;
			clr_IFID: in std_logic;
			IFID_inc, IFID_PC, IFID_IMem : in std_logic_vector(15 downto 0);
			IFID_inc_Op, IFID_PC_Op, IFID_IMem_Op : out std_logic_vector(15 downto 0);
			IFID_indexout_Op : out integer;
			IFID_match_Op : out std_logic
			);
end IFID;

architecture arch of IFID is

	--1-bit Register
	component reg1 is 
		port(
			wr: in std_logic;
			clk: in std_logic;
			clr: in std_logic;
			data: in std_logic;
			Op: out std_logic
		);
	end component;
	
	--1-bit Register-Integer
	component reg1_int is 
		port(
			wr: in std_logic;
			clk: in std_logic;
			clr: in std_logic;
			data: in integer;
			Op: out integer
		);
	end component;
	
	--16-bit Register
	component reg is
		port(
			wr: in std_logic;
			clk: in std_logic;
			clr: in std_logic;
			data: in std_logic_vector(15 downto 0);
			Op: out std_logic_vector(15 downto 0)
		);
	end component;
		
begin

inc: reg port map (wr=>wr_IFID, clk=>clk, data=>IFID_inc, Op=>IFID_inc_Op, clr=>clr_IFID);
PC: reg port map (wr=>wr_IFID, clk=>clk, data=>IFID_PC, Op=>IFID_PC_Op, clr=>clr_IFID);
IMem: reg port map (wr=>wr_IFID, clk=>clk, data=>IFID_IMem, Op=>IFID_IMem_Op, clr=>clr_IFID);
match: reg1 port map (wr=>wr_IFID, clk=>clk, data=>IFID_match, Op=>IFID_match_Op, clr=>clr_IFID);
indexout: reg1_int port map (wr=>wr_IFID, clk=>clk, data=>IFID_indexout, Op=>IFID_indexout_Op, clr=>clr_IFID);

end arch;