library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb is
end entity;

architecture behavioural of tb is
    component IFStage is
    port(
        reset: in std_logic;
        clk: in std_logic;

        wr_IFID: out std_logic;
        IFID_inc_D, IFID_PC_D: out std_logic_vector(15 downto 0);
        IFID_IMem_D: out std_logic_vector(31 downto 0)
    );
    end component IFStage;

    signal reset_in: std_logic;
    signal clk_in: std_logic;

    signal wr_IFID_out: std_logic;
    signal IFID_inc_D_out, IFID_PC_D_out: std_logic_vector(15 downto 0);
    signal IFID_IMem_D_out: std_logic_vector(31 downto 0);

begin
    if_stage: IFStage
        port map(
            reset => reset_in,
            clk => clk_in,

            wr_IFID => wr_IFID_out,
            IFID_inc_D => IFID_inc_D_out,
            IFID_PC_D => IFID_PC_D_out,
            IFID_IMem_D => IFID_IMem_D_out
        );

    test_process: process
    begin
        reset_in <= '1';
        clk_in <= '0';
        wait for 20 ns;
        
        reset_in <= '0';
        clk_in <= '1';
        wait for 20 ns;

        reset_in <= '0';
        clk_in <= '0';
        wait for 20 ns;

        reset_in <= '0';
        clk_in <= '1';
        wait for 20 ns;

        reset_in <= '0';
        clk_in <= '0';
        wait for 20 ns;

        reset_in <= '0';
        clk_in <= '1';
        wait for 20 ns;

        reset_in <= '0';
        clk_in <= '0';
        wait for 20 ns;

        reset_in <= '0';
        clk_in <= '1';
        wait for 20 ns;

        reset_in <= '0';
        clk_in <= '0';
        wait for 20 ns;

        report "Testing completed";
        wait;
    end process test_process;

end architecture behavioural;