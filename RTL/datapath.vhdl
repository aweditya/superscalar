LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY datapath IS
    PORT (
        reset, clk : IN STD_LOGIC;
        output_proc : STD_LOGIC_VECTOR(63 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE arch IS

    -- components --
    COMPONENT aluexecpipe IS
        PORT (
            control_sig_in : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
            -- bit 1 and 0 are for mux 
            --  00 - rb_data, 01 - leftshift(rb_data), 10 - se6(rb_data), 11 - invalid

            -- bit 3 and 2 are for alu operation same as in alu.vhdl
            --  01 - add, 10 - nand, 11 - xor, 00 - invalid

            -- bit 4 is c_flag_enable for carry flag modification
            -- bit 5 is z_flag_enable for zero flag modification
            ra_data, rb_data, pc_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            imm_data : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
            c_in, z_in : IN STD_LOGIC := '0';
            c_out, z_out : OUT STD_LOGIC;
            pc_out, result : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    END COMPONENT aluexecpipe;

    COMPONENT IDStage IS
        PORT (
            -- INPUTS
            clr : IN STD_LOGIC;
            clk : IN STD_LOGIC;

            IFID_inc_Op, IFID_PC_Op : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            IFID_IMem_Op : IN STD_LOGIC_VECTOR(31 DOWNTO 0);

            finish_alu_pipe1, finish_alu_pipe2 : IN STD_LOGIC;

            data_rr_alu_1, data_rr_alu_2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            data_result_alu_1, data_result_alu_2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

            carry_rr_alu_1, carry_rr_alu_2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            carry_result_alu_1, carry_result_alu_2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);

            zero_rr_alu_1, zero_rr_alu_2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            zero_result_alu_1, zero_result_alu_2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);

            inst_complete_exec : IN STD_LOGIC;
            inst_complete_exec_dest : IN STD_LOGIC_VECTOR(2 DOWNTO 0);

            -- OUTPUTS
            wr_inst1, wr_inst2 : OUT STD_LOGIC; -- write bits for newly decoded instructions 
            wr_ALU1, wr_ALU2 : OUT STD_LOGIC; -- write bits for newly executed instructions
            rd_ALU1, rd_ALU2 : OUT STD_LOGIC; -- read bits for issuing ready instructions
            control_inst1, control_inst2 : OUT STD_LOGIC_VECTOR(5 DOWNTO 0); -- control values for the two instructions
            pc_inst1, pc_inst2 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- pc values for the two instructions
            opr1_inst1, opr2_inst1, opr1_inst2, opr2_inst2 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- operand values for the two instructions
            imm6_inst1, imm6_inst2 : OUT STD_LOGIC_VECTOR(5 DOWNTO 0); -- imm6 values for the two instructions
            c_inst1, z_inst1, c_inst2, z_inst2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- carry and zero values for the two instructions
            valid1_inst1, valid2_inst1, valid3_inst1, valid4_inst1 : OUT STD_LOGIC; -- valid bits for first instruction
            valid1_inst2, valid2_inst2, valid3_inst2, valid4_inst2 : OUT STD_LOGIC -- valid bits for second instruction
        );
    END COMPONENT IDStage;

    COMPONENT rob IS
        GENERIC (
            size : INTEGER := 256 -- size of the ROB
        );
        PORT (
            -- INPUTS -------------------------------------------------------------------------------------------
            wr_inst1, wr_inst2 : IN STD_LOGIC; -- write bits for newly decoded instructions 
            wr_ALU1, wr_ALU2 : IN STD_LOGIC; -- write bits for newly executed instructions
            rd : IN STD_LOGIC; -- read bit for finished instructions
            clk : IN STD_LOGIC; -- input clock
            clr : IN STD_LOGIC; -- clear bit
            pc_inst1, pc_inst2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- PC values for writing the newly decoded instructions
            pc_ALU1, pc_ALU2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- PC values for identifying the newly executed instructions
            value_ALU1, value_ALU2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- final output values obtained from the execution pipelines
            dest_inst1, dest_inst2 : IN STD_LOGIC_VECTOR(2 DOWNTO 0); -- destination registers for newly decoded instructions
            rr1_inst1, rr1_inst2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- RR1 for newly decoded instructions
            c_ALU1, z_ALU1, c_ALU2, z_ALU2 : IN STD_LOGIC; -- c and z values obtained from the execution pipelines
            rr2_inst1, rr2_inst2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- RR2 for newly decoded instructions
            rr3_inst1, rr3_inst2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- RR3 for newly decoded instructions

            -- OUTPUTS -------------------------------------------------------------------------------------------
            rr1_ALU1, rr1_ALU2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- RR1 values for both ALU pipelines to which value is written to
            rr2_ALU1, rr2_ALU2, rr3_ALU1, rr3_ALU2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- RR2, RR3 values for both ALU pipelines to which flags are written to
            dest_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0); -- destination register for final output
            full_out, empty_out : OUT STD_LOGIC; -- full and empty bits for the ROB Buffer
            completed: OUT STD_LOGIC -- bit for when an instruction is completed
        );
    END COMPONENT rob;

    COMPONENT Control IS
        PORT (

            --INPUTS------------------------------------
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            wr_fetch : IN STD_LOGIC;
            wr_rs : IN STD_LOGIC;
            wr_wb_mem : IN STD_LOGIC;
            wr_wb_regfile : IN STD_LOGIC;

            --OUTPUTS----------------------------------
            adv_fetch : OUT STD_LOGIC;
            adv_rs : OUT STD_LOGIC;
            adv_wb : OUT STD_LOGIC;
            flush_out : OUT STD_LOGIC; -- In case of a branch misprediction, we need to flush the pipeline. This will route to all of the pipelines and flush them.
            stall_out : OUT STD_LOGIC -- For completeness sake, will remove if not required.
            end_of_program : OUT STD_LOGIC -- This will be used to stop the pipeline. Equivalent to a permanent stall, differs in functioning.

        );
    END COMPONENT;

    -- signals for id - alu pipe--
    SIGNAL opr1_inst1_IDA, opr1_inst2_IDA, opr2_inst1_IDA, opr2_inst2_IDA : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL imm6_inst1_IDA, imm6_inst2_IDA : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL pc_inst1_IDA, pc_inst2_IDA : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL c_inst1_IDA, c_inst2_IDA, z_inst1_IDA, z_inst2_IDA : STD_LOGIC;
    SIGNAL control_inst1_IDA, control_inst2_IDA : STD_LOGIC_VECTOR(5 DOWNTO 0);

    -- signals    --
    SIGNAL pc_inst1_DW, pc_inst2_DW : STD_LOGIC_VECTOR(15 DOWNTO 0); -- PC values for writing the newly decoded instructions
    SIGNAL pc_ALU1_EW, pc_ALU2_EW : STD_LOGIC_VECTOR(15 DOWNTO 0); -- PC values for identifying the newly executed instructionssignal 
    SIGNAL value_ALU1_EW, value_ALU2_EW : STD_LOGIC_VECTOR(15 DOWNTO 0); -- final output values obtained from the execution pipelines
    SIGNAL dest_inst1_DW, dest_inst2_DW : STD_LOGIC_VECTOR(4 DOWNTO 0); -- destination registers for newly decoded instructions
    SIGNAL rr1_inst1_DW, rr1_inst2_DW : STD_LOGIC_VECTOR(7 DOWNTO 0); -- RR1 for newly decoded instructions
    SIGNAL c_ALU1_EW, z_ALU1_EW, c_ALU2_EW, z_ALU2_EW : STD_LOGIC; -- c and z values obtained from the execution pipelines
    SIGNAL rr2_inst1_DW, rr2_inst2_DW : STD_LOGIC_VECTOR(7 DOWNTO 0); -- RR2 for newly decoded instructions
    SIGNAL rr3_inst1_DW, rr3_inst2_DW : STD_LOGIC_VECTOR(7 DOWNTO 0); -- RR3 for newly decoded instructions

