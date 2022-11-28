library ieee;
use ieee.std_logic_1164.all;

entity aluexecpipe is 
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
        c_in, z_in: in std_logic:='0';
        c_out, z_out: out std_logic;
        pc_out, result: out std_logic_vector(15 downto 0)
    );
end entity;

architecture behavioural of aluexecpipe is
    signal imm_data_se_sig, rb_data_ls_sig, a_sig, b_sig: std_logic_vector(15 downto 0) := (others => '0');
    signal c_sig, c_sig_alu_out, z_sig, z_sig_alu_out: std_logic := '0';
    
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

    p1: process(control_sig_in, ra_data, rb_data, pc_in, c_in, z_in, rb_data_ls_sig, imm_data_se_sig)
        begin
        if(control_sig_in(1 downto 0) = "00") then
            b_sig <= rb_data;
        elsif(control_sig_in(1 downto 0) = "01") then
            b_sig <= rb_data_ls_sig;
        elsif(control_sig_in(1 downto 0) = "10") then
            b_sig <= imm_data_se_sig;
        else --invalid state 
            b_sig <= (others => 'Z');
        end if;
    end process p1;

    carry_flag_process: process(control_sig_in, ra_data, rb_data, pc_in, c_in, c_sig_alu_out)
        begin
        if (control_sig_in(4) = '1') then
            c_out <= c_sig_alu_out;
        else
            c_out <= c_in;
        end if;
    end process carry_flag_process;

    zero_flag_process: process(control_sig_in, ra_data, rb_data, pc_in, z_in, z_sig_alu_out)
        begin
        if (control_sig_in(5) = '1') then
            z_out <= z_sig_alu_out;
        else
            z_out <= z_in;
        end if;
    end process zero_flag_process;

    a1: alu port map(a => a_sig, b => b_sig, s => control_sig_in(3 downto 2), op => result, carry => c_sig_alu_out, zero => z_sig_alu_out);
    s1: bitextender6 port map(a => imm_data, op => imm_data_se_sig);
    b1: bit1shift port map(a => rb_data, op => rb_data_ls_sig);

    a_sig <= ra_data; 
    pc_out <= pc_in;
end behavioural;