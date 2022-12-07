LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY datapath IS
    PORT (
        reset, clk : IN STD_LOGIC;
        output_proc : STD_LOGIC_VECTOR(63 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE arch OF datapath IS
    -- Instruction Fetch --
    COMPONENT IFStage IS
        PORT (
            reset : IN STD_LOGIC;
            clk : IN STD_LOGIC;

            wr_IFID : OUT STD_LOGIC; -- Logic required in case of pipeline stall. For the time being, we always write
            IFID_inc_D, IFID_PC_D : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            IFID_IMem_D : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT IFStage;

    COMPONENT IFID IS
        PORT (
            clk, clr : IN STD_LOGIC;
            wr_IFID : IN STD_LOGIC;
            IFID_inc_D, IFID_PC_D : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            IFID_IMem_D : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            IFID_inc_Op, IFID_PC_Op : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            IFID_IMem_Op : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT IFID;

    -- Instruction Decode --
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
            rs_almost_full, rs_full : IN STD_LOGIC;

            -- OUTPUTS
            wr_inst1, wr_inst2 : OUT STD_LOGIC; -- write bits for newly decoded instructions 
            control_inst1, control_inst2 : OUT STD_LOGIC_VECTOR(5 DOWNTO 0); -- control values for the two instructions
            pc_inst1, pc_inst2 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- pc values for the two instructions
            opr1_inst1, opr2_inst1, opr1_inst2, opr2_inst2 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- operand values for the two instructions
            imm6_inst1, imm6_inst2 : OUT STD_LOGIC_VECTOR(5 DOWNTO 0); -- imm6 values for the two instructions
            c_inst1, z_inst1, c_inst2, z_inst2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- carry and zero values for the two instructions
            valid1_inst1, valid2_inst1, valid3_inst1, valid4_inst1 : OUT STD_LOGIC; -- valid bits for first instruction
            valid1_inst2, valid2_inst2, valid3_inst2, valid4_inst2 : OUT STD_LOGIC -- valid bits for second instruction
        );
    END COMPONENT IDStage;
    -- 
    -- Reservation Station
    COMPONENT rs IS
        GENERIC (
            size : INTEGER := 256
        );
        PORT (
            -- INPUTS 
            clk : IN STD_LOGIC; -- input clock
            clr : IN STD_LOGIC; -- clear bit
            wr_inst1, wr_inst2 : IN STD_LOGIC; -- write bits for newly decoded instructions 
            -- wr_ALU1, wr_ALU2 : IN STD_LOGIC; -- write bits for newly executed instructions
            rd_ALU1, rd_ALU2 : IN STD_LOGIC; -- read bits for issuing ready instructions
            control_inst1, control_inst2 : IN STD_LOGIC_VECTOR(5 DOWNTO 0); -- control values for the two instructions
            pc_inst1, pc_inst2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- pc values for the two instructions
            opr1_inst1, opr2_inst1, opr1_inst2, opr2_inst2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- operand values for the two instructions
            imm6_inst1, imm6_inst2 : IN STD_LOGIC_VECTOR(5 DOWNTO 0); -- imm6 values for the two instructions
            c_inst1, z_inst1, c_inst2, z_inst2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- carry and zero values for the two instructions
            valid1_inst1, valid2_inst1, valid3_inst1, valid4_inst1 : IN STD_LOGIC; -- valid bits for first instruction
            valid1_inst2, valid2_inst2, valid3_inst2, valid4_inst2 : IN STD_LOGIC; -- valid bits for second instruction
            data_ALU1, data_ALU2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- data forwarded from the execution pipelines
            rr1_ALU1, rr1_ALU2, rr2_ALU1, rr2_ALU2, rr3_ALU1, rr3_ALU2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- rr values coming from the ROB corresponding to execution pipeline outputs
            c_ALU1_in, z_ALU1_in, c_ALU2_in, z_ALU2_in : IN STD_LOGIC; -- carry and zero values forwarded from the execution pipelines
            finished_ALU1, finished_ALU2 : STD_LOGIC; -- finished bits coming from the execution pipelines

            -- OUTPUTS
            pc_ALU1, pc_ALU2 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- pc values forwarded to each execution pipeline
            control_ALU1, control_ALU2 : OUT STD_LOGIC_VECTOR(5 DOWNTO 0); -- control to go to the control generator for the ALU pipelines
            ra_ALU1, rb_ALU1, ra_ALU2, rb_ALU2 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- operand values forwarded to each execution pipeline
            imm6_ALU1, imm6_ALU2 : OUT STD_LOGIC_VECTOR(5 DOWNTO 0); -- imm6 values forwarded to each execution pipeline
            c_ALU1_out, z_ALU1_out, c_ALU2_out, z_ALU2_out : OUT STD_LOGIC; -- carry and zero values forwarded to each execution pipeline
            almost_full_out, full_out, empty_out : OUT STD_LOGIC; -- full and empty bits for the RS
            finished_ALU1_out, finished_ALU2_out : OUT STD_LOGIC -- instruction has been scheduled to the pipeline
        );
    END COMPONENT rs;
    -- 
    -- ALU Execution Pipeline
    COMPONENT ALUPipeControlGenerator IS
        PORT (
            control_in : IN STD_LOGIC_VECTOR(5 DOWNTO 0); -- opcode + last two bits of the instruction
            carry_in, zero_in : IN STD_LOGIC; -- carry and zero coming from the RS
            control_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
        );
    END COMPONENT ALUPipeControlGenerator;

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
    -- 
    -- Reorder Buffer (ROB)
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
            completed : OUT STD_LOGIC -- bit for when an instruction is completed
        );
    END COMPONENT rob;
    -- 
    -- Control Unit
    COMPONENT Control IS
        PORT (
            --INPUTS------------------------------------
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            wr_fetch : IN STD_LOGIC;
            rs_full_input : IN STD_LOGIC; --connect to full_out,
            rs_almost_full_input : IN STD_LOGIC; --connect to almost_full_out,
            wr_wb_mem : IN STD_LOGIC;
            wr_wb_regfile : IN STD_LOGIC;
            end_of_program : IN STD_LOGIC; -- This will be used to stop the pipeline. Equivalent to a permanent stall, differs in functioning.
            --OUTPUTS----------------------------------
            adv_fetch : OUT STD_LOGIC;
            adv_rs : OUT STD_LOGIC;
            adv_wb : OUT STD_LOGIC;
            rs_full : OUT STD_LOGIC; --connect to rs_almost_full, rs_full of id stage
            rs_almost_full : OUT STD_LOGIC;
            adv_rob : OUT STD_LOGIC;
            flush_out : OUT STD_LOGIC; -- In case of a branch misprediction, we need to flush the pipeline. This will route to all of the pipelines and flush them.
            stall_out : OUT STD_LOGIC -- For completeness sake, will remove if not required.

        );
    END COMPONENT;
    -- 

    --signals for if and fetch buffer --
    SIGNAL wr_IFID_IFFB : STD_LOGIC;
    SIGNAL IFID_inc_D_IFFB, IFID_PC_D_IFFB : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL IFID_IMem_D_IFFB : STD_LOGIC_VECTOR(31 DOWNTO 0);

    --signals for fetch buffer and id --
    SIGNAL IFID_inc_Op_FBID, IFID_PC_Op_FBID : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL IFID_IMem_Op_FBID : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- signals from ID to RS --
    SIGNAL opr1_inst1_DR, opr1_inst2_DR : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL opr2_inst1_DR, opr2_inst2_DR : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL imm6_inst1_DR, imm6_inst2_DR : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL pc_inst1_DR, pc_inst2_DR : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL c_inst1_DR, c_inst2_DR, z_inst1_DR, z_inst2_DR : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL control_inst1_DR, control_inst2_DR : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL wr_inst1_DR, wr_inst2_DR : STD_LOGIC;
    SIGNAL wr_ALU1_DR, wr_ALU2_DR : STD_LOGIC;
    SIGNAL rd_ALU1_DR, rd_ALU2_DR : STD_LOGIC;
    SIGNAL valid1_inst1_DR, valid2_inst1_DR, valid3_inst1_DR, valid4_inst1_DR : STD_LOGIC;
    SIGNAL valid1_inst2_DR, valid2_inst2_DR, valid3_inst2_DR, valid4_inst2_DR : STD_LOGIC;

    -- signals from ID to ROB
    SIGNAL rr1_inst1_DR, rr1_inst2_DR, rr2_inst1_DR, rr2_inst2_DR, rr3_inst1_DR, rr3_inst2_DR : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL dest_inst1_DR, dest_inst2_DR : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- signals for rs - alupipe connections --
    SIGNAL pc_ALU1_RSAP, pc_ALU2_RSAP : STD_LOGIC_VECTOR(15 DOWNTO 0); -- pc values forwarded to each execution pipeline
    SIGNAL ra_ALU1_RSAP, rb_ALU1_RSAP, ra_ALU2_RSAP, rb_ALU2_RSAP : STD_LOGIC_VECTOR(15 DOWNTO 0); -- operand values forwarded to each execution pipeline
    SIGNAL imm6_ALU1_RSAP, imm6_ALU2_RSAP : STD_LOGIC_VECTOR(5 DOWNTO 0); -- imm6 values forwarded to each execution pipeline
    SIGNAL c_ALU1_out_RSAP, z_ALU1_out_RSAP, c_ALU2_out_RSAP, z_ALU2_out_RSAP : STD_LOGIC; -- carry and zero values forwarded to each execution pipeline

    -- signals for rs - alucongen --
    SIGNAL control_ALU1_RSACG, control_ALU2_RSACG : STD_LOGIC_VECTOR(5 DOWNTO 0); -- for control sig

    -- signals for alucongen - alupipe --
    SIGNAL control_ALU1_ACGAP, control_ALU2_ACGAP : STD_LOGIC_VECTOR(5 DOWNTO 0);

    -- signal from EXEC to ROB --
    SIGNAL pc_ALU1_EW, pc_ALU2_EW : STD_LOGIC_VECTOR(15 DOWNTO 0); -- PC values for identifying the newly executed instructions
    SIGNAL value_ALU1_EW, value_ALU2_EW : STD_LOGIC_VECTOR(15 DOWNTO 0); -- final output values obtained from the execution pipelines
    SIGNAL c_ALU1_EW, z_ALU1_EW, c_ALU2_EW, z_ALU2_EW : STD_LOGIC; -- c and z values obtained from the execution pipelines
    SIGNAL finished_ALU1_RE, finished_ALU2_RE : STD_LOGIC;

    -- signals for ROB - ID connections
    SIGNAL rr1_ALU1_ED, rr1_ALU2_ED : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL rr2_ALU1_ED, rr2_ALU2_ED, rr3_ALU1_ED, rr3_ALU2_ED : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL dest_WD : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL completed_WD : STD_LOGIC;

    ---CONTROLLER SIGNALS---

    --CT as:
    --       suffix -> input to controller
    --       prefix -> output from controller
    SIGNAL almost_full_out_CT : STD_LOGIC;
    SIGNAL full_out_CT : STD_LOGIC;
    SIGNAL empty_out_CT : STD_LOGIC;
    SIGNAL CT_rs_full : STD_LOGIC;
    SIGNAL CT_rs_almost_full : STD_LOGIC;
    SIGNAL CT_stall_out : STD_LOGIC;
    SIGNAL CT_flush_out : STD_LOGIC;
    SIGNAL from_future_default_set : STD_LOGIC := '1';
    SIGNAL from_future_default_unset : STD_LOGIC := '0';
    ------------------------

BEGIN
    -- port maps --
    instfetch : IFStage PORT MAP(
        clk => clk,
        reset => reset,
        wr_IFID => wr_IFID_IFFB,
        IFID_inc_D => IFID_inc_D_IFFB,
        IFID_PC_D => IFID_PC_D_IFFB,
        IFID_IMem_D => IFID_IMem_D_IFFB
    );

    fetchbuffer : IFID PORT MAP(
        clk => clk,
        clr => reset,
        wr_IFID => wr_IFID_IFFB,
        IFID_inc_D => IFID_inc_D_IFFB,
        IFID_PC_D => IFID_PC_D_IFFB,
        IFID_IMem_D => IFID_IMem_D_IFFB,
        IFID_inc_Op => IFID_inc_Op_FBID,
        IFID_PC_Op => IFID_PC_Op_FBID,
        IFID_IMem_Op => IFID_IMem_Op_FBID
    );

    idstage1 : IDStage PORT MAP(
        clr => reset,
        clk => clk,
        IFID_inc_Op => IFID_inc_Op_FBID,
        IFID_PC_Op => IFID_PC_Op_FBID,
        IFID_IMem_Op => IFID_IMem_Op_FBID,
        finish_alu_pipe1 => finished_ALU1_RE,
        finish_alu_pipe2 => finished_ALU2_RE,
        data_rr_alu_1 => rr1_ALU1_ED,
        data_rr_alu_2 => rr1_ALU2_ED,
        data_result_alu_1 => value_ALU1_EW,
        data_result_alu_2 => value_ALU2_EW,
        carry_rr_alu_1 => rr2_ALU1_ED,
        carry_rr_alu_2 => rr2_ALU2_ED,
        carry_result_alu_1(0) => c_ALU1_EW,
        carry_result_alu_2(0) => c_ALU2_EW,
        zero_rr_alu_1 => rr3_ALU1_ED,
        zero_rr_alu_2 => rr3_ALU2_ED,
        zero_result_alu_1(0) => z_ALU1_EW,
        zero_result_alu_2(0) => z_ALU2_EW,
        inst_complete_exec => completed_WD,
        inst_complete_exec_dest => dest_WD,
        rs_almost_full => CT_rs_almost_full, 
        rs_full => CT_rs_full,


        opr1_inst1 => opr1_inst1_DR,
        opr2_inst1 => opr2_inst1_DR,
        opr1_inst2 => opr1_inst2_DR,
        opr2_inst2 => opr2_inst2_DR,
        imm6_inst1 => imm6_inst1_DR,
        imm6_inst2 => imm6_inst2_DR,
        pc_inst1 => pc_inst1_DR,
        pc_inst2 => pc_inst2_DR,
        c_inst1 => c_inst1_DR,
        c_inst2 => c_inst2_DR,
        z_inst1 => z_inst1_DR,
        z_inst2 => z_inst2_DR,
        control_inst1 => control_inst1_DR,
        control_inst2 => control_inst2_DR,
        wr_inst1 => wr_inst1_DR,
        wr_inst2 => wr_inst2_DR,
        valid1_inst1 => valid1_inst1_DR,
        valid2_inst1 => valid2_inst1_DR,
        valid3_inst1 => valid3_inst1_DR,
        valid4_inst1 => valid4_inst1_DR,
        valid1_inst2 => valid1_inst2_DR,
        valid2_inst2 => valid2_inst2_DR,
        valid3_inst2 => valid3_inst2_DR,
        valid4_inst2 => valid4_inst2_DR
    );

    rs1 : rs GENERIC MAP(
        size => 256
    )
    PORT MAP(
        clk => clk,
        clr => reset,
        wr_inst1 => wr_inst1_DR,
        wr_inst2 => wr_inst2_DR,
        --wr_ALU1 => wr_ALU1_DR,
        --wr_ALU2 => wr_ALU2_DR,
        rd_ALU1 => '1',
        rd_ALU2 => '1',
        control_inst1 => control_inst1_DR,
        control_inst2 => control_inst2_DR,
        pc_inst1 => pc_inst1_DR,
        pc_inst2 => pc_inst2_DR,
        opr1_inst1 => opr1_inst1_DR,
        opr2_inst1 => opr2_inst1_DR,
        opr1_inst2 => opr1_inst2_DR,
        opr2_inst2 => opr2_inst2_DR,
        imm6_inst1 => imm6_inst1_DR,
        imm6_inst2 => imm6_inst2_DR,
        c_inst1 => c_inst1_DR,
        c_inst2 => c_inst2_DR,
        z_inst1 => z_inst1_DR,
        z_inst2 => z_inst2_DR,
        valid1_inst1 => valid1_inst1_DR,
        valid2_inst1 => valid2_inst1_DR,
        valid3_inst1 => valid3_inst1_DR,
        valid4_inst1 => valid4_inst1_DR,
        valid1_inst2 => valid1_inst2_DR,
        valid2_inst2 => valid2_inst2_DR,
        valid3_inst2 => valid3_inst2_DR,
        valid4_inst2 => valid4_inst2_DR,
        data_ALU1 => value_ALU1_EW,
        data_ALU2 => value_ALU2_EW,
        rr1_ALU1 => rr1_ALU1_ED,
        rr1_ALU2 => rr1_ALU2_ED,
        rr2_ALU1 => rr2_ALU1_ED,
        rr2_ALU2 => rr2_ALU2_ED,
        rr3_ALU1 => rr3_ALU1_ED,
        rr3_ALU2 => rr3_ALU2_ED,
        c_ALU1_in => c_ALU1_EW,
        z_ALU1_in => z_ALU1_EW,
        c_ALU2_in => c_ALU2_EW,
        z_ALU2_in => z_ALU2_EW,
        finished_ALU1 => finished_ALU1_RE,
        finished_ALU2 => finished_ALU2_RE,

        pc_ALU1 => pc_ALU1_RSAP,
        pc_ALU2 => pc_ALU2_RSAP,
        ra_ALU1 => ra_ALU1_RSAP,
        rb_ALU1 => rb_ALU1_RSAP,
        ra_ALU2 => ra_ALU2_RSAP,
        rb_ALU2 => rb_ALU2_RSAP,
        imm6_ALU1 => imm6_ALU1_RSAP,
        imm6_ALU2 => imm6_ALU2_RSAP,
        c_ALU1_out => c_ALU1_out_RSAP,
        z_ALU1_out => z_ALU1_out_RSAP,
        c_ALU2_out => c_ALU2_out_RSAP,
        z_ALU2_out => z_ALU2_out_RSAP,
        almost_full_out => almost_full_out_CT,
        full_out => full_out_CT,
        empty_out => empty_out_CT,
        finished_ALU1_out => finished_ALU1_RE,
        finished_ALU2_out => finished_ALU1_RE,
        control_ALU1 => control_ALU1_RSACG,
        control_ALU2 => control_ALU2_RSACG
    );

    alucongen1 : ALUPipeControlGenerator PORT MAP(
        control_in => control_ALU1_RSACG,
        carry_in => c_ALU1_out_RSAP,
        zero_in => z_ALU1_out_RSAP,
        control_out => control_ALU1_ACGAP
    );

    alu1 : aluexecpipe PORT MAP(
        control_sig_in => control_ALU1_ACGAP,
        ra_data => ra_ALU1_RSAP,
        rb_data => rb_ALU1_RSAP,
        pc_in => pc_ALU1_RSAP,
        imm_data => imm6_ALU1_RSAP,
        c_in => c_ALU1_out_RSAP,
        z_in => z_ALU1_out_RSAP,
        c_out => c_ALU2_EW,
        z_out => z_ALU2_EW,
        pc_out => pc_ALU1_EW,
        result => value_ALU1_EW
    );

    alucongen2 : ALUPipeControlGenerator PORT MAP(
        control_in => control_ALU1_RSACG,
        carry_in => c_ALU2_out_RSAP,
        zero_in => z_ALU2_out_RSAP,
        control_out => control_ALU2_ACGAP
    );

    alu2 : aluexecpipe PORT MAP(
        control_sig_in => control_ALU2_ACGAP,
        ra_data => ra_ALU2_RSAP,
        rb_data => rb_ALU2_RSAP,
        pc_in => pc_ALU2_RSAP,
        imm_data => imm6_ALU2_RSAP,
        c_in => c_ALU2_out_RSAP,
        z_in => z_ALU2_out_RSAP,
        c_out => c_ALU2_EW,
        z_out => z_ALU2_EW,
        pc_out => pc_ALU2_EW,
        result => value_ALU2_EW
    );

    rob1 : rob PORT MAP(
        clk => clk,
        clr => reset,
        rd => '1',
        wr_inst1 => wr_inst1_DR,
        wr_inst2 => wr_inst2_DR,
        wr_ALU1 => finished_ALU1_RE,
        wr_ALU2 => finished_ALU2_RE,
        pc_inst1 => pc_inst1_DR,
        pc_inst2 => pc_inst2_DR,
        pc_ALU1 => pc_ALU1_EW,
        pc_ALU2 => pc_ALU2_EW,
        value_ALU1 => value_ALU1_EW,
        value_ALU2 => value_ALU2_EW,
        dest_inst1 => dest_inst1_DR,
        dest_inst2 => dest_inst2_DR,
        rr1_inst1 => rr1_inst1_DR,
        rr1_inst2 => rr1_inst2_DR,
        c_ALU1 => c_ALU1_EW,
        z_ALU1 => z_ALU1_EW,
        c_ALU2 => c_ALU2_EW,
        z_ALU2 => z_ALU2_EW,
        rr2_inst1 => rr2_inst1_DR,
        rr2_inst2 => rr2_inst2_DR,
        rr3_inst1 => rr3_inst1_DR,
        rr3_inst2 => rr3_inst2_DR,
        rr1_ALU1 => rr1_ALU1_ED,
        rr1_ALU2 => rr1_ALU2_ED,
        rr2_ALU1 => rr2_ALU1_ED,
        rr2_ALU2 => rr2_ALU2_ED,
        rr3_ALU1 => rr3_ALU1_ED,
        rr3_ALU2 => rr3_ALU2_ED,
        dest_out => dest_WD,
        completed => completed_WD
    );

    Controller : Control PORT MAP(

        --INPUTS------------------------------------
        clk => clk,
        rst => reset,
        wr_fetch => '1',
        rs_full_input => full_out_CT,
        rs_almost_full_input => almost_full_out_CT, --connect to almost_full_out of rs
        wr_wb_mem => from_future_default_set,
        wr_wb_regfile => from_future_default_set,
        end_of_program => from_future_default_unset, --connect to end_of_program of fetch stage       
        -- empty_out_CT unused
        --OUTPUTS----------------------------------
        -- adv_fetch =>
        -- adv_rs =>
        -- adv_wb =>
        rs_full => CT_rs_full, --connect to rs_almost_full, rs_full of id stage
        rs_almost_full => CT_rs_almost_full,
        flush_out => CT_flush_out, -- In case of a branch misprediction, we need to flush the pipeline. This will route to all of the pipelines and flush them.
        stall_out => CT_stall_out,
        adv_rob => open
    );
END ARCHITECTURE;