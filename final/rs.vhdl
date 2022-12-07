library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rs is 
    generic(
        size : integer := 256
    );
    port(
        -- INPUTS 
		clk: in std_logic; -- input clock
        clr: in std_logic; -- clear bit
        wr_inst1, wr_inst2: in std_logic; -- write bits for newly decoded instructions 
        --wr_ALU1, wr_ALU2: in std_logic; -- write bits for newly executed instructions
        rd_ALU1, rd_ALU2: in std_logic;  -- read bits for issuing ready instructions
		control_inst1, control_inst2: in std_logic_vector(5 downto 0); -- control values for the two instructions
        pc_inst1, pc_inst2: in std_logic_vector(15 downto 0); -- pc values for the two instructions
        opr1_inst1, opr2_inst1, opr1_inst2, opr2_inst2: in std_logic_vector(15 downto 0); -- operand values for the two instructions
        imm6_inst1, imm6_inst2: in std_logic_vector(5 downto 0); -- imm6 values for the two instructions
        c_inst1, z_inst1, c_inst2, z_inst2: in std_logic_vector(7 downto 0); -- carry and zero values for the two instructions
        valid1_inst1, valid2_inst1, valid3_inst1, valid4_inst1: in std_logic; -- valid bits for first instruction
        valid1_inst2, valid2_inst2, valid3_inst2, valid4_inst2: in std_logic; -- valid bits for second instruction
        data_ALU1, data_ALU2: in std_logic_vector(15 downto 0); -- data forwarded from the execution pipelines
        rr1_ALU1, rr1_ALU2, rr2_ALU1, rr2_ALU2, rr3_ALU1, rr3_ALU2: in std_logic_vector(7 downto 0); -- rr values coming from the ROB corresponding to execution pipeline outputs
        c_ALU1_in, z_ALU1_in, c_ALU2_in, z_ALU2_in: in std_logic; -- carry and zero values forwarded from the execution pipelines
        finished_ALU1, finished_ALU2: std_logic; -- finished bits coming from the execution pipelines

        -- OUTPUTS
        pc_ALU1, pc_ALU2: out std_logic_vector(15 downto 0); -- pc values forwarded to each execution pipeline
        control_ALU1, control_ALU2: out std_logic_vector(5 downto 0); -- control to go to the control generator for the ALU pipelines
        ra_ALU1, rb_ALU1, ra_ALU2, rb_ALU2: out std_logic_vector(15 downto 0); -- operand values forwarded to each execution pipeline
        imm6_ALU1, imm6_ALU2: out std_logic_vector(5 downto 0); -- imm6 values forwarded to each execution pipeline
        c_ALU1_out, z_ALU1_out, c_ALU2_out, z_ALU2_out: out std_logic; -- carry and zero values forwarded to each execution pipeline
        almost_full_out, full_out, empty_out: out std_logic; -- full and empty bits for the RS
        finished_ALU1_out, finished_ALU2_out: out std_logic -- instruction has been scheduled to the pipeline
	);
end rs;

architecture behavioural of rs is
    -- defining the types required for different-sized columns
    type rs_type_4 is array(size-1 downto 0) of std_logic_vector(3 downto 0);
    type rs_type_16 is array(size-1 downto 0) of std_logic_vector(15 downto 0);
    type rs_type_1 is array(size-1 downto 0) of std_logic;
    type rs_type_6 is array(size-1 downto 0) of std_logic_vector(5 downto 0);
    type rs_type_8 is array(size-1 downto 0) of std_logic_vector(7 downto 0);

    -- defining the required columns, each with (size) entries
    signal rs_control: rs_type_6:= (others => (others => '0'));
    signal rs_pc: rs_type_16:= (others => (others => '0'));
    signal rs_opr1: rs_type_16:= (others => (others => '0'));
    signal rs_v1: rs_type_1:= (others => '0');
    signal rs_opr2: rs_type_16:= (others => (others => '0'));
    signal rs_v2: rs_type_1:= (others => '0');
    signal rs_imm_6: rs_type_6:= (others => (others => '0'));
    signal rs_c: rs_type_8:= (others => (others => '0'));
    signal rs_v3: rs_type_1:= (others => '0');
    signal rs_z: rs_type_8:= (others => (others => '0'));
    signal rs_v4: rs_type_1:= (others => '0');
    signal rs_ready: rs_type_1:= (others => '0');
    signal rs_issued: rs_type_1:= (others => '0');

    signal count: integer range 0 to size := 0;
    signal almost_full: std_logic;
    signal full: std_logic;
    signal empty: std_logic;

    signal finished_ALU1_s, finished_ALU2_s: std_logic;

