library ieee;
use ieee.std_logic_1164.all;

entity aluexecpipe is 
    port(
        c_sig_in: in std_logic_vector(5 downto 0);
        -- bit 1 and 0 are for mux 
        --  00 - opr2, 01 - leftshift(opr2), 10 - se6(opr2), 11 - invalid
        
        -- bit 3 and 2 are for alu operation same as in alu.vhdl
        --  01 - add, 10 - nand, 11 - xor, 00 - invalid

        -- bit 4 is c_flag_enable for carry flag modification
        -- bit 5 is z_flag_enable for zero flag modification
        opr1, opr2, pc_in: in std_logic_vector(15 downto 0);
        c_in, z_in: in std_logic;
        c_out, z_out: out std_logic;
        pc_out, result: out std_logic_vector(15 downto 0)
    );
end entity;

architecture behavioural of aluexecpipe is
    signal opr2_se_sig, opr2_ls_sig, a_sig, b_sig: std_logic_vector(15 downto 0);
    signal c_sig, c_sig_alu_out, z_sig, z_sig_alu_out: std_logic;
    
    component bitextender6 is
        port (
            A: in std_logic_vector(5 downto 0);
            Op: out std_logic_vector(15 downto 0)
        );
    end component bitextender6;

    component bit1shift is
        port (
            A: in std_logic_vector(15 downto 0);
            Op: out std_logic_vector(15 downto 0)
        );
    end component bit1shift;

    component alu is
        port (
            A: in std_logic_vector(15 downto 0);
            B: in std_logic_vector(15 downto 0);
            S: in std_logic_vector(1 downto 0);
            Op: out std_logic_vector(15 downto 0);
            carry: out std_logic;
            zero: out std_logic
        );
    end component alu;

begin

    p1: process(c_sig_in, opr1, opr2, pc_in, c_in, z_in, opr2_ls_sig, opr2_se_sig)
        begin
        if(c_sig_in(1 downto 0) = "00") then
            b_sig <= opr2;
        elsif(c_sig_in(1 downto 0) = "01") then
            b_sig <= opr2_ls_sig;
        elsif(c_sig_in(1 downto 0) = "10") then
            b_sig <= opr2_se_sig;
        else --invalid state 
            b_sig <= (others => 'Z');
        end if;
    end process p1;

    p2: process(c_sig_in, opr1, opr2, pc_in, c_in, z_in, c_sig_alu_out, z_sig_alu_out)
        begin
        if(c_sig_in(5 downto 4) = "11") then
            c_out <= c_sig_alu_out;
            z_out <= z_sig_alu_out;
        elsif(c_sig_in(5 downto 4) = "01") then
            c_out <= c_in;
            z_out <= z_sig_alu_out;
        elsif(c_sig_in(5 downto 4) = "10") then
            c_out <= c_sig_alu_out;
            z_out <= z_in;
        else
            c_out <= c_in;
            z_out <= z_in;
        end if;
    end process p2;

    a1: alu port map(a => a_sig, b => b_sig, s =>c_sig_in(3 downto 2), op => result, carry => c_sig_alu_out, zero => z_sig_alu_out);
    s1: bitextender6 port map(a => opr2(5 downto 0), op => opr2_se_sig);
    b1: bit1shift port map(a => opr2, op => opr2_ls_sig);
    a_sig <= opr1; 
    pc_out <= pc_in;
end behavioural;