BEGIN
    -- processes--
    -- port maps --

    idstage1 : IDStage PORT MAP(
        clr => clr,
        clk => clk,

        IFID_inc_Op =>
        IFID_PC_Op =>
        IFID_IMem_Op =>
        finish_alu_pipe1 =>
        finish_alu_pipe2 =>
        data_rr_alu_1 => rr1_ALU1_ED,
        data_rr_alu_2 => rr1_ALU2_ED,
        data_result_alu_1 => value_ALU1_EW,
        data_result_alu_2 => value_ALU2_EW,
        carry_rr_alu_1 => rr2_ALU1_ED,
        carry_rr_alu_2 => rr2_ALU2_ED,
        carry_result_alu_1 => c_ALU1_EW,
        carry_result_alu_2 => c_ALU2_EW,
        zero_rr_alu_1 => rr3_ALU1_ED,
        zero_rr_alu_2 => rr3_ALU2_ED,
        zero_result_alu_1 => z_ALU1_EW,
        zero_result_alu_2 => z_ALU2_EW,
        inst_complete_exec => completed_WD,
        inst_complete_exec_dest => dest_WD

        opr1_inst1 => opr1_inst1_IDA,
        opr2_inst1 => opr2_inst1_IDA,
        opr1_inst2 => opr1_inst2_IDA,
        opr2_inst2 => opr2_inst2_IDA,
        imm6_inst1 => imm6_inst1_IDA,
        imm6_inst2 => imm6_inst2_IDA,
        pc_inst1 => pc_inst1_IDA,
        pc_inst2 => pc_inst2_IDA,
        z_inst1 => z_inst1_IDA,
        z_inst2 => z_inst2_IDA,
        c_inst1 => c_inst1_IDA,
        c_inst2 => c_inst2_IDA,
        control_inst1 => control_inst1_IDA,
        control_inst2 => control_inst2_IDA,
        wr_inst1 =>
        wr_inst2 =>
        wr_ALU1 =>
        wr_ALU2 =>
        rd_ALU1 =>
        rd_ALU2 =>
        valid1_inst1 =>
        valid2_inst1 =>
        valid3_inst1 =>
        valid4_inst1 =>
        valid1_inst2 =>
        valid2_inst2 =>
        valid3_inst2 =>
        valid4_inst2 =>
    );
    --Nikhil control.vhdl:  add the adv_fetch signal for control stage connection.
    alu1 : aluexecpipe PORT MAP(
        control_sig_in => control_inst1_IDA,
        ra_data => opr1_inst1_IDA,
        rb_data => opr2_inst1_IDA,
        pc_in => pc_inst1_IDA,
        imm_data => imm6_inst1_IDA,
        c_in => c_inst1_IDA,
        z_in => z_inst1_IDA,
        c_out => c_ALU2_EW,
        z_out => z_ALU2_EW,
        pc_out => pc_ALU1_EW,
        result => value_ALU1_EW
    );

    alu2 : aluexecpipe PORT MAP(
        control_sig_in => control_inst2_IDA,
        ra_data => opr1_inst2_IDA,
        rb_data => opr2_inst2_IDA,
        pc_in => pc_inst2_IDA,
        imm_data => imm6_inst2_IDA,
        c_in => c_inst2_IDA,
        z_in => z_inst2_IDA,
        c_out => c_ALU2_EW,
        z_out => z_ALU2_EW,
        pc_out => pc_ALU2_EW,
        result => value_ALU2_EW
    );

    rob1 : rob PORT MAP(
        clk => clk,
        clr => reset,
        wr_inst1 =>
        wr_inst2 =>
        wr_ALU1 =>
        wr_ALU2 =>
        pc_inst1 => pc_inst1_DW,
        pc_inst2 => pc_inst2_DW,
        pc_ALU1 => pc_ALU1_EW,
        pc_ALU2 => pc_ALU2_EW,
        value_ALU1 => value_ALU1_EW,
        value_ALU2 => value_ALU2_EW,
        dest_inst1 => dest_inst1_DW,
        dest_inst2 => dest_inst2_DW,
        rr1_inst1 => rr1_inst1_DW,
        rr1_inst2 => rr1_inst2_DW,
        c_ALU1 => c_ALU1_EW,
        z_ALU1 => z_ALU1_EW,
        c_ALU2 => c_ALU2_EW,
        z_ALU2 => z_ALU2_EW,
        rr2_inst1 => rr2_inst1_DW,
        rr2_inst2 => rr2_inst2_DW,
        rr3_inst1 => rr3_inst1_DW,
        rr3_inst2 => rr3_inst2_DW,
        rr1_ALU1 => rr1_ALU1_ED,
        rr1_ALU2 => rr1_ALU2_ED,
        rr2_ALU1 => rr2_ALU1_ED,
        rr2_ALU2 => rr2_ALU2_ED,
        rr3_ALU1 => rr3_ALU1_ED,
        rr3_ALU2 => rr3_ALU2_ED,
        dest_out => dest_WD,
        completed => completed_WD,
        full_out =>
        empty_out =>
    );
END ARCHITECTURE;