library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IFStage is
    port(
        reset: in std_logic;
        clk: in std_logic;

        wr_IFID: out std_logic; -- Logic required in case of pipeline stall. For the time being, we always write
        IFID_inc_D, IFID_PC_D: out std_logic_vector(15 downto 0);
        IFID_IMem_D: out std_logic_vector(31 downto 0)
    );
end entity IFStage;

architecture behavioural of IFStage is
    component PC is
        port(
            clr: in std_logic;
            clk: in std_logic;
            pc_in: in std_logic_vector(15 downto 0);
            pc_out: out std_logic_vector(15 downto 0)
        );
    end component;

    signal pc_in_sig: std_logic_vector(15 downto 0) := (others => '0');
    signal pc_inc_sig: std_logic_vector(15 downto 0) := (others => '0');
    signal pc_out_sig: std_logic_vector(15 downto 0) := (others => '0');

    component ROM is
        port(
            A: in std_logic_vector(15 downto 0);
            Dout: out std_logic_vector(31 downto 0)
        );
    end component ROM;

    signal wr_IFID_sig: std_logic := '1';

begin
    pc_inc_sig <= std_logic_vector(unsigned(pc_in_sig) + 1);

    pc_increment_process: process(clk, pc_in_sig)
    begin
        if (rising_edge(clk)) then
            pc_in_sig <= std_logic_vector(unsigned(pc_in_sig) + 2);
        end if;
    end process pc_increment_process;

    pc_reg: PC
        port map(
            clr => reset,
            clk => clk,
            pc_in => pc_in_sig,
            pc_out => pc_out_sig
        );

    IFID_PC_D <= pc_in_sig;
    IFID_inc_D <= pc_inc_sig;

    mem: ROM
        port map(
            A => pc_out_sig,
            Dout => IFID_IMem_D
        );
    
    pipeline_write_process: process(wr_IFID_sig)
    begin
        wr_IFID_sig <= '1';
    end process pipeline_write_process;

    wr_IFID <= wr_IFID_sig;
end architecture behavioural;