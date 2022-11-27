library ieee;
use ieee.std_logic_1164.all;

entity rs is 
    generic(
        size : integer := 256
    )
    port(
        wr: in std_logic;
        rd: in std_logic;
		clk: in std_logic;
        clr: in std_logic;
		control: in std_logic_vector(3 downto 0);
        pc_in: in std_logic_vector(15 downto 0);
        opr1, opr2: in std_logic_vector(15 downto 0);
        c_in, z_in: in std_logic_vector(2 downto 0);
        valid1, valid2, valid3, valid4: in std_logic;
        imm_6: in std_logic_vector(5 downto 0);
        pc_out: out std_logic_vector(15 downto 0);
        ra_data, rb_data: out std_logic_vector(15 downto 0);
        imm_data: out std_logic_vector(5 downto 0);
        c_out, z_out: out std_logic;
	);
end rs;

architecture behavioural of rs is
    type rs_type_4 is array(size-1 downto 0) of std_logic_vector(3 downto 0);
    type rs_type_16 is array(size-1 downto 0) of std_logic_vector(15 downto 0);
    type rs_type_1 is array(size-1 downto 0) of std_logic;
    type rs_type_6 is array(size-1 downto 0) of std_logic_vector(5 downto 0);
    type rs_type_3 is array(size-1 downto 0) of std_logic_vector(2 downto 0);
    signal rs_control: rs_type_4:= (others => "0000");
    signal rs_pc: rs_type_16:= (others => "0000000000000000");
    signal rs_opr1: rs_type_16:= (others => "0000000000000000");
    signal rs_v1: rs_type_1:= (others => '0');
    signal rs_opr2: rs_type_16:= (others => "0000000000000000");
    signal rs_v2: rs_type_1:= (others => '0');
    signal rs_imm_6: rs_type_6:= (others => "000000");
    signal rs_c: rs_type_3:= (others => "000");
    signal rs_v3: rs_type_1:= (others => '0');
    signal rs_z: rs_type_3:= (others => "000");
    signal rs_v4: rs_type_1:= (others => '0');
    signal rs_ready: rs_type_1:= (others => '0');
    signal rs_issued: rs_type_1:= (others => '0');

begin

    p1: process(clr, wr)
        begin
        if (clr = '1') then
            for i in 0 to size-1 loop
                rs_control <= (others => "0000");
                rs_pc <= (others => "0000000000000000");
                rs_opr1 <= (others => "0000000000000000");
                rs_v1 <= (others => '0');
                rs_opr2: rs_type_16:= (others => "0000000000000000");
                rs_v2: rs_type_1:= (others => '0');
                rs_imm_6: rs_type_6:= (others => "000000");
                rs_c: rs_type_3:= (others => "000");
                rs_v3: rs_type_1:= (others => '0');
                rs_z: rs_type_3:= (others => "000");
                rs_v4: rs_type_1:= (others => '0');
                rs_ready: rs_type_1:= (others => '0');
                rs_issued: rs_type_1:= (others => '0');
            end loop;
        end if;
        if (wr = '1') then
            -- finds an empty entry and writes to it
            for i in 0 to size-1 loop
                if (rs_issued(i) = '1') then
                    rs_control(i) <= control;
                    rs_pc(i) <= pc_in;
                    rs_opr1(i) <= opr1;
                    rs_v1(i) <= valid1;
                    rs_opr2(i) <= opr2;
                    rs_v2(i) <= valid2;
                    rs_imm_6(i) <= imm_6;
                    rs_c(i) <= c_in;
                    rs_v3(i) <= valid3;
                    rs_z(i) <= z_in;
                    rs_v4(i) <= valid4;
                    rs_ready(i) <= valid1 AND valid2 AND valid3 AND valid4;
                    rs_issed(i) <= '0';
                end if;
            end loop;
        end if;
    end process p1;

end behavioural