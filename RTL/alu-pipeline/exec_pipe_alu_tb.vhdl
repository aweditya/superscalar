-- testbench without tracefile --
library ieee;
use ieee.std_logic_1164.all;

entity tb is
end entity;

architecture behave of tb is
    --write component blocks here-- 
    component aluexecpipe is 
        port(
            control_sig_in: in std_logic_vector(5 downto 0);
            -- bit 1 and 0 are for mux 
            --  00 - rb_data, 01 - leftshift(rb_data), 10 - se6(rb_data), 11 - invalid
            
            -- bit 3 and 2 are for alu operation same as in alu.vhdl
            --  01 - add, 10 - nand, 11 - xor, 00 - invalid

            -- bit 4 is c_flag_enable for carry flag modification
            -- bit 5 is z_flag_enable for zero flag modification
            ra_data, rb_data, pc_in: in std_logic_vector(15 downto 0);
            imm_data: in std_logic_vector(5 downto 0);
            c_in, z_in: in std_logic;
            c_out, z_out: out std_logic;
            pc_out, result: out std_logic_vector(15 downto 0)
        );
    end component;

    --signals here--
    signal c_sig_in_sig: std_logic_vector(5 downto 0) := (others => '0');
    signal opr1_sig,opr2_sig,pc_in_sig: std_logic_vector(15 downto 0) := (others => '0');
    signal imm6_sig: std_logic_vector(5 downto 0) := (others => '0');
    signal c_in_sig, z_in_sig, c_out_sig, z_out_sig: std_logic:='0';
    signal pc_out_sig, result_sig: std_logic_vector(15 downto 0):= (others => '0'); 
begin
    dut1: aluexecpipe
        port map(
            control_sig_in => c_sig_in_sig,
            ra_data => opr1_sig,
            rb_data => opr2_sig,
            pc_in => pc_in_sig,
            imm_data => imm6_sig,
            c_in => c_in_sig,
            z_in => z_in_sig,
            c_out => c_out_sig,
            z_out => z_out_sig,
            pc_out => pc_out_sig,
            result => result_sig
        );
    main: process
    begin  
        c_sig_in_sig <= "000100";
        imm6_sig <= "000000";
        opr1_sig <= x"2332";
        opr2_sig <= x"3421";
        pc_in_sig <= x"7FFF";
        c_in_sig <= '0';
        z_in_sig <= '0';
        wait for 10 ns;

        c_sig_in_sig <= "110100";
        imm6_sig <= "000000";
        opr1_sig <= x"0001";
        opr2_sig <= x"FFFF";
        pc_in_sig <= x"7FFF";
        c_in_sig <= '0';
        z_in_sig <= '0';
        wait for 10 ns;

        report "Testing completed";
        wait;
    end process;
end;