begin
    -- responsible for clearing entries when clr is set
    p0: process(clr, rs_v1, rs_v2, rs_v3, rs_v4)
        begin
        -- clear data and indices when reset is set
        if (clr = '1') then
            rs_control <= (others => (others => '0'));
            rs_pc <= (others => (others => '0'));
            rs_opr1 <= (others => (others => '0'));
            rs_v1 <= (others => '0');
            rs_opr2 <= (others => (others => '0'));
            rs_v2 <= (others => '0');
            rs_c <= (others => (others => '0'));
            rs_v3 <= (others => '0');
            rs_z <= (others => (others => '0'));
            rs_v4 <= (others => '0');
            rs_ready <= (others => '0');
            rs_issued <= (others => '0');
            count <= 0;
        end if;
    end process p0; 

    -- responsible for adding newly decoded instructions to the RS
    p1: process(clk, wr_inst1, wr_inst2, rs_issued, control_inst1, control_inst2, pc_inst1, pc_inst2, opr1_inst1, opr1_inst2, opr2_inst1, opr2_inst2,
    valid1_inst1, valid1_inst2, valid2_inst1, valid2_inst2, imm6_inst1, imm6_inst2, c_inst1, c_inst2, valid3_inst1, valid3_inst2, z_inst1, z_inst2,
    valid4_inst1, valid4_inst2)
        begin
        if rising_edge(clk) then
            -- finds an empty entry and writes first instruction to it at the clock edge
            if (wr_inst1 = '1') then
                for i in 0 to size-1 loop
                    if (rs_issued(i) = '1') then
                        rs_control(i) <= control_inst1;
                        rs_pc(i) <= pc_inst1;
                        rs_opr1(i) <= opr1_inst1;
                        rs_v1(i) <= valid1_inst1;
                        rs_opr2(i) <= opr2_inst1;
                        rs_v2(i) <= valid2_inst1;
                        rs_imm_6(i) <= imm6_inst1;
                        rs_c(i) <= c_inst1;
                        rs_v3(i) <= valid3_inst1;
                        rs_z(i) <= z_inst1;
                        rs_v4(i) <= valid4_inst1;
                        rs_issued(i) <= '0';
                        count <= count + 1;
                        exit;
                    end if;
                end loop;
            end if;

            -- finds an empty entry and writes second instruction to it at the clock edge
            if (wr_inst2 = '1') then
                for i in 0 to size-1 loop
                    if (rs_issued(i) = '1') then
                        rs_control(i) <= control_inst2;
                        rs_pc(i) <= pc_inst2;
                        rs_opr1(i) <= opr1_inst2;
                        rs_v1(i) <= valid1_inst2;
                        rs_opr2(i) <= opr2_inst2;
                        rs_v2(i) <= valid2_inst2;
                        rs_imm_6(i) <= imm6_inst2;
                        rs_c(i) <= c_inst2;
                        rs_v3(i) <= valid3_inst2;
                        rs_z(i) <= z_inst2;
                        rs_v4(i) <= valid4_inst2;
                        rs_issued(i) <= '0';
                        count <= count + 1;
                        exit;
                    end if;
                end loop;
            end if;
        end if;
    end process p1;

    -- responsible for sending valid instructions to the execution pipelines
    p2: process(clk, rd_ALU1, rd_ALU2, rs_ready, rs_issued, rs_control, rs_pc, rs_opr1, rs_opr2, rs_imm_6, rs_c, rs_z)
        begin
        if rising_edge(clk) then
            -- finds a ready entry and forwards it to ALU pipeline-1
            for i in 0 to size-1 loop
                if (rd_ALU1 = '1' and rs_ready(i) = '1' and rs_issued(i) = '0') then
                    if (rs_control(i)(5 downto 2) = "0001" or rs_control(i)(5 downto 2) = "0010" or rs_control(i)(5 downto 2) = "0000") then
                        -- ADD, ADC, ADZ, ADL, ADI, NDU, NDC, NDZ
                        pc_ALU1 <= rs_pc(i);
                        ra_ALU1 <= rs_opr1(i);
                        rb_ALU1 <= rs_opr2(i);
                        imm6_ALU1 <= rs_imm_6(i);
                        c_ALU1_out <= rs_c(i)(0);
                        z_ALU1_out <= rs_z(i)(0); 
                        control_ALU1 <= rs_control(i);
                        rs_issued(i) <= '1';
                        count <= count - 1;
                        finished_ALU1_s <= '1';
                    end if;
                    exit;
                end if;
            end loop;
            
            -- finds a ready entry and forwards it to ALU pipeline-2
            for i in 0 to size-1 loop
                if (rd_ALU2 = '1' and rs_ready(i) = '1' and rs_issued(i) = '0') then
                    if (rs_control(i)(5 downto 2) = "0001" or rs_control(i)(5 downto 2) = "0010" or rs_control(i)(5 downto 2) = "0000") then
                        -- ADD, ADC, ADZ, ADL, ADI, NDU, NDC, NDZ
                        pc_ALU2 <= rs_pc(i);
                        ra_ALU2 <= rs_opr1(i);
                        rb_ALU2 <= rs_opr2(i);
                        imm6_ALU2 <= rs_imm_6(i);
                        c_ALU1_out <= rs_c(i)(0);
                        z_ALU1_out <= rs_z(i)(0);
                        control_ALU2 <= rs_control(i);
                        rs_issued(i) <= '1';
                        count <= count - 1;
                        finished_ALU2_s <= '1';
                    end if;
                    exit;
                end if;
            end loop;
        end if;
    end process p2;

    -- responsible for updating operand-1 received from execution pipelines
    p3: process(clk, rs_v1, rs_opr1, rr1_ALU1, rr1_ALU2, finished_ALU1, finished_ALU2, data_ALU1, data_ALU2)
        begin
        -- updates operand 1 if tag matches
        if rising_edge(clk) then
            for i in 0 to size-1 loop
                if (rs_v1(i) = '0' and rs_opr1(i)(7 downto 0) = rr1_ALU1 and finished_ALU1 = '1') then
                    rs_opr1(i) <= data_ALU1;
                    rs_v1(i) <= '1';
                end if;

                if (rs_v1(i) = '0' and rs_opr1(i)(7 downto 0) = rr1_ALU2 and finished_ALU2 = '1') then
                    rs_opr1(i) <= data_ALU2;
                    rs_v1(i) <= '1';
                end if;
            end loop;
        end if;
    end process p3;

    -- responsible for updating operand-2 received from execution pipelines
    p4: process(clk, rs_v2, rs_opr2, rr1_ALU1, rr1_ALU2, finished_ALU1, finished_ALU2, data_ALU1, data_ALU2)
        begin
        -- updates operand 2 if tag matches
        if rising_edge(clk) then
            for i in 0 to size-1 loop
                if (rs_v2(i) = '0' and rs_opr2(i)(7 downto 0) = rr1_ALU1 and finished_ALU1 = '1') then
                    rs_opr2(i) <= data_ALU1;
                    rs_v2(i) <= '1';
                end if;

                if (rs_v2(i) = '0' and rs_opr2(i)(7 downto 0) = rr1_ALU2 and finished_ALU2 = '1') then
                    rs_opr2(i) <= data_ALU2;
                    rs_v2(i) <= '1';
                end if;
            end loop;
        end if;
    end process p4;

    -- responsible for updating carry flag received from execution pipelines
    p5: process(clk, rs_v3, rs_c, rr2_ALU1, rr2_ALU2, finished_ALU1, finished_ALU2, c_ALU1_in, c_ALU2_in)
        begin
        -- updates carry flag if tag matches
        if rising_edge(clk) then
            for i in 0 to size-1 loop
                if (rs_v3(i) = '0' and rs_c(i) = rr2_ALU1 and finished_ALU1 = '1') then
                    rs_c(i) <= "0000000" & c_ALU1_in;
                    rs_v3(i) <= '1';
                end if;

                if (rs_v3(i) = '0' and rs_c(i) = rr2_ALU2 and finished_ALU2 = '1') then
                    rs_c(i) <= "0000000" & c_ALU2_in;
                    rs_v3(i) <= '1';
                end if;
            end loop;
        end if;
    end process p5;

    -- responsible for updating zero flag received from execution pipelines
    p6: process(clk, rs_v3, rs_c, rr3_ALU1, rr3_ALU2, finished_ALU1, finished_ALU2, z_ALU1_in, z_ALU2_in)
        begin
        -- updates zero flag if tag matches
        if rising_edge(clk) then
            for i in 0 to size-1 loop
                if (rs_v4(i) = '0' and rs_z(i) = rr3_ALU1 and finished_ALU1 = '1') then
                    rs_z(i) <= "0000000" & z_ALU1_in;
                    rs_v4(i) <= '1';
                end if;

                if (rs_v4(i) = '0' and rs_z(i) = rr3_ALU2 and finished_ALU2 = '1') then
                    rs_z(i) <= "0000000" & z_ALU2_in;
                    rs_v4(i) <= '1';
                end if;
            end loop;
        end if;
    end process p6;

    p7: process(rs_control, rs_v1, rs_v2, rs_v3, rs_v4)
        begin
        -- update the ready bit
        for i in 0 to size-1 loop
            if (rs_control(i)(5 downto 2) = "0000") then
                -- ADI
                rs_ready(i) <= rs_v1(i);
            elsif (rs_control(i)(5 downto 2) = "0001" or rs_control(i)(5 downto 2) = "0010") then
                if (rs_control(i)(1 downto 0) = "00") then
                    -- ADD, NDU
                    rs_ready(i) <= rs_v1(i) AND rs_v2(i);
                elsif (rs_control(i)(1 downto 0) = "10") then
                    -- ADC, NDC
                    rs_ready(i) <= rs_v1(i) AND rs_v2(i) AND rs_v3(i);
                elsif (rs_control(i)(1 downto 0) = "01") then
                    -- ADZ, NDZ
                    rs_ready(i) <= rs_v1(i) AND rs_v2(i) AND rs_v4(i);
                else 
                    -- ADL
                    rs_ready(i) <= rs_v1(i) AND rs_v2(i);
                end if;
            else 
                -- Default (more cases for other instructions)
                rs_ready(i) <= rs_v1(i) AND rs_v2(i) AND rs_v3(i) AND rs_v4(i);
            end if;
        end loop;
    end process p7;

    -- sets the full and empty bits to take care of stalls
    almost_full <= '1' when count = size-1 else '0';
    full  <= '1' when count = size else '0';
    empty <= '1' when count = 0 else '0';
    finished_ALU1_out <= '1' when finished_ALU1_s = '1' else '0';
    finished_ALU2_out <= '1' when finished_ALU2_s = '1' else '0';
    almost_full_out <= almost_full;
    full_out <= full;
    empty_out <= empty; 
    
end behavioural;