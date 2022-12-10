LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY datapath IS
    PORT (
        reset, clk : IN STD_LOGIC;
        output_proc : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE arch OF datapath IS
    -- Instruction Fetch --
    COMPONENT IFStage IS
        PORT (
            reset : IN STD_LOGIC;
            clk : IN STD_LOGIC;

            wr_IFID : OUT STD_LOGIC;
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
    COMPONENT IDStage is
        port(
            clr: in std_logic;
            clk: in std_logic;
    
            IFID_inc_Op, IFID_PC_Op: in std_logic_vector(15 downto 0);
            IFID_IMem_Op: in std_logic_vector(31 downto 0);
            
            finish_alu_pipe1, finish_alu_pipe2: in std_logic;
            data_rr_alu_1, data_rr_alu_2: in std_logic_vector(7 downto 0);
            data_result_alu_1, data_result_alu_2: in std_logic_vector(15 downto 0);
            carry_rr_alu_1, carry_rr_alu_2: in std_logic_vector(7 downto 0);
            carry_result_alu_1, carry_result_alu_2: in std_logic_vector(0 downto 0);
            zero_rr_alu_1, zero_rr_alu_2: in std_logic_vector(7 downto 0);
            zero_result_alu_1, zero_result_alu_2: in std_logic_vector(0 downto 0);
    
            finish_lhi: in std_logic;
            data_rr_lhi: in std_logic_vector(7 downto 0);
            data_result_lhi: in std_logic_vector(15 downto 0);
    
            inst_complete_exec: in std_logic;
            inst_complete_exec_dest: in std_logic_vector(2 downto 0);
    
            rs_almost_full, rs_full: in std_logic;
    
            wr_inst1, wr_inst2: out std_logic;
            control_inst1, control_inst2: out std_logic_vector(5 downto 0);
            pc_inst1, pc_inst2: out std_logic_vector(15 downto 0);
            opr1_inst1, opr2_inst1, opr1_inst2, opr2_inst2: out std_logic_vector(15 downto 0);
            imm9_inst1, imm9_inst2: out std_logic_vector(8 downto 0);
            c_inst1, z_inst1, c_inst2, z_inst2: out std_logic_vector(7 downto 0);
            valid1_inst1, valid2_inst1, valid3_inst1, valid4_inst1: out std_logic;
            valid1_inst2, valid2_inst2, valid3_inst2, valid4_inst2: out std_logic;
            dest_inst1, dest_inst2: out std_logic_vector(2 downto 0);
            rr1_inst1, rr1_inst2: out std_logic_vector(7 downto 0);
            rr2_inst1, rr2_inst2: out std_logic_vector(7 downto 0);
            rr3_inst1, rr3_inst2: out std_logic_vector(7 downto 0)
        );
    end COMPONENT;

    -- Reservation Station
    component rs is
        generic(
            size : integer := 256
        );
        port(
            clk: in std_logic;
            clr: in std_logic;
            wr_inst1, wr_inst2: in std_logic;
            control_inst1, control_inst2: in std_logic_vector(5 downto 0);
            pc_inst1, pc_inst2: in std_logic_vector(15 downto 0);
            opr1_inst1, opr2_inst1, opr1_inst2, opr2_inst2: in std_logic_vector(15 downto 0);
            imm9_inst1, imm9_inst2: in std_logic_vector(8 downto 0);
            c_inst1, z_inst1, c_inst2, z_inst2: in std_logic_vector(7 downto 0);
            valid1_inst1, valid2_inst1, valid3_inst1, valid4_inst1: in std_logic;
            valid1_inst2, valid2_inst2, valid3_inst2, valid4_inst2: in std_logic;

            --wr_ALU1, wr_ALU2: in std_logic;
            rd_ALU1, rd_ALU2: in std_logic;
            data_ALU1, data_ALU2: in std_logic_vector(15 downto 0);
            rr1_ALU1, rr1_ALU2: in std_logic_vector(7 downto 0);
            c_ALU1_in, c_ALU2_in: in std_logic;
            rr2_ALU1, rr2_ALU2: in std_logic_vector(7 downto 0);
            z_ALU1_in, z_ALU2_in: in std_logic;
            rr3_ALU1, rr3_ALU2: in std_logic_vector(7 downto 0);
            finished_ALU1, finished_ALU2: std_logic;

            rd_LHI: in std_logic;
            data_LHI: in std_logic_vector(15 downto 0);
            rr_LHI: in std_logic_vector(7 downto 0);
            finished_LHI: std_logic;

            pc_ALU1, pc_ALU2: out std_logic_vector(15 downto 0);
            control_ALU1, control_ALU2: out std_logic_vector(5 downto 0);
            ra_ALU1, rb_ALU1, ra_ALU2, rb_ALU2: out std_logic_vector(15 downto 0);
            imm6_ALU1, imm6_ALU2: out std_logic_vector(5 downto 0);
            c_ALU1_out, z_ALU1_out, c_ALU2_out, z_ALU2_out: out std_logic;
            finished_ALU1_out, finished_ALU2_out: out std_logic;

            pc_LHI: out std_logic_vector(15 downto 0);
            imm9_LHI: out std_logic_vector(8 downto 0);
            finished_LHI_out: out std_logic;

            almost_full_out, full_out, empty_out: out std_logic
        );
    end component;

    -- ALU Execution Pipeline
    COMPONENT ALUPipeControlGenerator IS
        PORT (
            control_in : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
            carry_in, zero_in : IN STD_LOGIC;

            control_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0)
        );
    END COMPONENT ALUPipeControlGenerator;

    COMPONENT aluexecpipe IS
        PORT (
            control_sig_in : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
            ra_data, rb_data, pc_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            imm_data : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
            c_in, z_in : IN STD_LOGIC := '0';

            c_out, z_out : OUT STD_LOGIC;
            pc_out, result : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    END COMPONENT aluexecpipe;

    -- LHI Execution Pipeline
    component lhiexecpipe is
        port(
            pc_in: in std_logic_vector(15 downto 0);
            data_in: in std_logic_vector(8 downto 0);
    
            pc_out: out std_logic_vector(15 downto 0);
            data_out: out std_logic_vector(15 downto 0)
        );
    end component;
    
    -- Reorder Buffer (ROB)
    component rob is 
        generic(
            size : integer := 256
        );
        port(
            clk: in std_logic;
            clr: in std_logic;
            rd: in std_logic;

            wr_inst1, wr_inst2: in std_logic;
            pc_inst1, pc_inst2: in std_logic_vector(15 downto 0);
            dest_inst1, dest_inst2: in std_logic_vector(2 downto 0);
            rr1_inst1, rr1_inst2: in std_logic_vector(7 downto 0);
            rr2_inst1, rr2_inst2: in std_logic_vector(7 downto 0);
            rr3_inst1, rr3_inst2: in std_logic_vector(7 downto 0);

            wr_ALU1, wr_ALU2: in std_logic;
            pc_ALU1, pc_ALU2: in std_logic_vector(15 downto 0);
            value_ALU1, value_ALU2: in std_logic_vector(15 downto 0);
            c_ALU1, c_ALU2: in std_logic;
            z_ALU1, z_ALU2: in std_logic;

            wr_LHI: in std_logic;
            pc_LHI: in std_logic_vector(15 downto 0);
            value_LHI: in std_logic_vector(15 downto 0);

            rr1_ALU1, rr1_ALU2: out std_logic_vector(7 downto 0);
            rr2_ALU1, rr2_ALU2: out std_logic_vector(7 downto 0);
            rr3_ALU1, rr3_ALU2: out std_logic_vector(7 downto 0);

            rr_LHI: out std_logic_vector(7 downto 0);

            dest_out: out std_logic_vector(2 downto 0);
            completed: out std_logic
        );
    end component;
    
    -- Control Unit
    COMPONENT Control IS
       PORT (
           clk : IN STD_LOGIC;
           rst : IN STD_LOGIC;

           wr_fetch : IN STD_LOGIC;
           wr_wb_regfile : IN STD_LOGIC;
           wr_wb_mem : IN STD_LOGIC;

           rs_almost_full_input : IN STD_LOGIC;
           rs_full_input : IN STD_LOGIC;
           
           end_of_program : IN STD_LOGIC;
           
           adv_fetch : OUT STD_LOGIC;
           adv_rs : OUT STD_LOGIC;
           adv_wb : OUT STD_LOGIC;
           adv_rob : OUT STD_LOGIC;

           rs_full : OUT STD_LOGIC;
           rs_almost_full : OUT STD_LOGIC;
           
           flush_out : OUT STD_LOGIC;
           stall_out : OUT STD_LOGIC
       );
    END COMPONENT;

    -- Signals for IF and fetch buffer --
    SIGNAL wr_IFID_IFFB : STD_LOGIC;
    SIGNAL IFID_inc_D_IFFB, IFID_PC_D_IFFB : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL IFID_IMem_D_IFFB : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- Signals for fetch buffer and ID --
    SIGNAL IFID_inc_Op_FBID, IFID_PC_Op_FBID : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL IFID_IMem_Op_FBID : STD_LOGIC_VECTOR(31 DOWNTO 0);

    -- Signals from ID to RS --
    SIGNAL opr1_inst1_DR, opr1_inst2_DR : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL opr2_inst1_DR, opr2_inst2_DR : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL imm9_inst1_DR, imm9_inst2_DR : STD_LOGIC_VECTOR(8 DOWNTO 0);
    SIGNAL pc_inst1_DR, pc_inst2_DR : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL c_inst1_DR, c_inst2_DR, z_inst1_DR, z_inst2_DR : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL control_inst1_DR, control_inst2_DR : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL wr_inst1_DR, wr_inst2_DR : STD_LOGIC;
    SIGNAL wr_ALU1_DR, wr_ALU2_DR : STD_LOGIC;
    SIGNAL rd_ALU1_DR, rd_ALU2_DR : STD_LOGIC;
    SIGNAL valid1_inst1_DR, valid2_inst1_DR, valid3_inst1_DR, valid4_inst1_DR : STD_LOGIC;
    SIGNAL valid1_inst2_DR, valid2_inst2_DR, valid3_inst2_DR, valid4_inst2_DR : STD_LOGIC;

    -- Signals from ID to ROB
    SIGNAL rr1_inst1_DR, rr1_inst2_DR, rr2_inst1_DR, rr2_inst2_DR, rr3_inst1_DR, rr3_inst2_DR : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL dest_inst1_DR, dest_inst2_DR : STD_LOGIC_VECTOR(2 DOWNTO 0) := (others => '0');

    -- Signals for RS - ALU pipeline connections
    SIGNAL pc_ALU1_RSAP, pc_ALU2_RSAP : STD_LOGIC_VECTOR(15 DOWNTO 0); -- PC values forwarded to each execution pipeline
    SIGNAL ra_ALU1_RSAP, rb_ALU1_RSAP, ra_ALU2_RSAP, rb_ALU2_RSAP : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Operand values forwarded to each execution pipeline
    SIGNAL imm6_ALU1_RSAP, imm6_ALU2_RSAP : STD_LOGIC_VECTOR(5 DOWNTO 0); -- imm6 values forwarded to each execution pipeline
    SIGNAL c_ALU1_out_RSAP, z_ALU1_out_RSAP, c_ALU2_out_RSAP, z_ALU2_out_RSAP : STD_LOGIC; -- Carry and zero values forwarded to each execution pipeline

    -- Signals for RS - ALU control generator
    SIGNAL control_ALU1_RSACG, control_ALU2_RSACG : STD_LOGIC_VECTOR(5 DOWNTO 0); -- Control signal

    -- Signals for ALU control generator - ALU pipeline
    SIGNAL control_ALU1_ACGAP, control_ALU2_ACGAP : STD_LOGIC_VECTOR(5 DOWNTO 0);

    -- Signals for RS - LHI pipeline connections
    SIGNAL pc_LHI_RSAP : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL imm9_LHI_RSAP : STD_LOGIC_VECTOR(8 DOWNTO 0);

    -- Signal from EXEC to ROB
    SIGNAL pc_ALU1_EW, pc_ALU2_EW : STD_LOGIC_VECTOR(15 DOWNTO 0); -- PC values for identifying the newly executed instructions
    SIGNAL value_ALU1_EW, value_ALU2_EW : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Final output values obtained from the execution pipelines
    SIGNAL c_ALU1_EW, z_ALU1_EW, c_ALU2_EW, z_ALU2_EW : STD_LOGIC := '0'; -- C and Z values obtained from the execution pipelines

    SIGNAL pc_LHI_EW : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL value_LHI_EW : STD_LOGIC_VECTOR(15 DOWNTO 0);

    SIGNAL finished_ALU1_RE, finished_ALU2_RE : STD_LOGIC;
    SIGNAL finished_LHI_RE : STD_LOGIC;

    -- signals for ROB - ID connections
    SIGNAL rr1_ALU1_ED, rr1_ALU2_ED : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL rr2_ALU1_ED, rr2_ALU2_ED, rr3_ALU1_ED, rr3_ALU2_ED : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL rr_LHI_ED : STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL dest_WD : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL completed_WD : STD_LOGIC;

    -- Signals for the controller
    -- Controller inputs
    SIGNAL almost_full_out_CT : STD_LOGIC;
    SIGNAL full_out_CT : STD_LOGIC;
    SIGNAL empty_out_CT : STD_LOGIC;

    -- Controller outputs
    SIGNAL CT_rs_full : STD_LOGIC;
    SIGNAL CT_rs_almost_full : STD_LOGIC;
    SIGNAL CT_stall_out : STD_LOGIC;
    SIGNAL CT_flush_out : STD_LOGIC;

    SIGNAL from_future_default_set : STD_LOGIC := '1';
    SIGNAL from_future_default_unset : STD_LOGIC := '0';

BEGIN
    fetch : IFStage PORT MAP(
        reset => reset,
        clk => clk,
        
        wr_IFID => wr_IFID_IFFB,
        IFID_inc_D => IFID_inc_D_IFFB,
        IFID_PC_D => IFID_PC_D_IFFB,
        IFID_IMem_D => IFID_IMem_D_IFFB
    );

    fetch_decode : IFID PORT MAP(
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

    decode : IDStage PORT MAP(
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

        finish_lhi => finished_LHI_RE,
        data_rr_lhi => rr_LHI_ED,
        data_result_lhi => value_LHI_EW,

        inst_complete_exec => completed_WD,
        inst_complete_exec_dest => dest_WD,

        rs_almost_full => almost_full_out_CT, 
        rs_full => full_out_CT,

        wr_inst1 => wr_inst1_DR,
        wr_inst2 => wr_inst2_DR,
        control_inst1 => control_inst1_DR,
        control_inst2 => control_inst2_DR,
        pc_inst1 => pc_inst1_DR,
        pc_inst2 => pc_inst2_DR,
        opr1_inst1 => opr1_inst1_DR,
        opr2_inst1 => opr2_inst1_DR,
        opr1_inst2 => opr1_inst2_DR,
        opr2_inst2 => opr2_inst2_DR,
        imm9_inst1 => imm9_inst1_DR,
        imm9_inst2 => imm9_inst2_DR,
        c_inst1 => c_inst1_DR,
        z_inst1 => z_inst1_DR,
        c_inst2 => c_inst2_DR,
        z_inst2 => z_inst2_DR,
        valid1_inst1 => valid1_inst1_DR,
        valid2_inst1 => valid2_inst1_DR,
        valid3_inst1 => valid3_inst1_DR,
        valid4_inst1 => valid4_inst1_DR,
        valid1_inst2 => valid1_inst2_DR,
        valid2_inst2 => valid2_inst2_DR,
        valid3_inst2 => valid3_inst2_DR,
        valid4_inst2 => valid4_inst2_DR,
        dest_inst1 => dest_inst1_DR,
        dest_inst2 => dest_inst2_DR,
        rr1_inst1 => rr1_inst1_DR,
        rr1_inst2 => rr1_inst2_DR,
        rr2_inst1 => rr2_inst1_DR, 
        rr2_inst2 => rr2_inst2_DR,
        rr3_inst1 => rr3_inst1_DR, 
        rr3_inst2 => rr3_inst2_DR
    );   

    reservation_station : rs GENERIC MAP(
        size => 256
    )
    PORT MAP(
        clk => clk,
        clr => reset,
        
        wr_inst1 => wr_inst1_DR,
        wr_inst2 => wr_inst2_DR,
        control_inst1 => control_inst1_DR,
        control_inst2 => control_inst2_DR,
        pc_inst1 => pc_inst1_DR,
        pc_inst2 => pc_inst2_DR,
        opr1_inst1 => opr1_inst1_DR,
        opr2_inst1 => opr2_inst1_DR,
        opr1_inst2 => opr1_inst2_DR,
        opr2_inst2 => opr2_inst2_DR,
        imm9_inst1 => imm9_inst1_DR,
        imm9_inst2 => imm9_inst2_DR,
        c_inst1 => c_inst1_DR,
        z_inst1 => z_inst1_DR,
        c_inst2 => c_inst2_DR,
        z_inst2 => z_inst2_DR,
        valid1_inst1 => valid1_inst1_DR,
        valid2_inst1 => valid2_inst1_DR,
        valid3_inst1 => valid3_inst1_DR,
        valid4_inst1 => valid4_inst1_DR,
        valid1_inst2 => valid1_inst2_DR,
        valid2_inst2 => valid2_inst2_DR,
        valid3_inst2 => valid3_inst2_DR,
        valid4_inst2 => valid4_inst2_DR,

        --wr_ALU1 => wr_ALU1_DR,
        --wr_ALU2 => wr_ALU2_DR,
        rd_ALU1 => '1',
        rd_ALU2 => '1',
        data_ALU1 => value_ALU1_EW,
        data_ALU2 => value_ALU2_EW,
        rr1_ALU1 => rr1_ALU1_ED,
        rr1_ALU2 => rr1_ALU2_ED,
        c_ALU1_in => c_ALU1_EW,
        c_ALU2_in => c_ALU2_EW,
        rr2_ALU1 => rr2_ALU1_ED,
        rr2_ALU2 => rr2_ALU2_ED,
        z_ALU1_in => z_ALU1_EW,
        z_ALU2_in => z_ALU2_EW,
        rr3_ALU1 => rr3_ALU1_ED,
        rr3_ALU2 => rr3_ALU2_ED,
        finished_ALU1 => finished_ALU1_RE,
        finished_ALU2 => finished_ALU2_RE,

        rd_LHI => '1',
        data_LHI => value_LHI_EW,
        rr_LHI => rr_LHI_ED,
        finished_LHI => finished_LHI_RE,

        pc_ALU1 => pc_ALU1_RSAP,
        pc_ALU2 => pc_ALU2_RSAP,
        control_ALU1 => control_ALU1_RSACG,
        control_ALU2 => control_ALU2_RSACG,
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
        finished_ALU1_out => finished_ALU1_RE,
        finished_ALU2_out => finished_ALU2_RE,

        pc_LHI => pc_LHI_RSAP,
        imm9_LHI => imm9_LHI_RSAP,
        finished_LHI_out => finished_LHI_RE,

        almost_full_out => almost_full_out_CT,
        full_out => full_out_CT,
        empty_out => empty_out_CT        
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
        c_out => c_ALU1_EW,
        z_out => z_ALU1_EW,
        pc_out => pc_ALU1_EW,
        result => value_ALU1_EW
    );

    alucongen2 : ALUPipeControlGenerator PORT MAP(
        control_in => control_ALU2_RSACG,
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

    output_proc <= value_ALU1_EW & value_ALU2_EW;

    lhi: lhiexecpipe PORT MAP(
        pc_in => PC_LHI_RSAP,
        data_in => imm9_LHI_RSAP,

        pc_out => PC_LHI_EW,
        data_out => value_LHI_EW
    );

    rob1 : rob PORT MAP(
        clk => clk,
        clr => reset,
        rd => '1',

        wr_inst1 => wr_inst1_DR,
        wr_inst2 => wr_inst2_DR,
        pc_inst1 => pc_inst1_DR,
        pc_inst2 => pc_inst2_DR,
        dest_inst1 => dest_inst1_DR,
        dest_inst2 => dest_inst2_DR,
        rr1_inst1 => rr1_inst1_DR,
        rr1_inst2 => rr1_inst2_DR,
        rr2_inst1 => rr2_inst1_DR,
        rr2_inst2 => rr2_inst2_DR,
        rr3_inst1 => rr3_inst1_DR,
        rr3_inst2 => rr3_inst2_DR,

        wr_ALU1 => finished_ALU1_RE,
        wr_ALU2 => finished_ALU2_RE,
        pc_ALU1 => pc_ALU1_EW,
        pc_ALU2 => pc_ALU2_EW,
        value_ALU1 => value_ALU1_EW,
        value_ALU2 => value_ALU2_EW, 
        c_ALU1 => c_ALU1_EW,
        z_ALU1 => z_ALU1_EW,
        c_ALU2 => c_ALU2_EW,
        z_ALU2 => z_ALU2_EW,
        
        wr_LHI => finished_LHI_RE,
        pc_LHI => pc_LHI_EW,
        value_LHI => value_LHI_EW,

        rr1_ALU1 => rr1_ALU1_ED,
        rr1_ALU2 => rr1_ALU2_ED,
        rr2_ALU1 => rr2_ALU1_ED,
        rr2_ALU2 => rr2_ALU2_ED,
        rr3_ALU1 => rr3_ALU1_ED,
        rr3_ALU2 => rr3_ALU2_ED,

        rr_LHI => rr_LHI_ED,

        dest_out => dest_WD,
        completed => completed_WD
    );

    Controller : Control PORT MAP(
        clk => clk,
        rst => reset,

        wr_fetch => '1',
        wr_wb_regfile => from_future_default_set,
        wr_wb_mem => from_future_default_set,

        rs_almost_full_input => almost_full_out_CT,
        rs_full_input => full_out_CT,
        
        end_of_program => from_future_default_unset,

        adv_fetch => open,
        adv_rs => open,
        adv_wb => open,
        adv_rob => open,

        rs_full => CT_rs_full,
        rs_almost_full => CT_rs_almost_full,

        flush_out => CT_flush_out,
        stall_out => CT_stall_out
    );
END ARCHITECTURE;