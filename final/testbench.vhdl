library ieee;
use ieee.std_logic_1164.all;

entity tb is
end entity tb;

architecture behavioural of tb is
    component datapath is 
        port(
            reset, clk : IN STD_LOGIC;
            output_proc : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    end component;

    signal clock, clear: std_logic := '1';
    signal out_proc: std_logic_vector(31 downto 0);

begin
    proc: datapath
        port map(
            reset => clear,
            clk => clock,
            output_proc => out_proc
        );

    main: process
    begin
        clear <= '1';
        clock <= '0';
        wait for 100 ns;

        clear <= '1';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;

        clear <= '0';
        clock <= '1';
        wait for 100 ns;

        clear <= '0';
        clock <= '0';
        wait for 100 ns;
        
        report "Testing completed";
        wait;
    end process;
end architecture behavioural;