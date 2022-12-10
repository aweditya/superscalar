library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IDStage is
    port(
        -- INPUTS
        clr: in std_logic;
        clk: in std_logic;

        IFID_inc_Op, IFID_PC_Op: in std_logic_vector(15 downto 0);
        IFID_IMem_Op: in std_logic_vector(31 downto 0);
        
        -- ALU execution pipeline fowarding
        finish_alu_pipe1, finish_alu_pipe2: in std_logic;
        data_rr_alu_1, data_rr_alu_2: in std_logic_vector(7 downto 0);
        data_result_alu_1, data_result_alu_2: in std_logic_vector(15 downto 0);
        carry_rr_alu_1, carry_rr_alu_2: in std_logic_vector(7 downto 0);
        carry_result_alu_1, carry_result_alu_2: in std_logic_vector(0 downto 0);
        zero_rr_alu_1, zero_rr_alu_2: in std_logic_vector(7 downto 0);
        zero_result_alu_1, zero_result_alu_2: in std_logic_vector(0 downto 0);

        -- LHI execution pipeline forwarding
        finish_lhi: in std_logic;
        data_rr_lhi: in std_logic_vector(7 downto 0);
        data_result_lhi: in std_logic_vector(15 downto 0);

        inst_complete_exec: in std_logic;
        inst_complete_exec_dest: in std_logic_vector(2 downto 0);

        -- For handing RS capacity stalls,
        -- rs_almost_full indicates if the RS has just one entry left
        -- rs_full indicates if the RS has no entries left
        rs_almost_full, rs_full: in std_logic;

        -- OUTPUTS
        wr_inst1, wr_inst2: out std_logic; -- write bits for newly decoded instructions 
        control_inst1, control_inst2: out std_logic_vector(5 downto 0); -- control values for the two instructions
        pc_inst1, pc_inst2: out std_logic_vector(15 downto 0); -- pc values for the two instructions
        opr1_inst1, opr2_inst1, opr1_inst2, opr2_inst2: out std_logic_vector(15 downto 0); -- operand values for the two instructions
        imm9_inst1, imm9_inst2: out std_logic_vector(8 downto 0); -- imm9 values for the two instructions
        c_inst1, z_inst1, c_inst2, z_inst2: out std_logic_vector(7 downto 0); -- carry and zero values for the two instructions
        valid1_inst1, valid2_inst1, valid3_inst1, valid4_inst1: out std_logic; -- valid bits for first instruction
        valid1_inst2, valid2_inst2, valid3_inst2, valid4_inst2: out std_logic; -- valid bits for second instruction
        dest_inst1, dest_inst2: out std_logic_vector(2 downto 0);
        rr1_inst1, rr1_inst2: out std_logic_vector(7 downto 0); -- RR1 for newly decoded instructions
        rr2_inst1, rr2_inst2: out std_logic_vector(7 downto 0); -- RR2 for newly decoded instructions
        rr3_inst1, rr3_inst2: out std_logic_vector(7 downto 0) -- RR3 for newly decoded instructions
    );
end entity IDStage;

architecture behavioural of IDStage is
    component DataRegisterFile is 
        port(
            clk, clr: in std_logic;
            source_select_1, source_select_2, source_select_3, source_select_4: in std_logic_vector(2 downto 0);

            -- Newly decoded instructions
            wr1, wr2: in std_logic;
            dest_select_1, dest_select_2: in std_logic_vector(2 downto 0);
            tag_1, tag_2: in std_logic_vector(7 downto 0);

            -- ALU execution pipeline forwarding for data
            finish_alu_1, finish_alu_2: in std_logic;
            rr_alu_1, rr_alu_2: in std_logic_vector(7 downto 0);
            data_alu_1, data_alu_2: in std_logic_vector(15 downto 0);

            -- LHI execution pipeline forwarding for data
            finish_lhi: in std_logic;
            rr_lhi: in std_logic_vector(7 downto 0);
            data_lhi: in std_logic_vector(15 downto 0);

            -- Instruction retirement
            complete: in std_logic;
            inst_complete_dest: in std_logic_vector(2 downto 0);

            data_out_1, data_out_2, data_out_3, data_out_4: out std_logic_vector(15 downto 0);
            data_tag_1, data_tag_2, data_tag_3, data_tag_4: out std_logic;

            rrf_busy_out: out std_logic_vector((integer'(2)**8)-1 downto 0)
        );
    end component;

    component FlagRegisterFile is 
        port(
            clk, clr: in std_logic;

            wr1, wr2: in std_logic;
            tag_1, tag_2: in std_logic_vector(7 downto 0);

            finish_alu_1, finish_alu_2: in std_logic;
            rr_alu_1, rr_alu_2: in std_logic_vector(7 downto 0);
            data_alu_1, data_alu_2: in std_logic_vector(0 downto 0);

            complete: in std_logic;

            data_out_1, data_out_2: out std_logic_vector(7 downto 0);
            data_tag_1, data_tag_2: out std_logic;

            rrf_busy_out: out std_logic_vector((integer'(2)**8)-1 downto 0)
        );
    end component;

    component DualPriorityEncoder is
        generic (
            input_width : integer := 2 ** 8;
            output_width : integer := 8
        );
        port (
            a: in std_logic_vector(input_width - 1 downto 0);
            y_first: out std_logic_vector(output_width - 1 downto 0);
            valid_first: out std_logic;
            y_second: out std_logic_vector(output_width - 1 downto 0);
            valid_second: out std_logic
        );
    end component;
    
    component OperandExtractor is
        port(
            instruction: in std_logic_vector(15 downto 0);

            operand1, operand2: out std_logic_vector(2 downto 0);
            destination: out std_logic_vector(2 downto 0)
        );
    end component;

    component DestinationWriteChecker is
        port(
            instruction: in std_logic_vector(15 downto 0);
            dest_write: out std_logic
        );
    end component;

    component CarryWriteChecker is
        port(
            instruction: in std_logic_vector(15 downto 0);
            carry_write: out std_logic
        );
    end component;

    component ZeroWriteChecker is
        port(
            instruction: in std_logic_vector(15 downto 0);
            zero_write: out std_logic
        );
    end component;

    signal wr_inst1_sig, wr_inst2_sig: std_logic := '1';

    signal opr_addr1_inst1, opr_addr2_inst1, opr_addr1_inst2, opr_addr2_inst2: std_logic_vector(2 downto 0) := (others => '0');
    signal dest_addr_inst1, dest_addr_inst2: std_logic_vector(2 downto 0) := (others => '0'); 

    signal data_rrf_busy, carry_rrf_busy, zero_rrf_busy: std_logic_vector((integer'(2)**8)-1 downto 0) := (others => '0');

    -- Signals _rf_full_first, _rf_full_second can be used to check if the corresponding RF have space
    signal data_rr_tag_inst1, data_rr_tag_inst2: std_logic_vector(7 downto 0) := (others => '0');
    signal data_rf_full_first, data_rf_full_second: std_logic;

    signal carry_rr_tag_inst1, carry_rr_tag_inst2: std_logic_vector(7 downto 0) := (others => '0');
    signal carry_rf_full_first, carry_rf_full_second: std_logic;

    signal zero_rr_tag_inst1, zero_rr_tag_inst2: std_logic_vector(7 downto 0) := (others => '0');
    signal zero_rf_full_first, zero_rf_full_second: std_logic;

    signal data_reg_wr1, data_reg_wr2: std_logic;
    signal carry_reg_wr1, carry_reg_wr2: std_logic;
    signal zero_reg_wr1, zero_reg_wr2: std_logic;

begin
    -- Control logic for wr_inst1, wr_inst2 (if the RS or register files are full, we cannot write into it)
    instruction_write_control_process: process(rs_full, rs_almost_full, data_reg_wr1, data_rf_full_first, data_reg_wr2, data_rf_full_second, carry_reg_wr1, carry_rf_full_first, carry_reg_wr2, carry_rf_full_second, zero_reg_wr1, zero_rf_full_first, zero_reg_wr2, zero_rf_full_second)
        variable write_inst1, write_inst2 : std_logic := '1';
    begin
        if (rs_full = '1') then
            -- No space in RS
            write_inst1 := '0';
            write_inst2 := '0';

        elsif (rs_almost_full = '1') then
            -- One space left in RS so turn off write for instruction 2, check write for instruction 1
            if (data_reg_wr1 = '1' and data_rf_full_first = '0') then
                write_inst1 := '0';
				else
				    write_inst1 := '1';
            end if;
    
            if (carry_reg_wr1 = '1' and carry_rf_full_first = '0') then
                write_inst1 := '0';
				else
				    write_inst1 := '1';
            end if;
    
            if (zero_reg_wr1 = '1' and zero_rf_full_first = '0') then
                write_inst1 := '0';
				else
				    write_inst1 := '1';
            end if;

            write_inst2 := '0';
        else
            -- More than two entries in the RS. Check write for each instruction
            if (data_reg_wr1 = '1' and data_rf_full_first = '0') then
                write_inst1 := '0';
				else
				    write_inst1 := '1';
            end if;
    
            if (carry_reg_wr1 = '1' and carry_rf_full_first = '0') then
                write_inst1 := '0';
				else
				    write_inst1 := '1';
            end if;
    
            if (zero_reg_wr1 = '1' and zero_rf_full_first = '0') then
                write_inst1 := '0';
				else
				    write_inst1 := '1';
            end if;

            if (data_reg_wr2 = '1' and data_rf_full_second = '0') then
                write_inst2 := '0';
				else
				    write_inst2 := '1';
            end if;
    
            if (carry_reg_wr2 = '1' and carry_rf_full_second = '0') then
                write_inst2 := '0';
				else
				    write_inst2 := '1';
            end if;
    
            if (zero_reg_wr2 = '1' and zero_rf_full_second = '0') then
                write_inst2 := '0';
				else
				    write_inst2 := '1';
            end if;
        end if;
        
        wr_inst1_sig <= write_inst1;
        wr_inst2_sig <= write_inst2;
    end process instruction_write_control_process;

    wr_inst1 <= wr_inst1_sig;
    wr_inst2 <= wr_inst2_sig;
    --

    -- Opcode + last two bits for each instruction
    control_inst1 <= IFID_IMem_Op(31 downto 28) & IFID_IMem_Op(17 downto 16);
    control_inst2 <= IFID_IMem_Op(15 downto 12) & IFID_IMem_Op(1 downto 0);
    -- 

    -- PC for both instructions
    pc_inst1 <= IFID_PC_Op;
    pc_inst2 <= IFID_inc_Op;
    --

    -- Immediate data field
    imm9_inst1 <= IFID_IMem_Op(24 downto 16);
    imm9_inst2 <= IFID_IMem_Op(8 downto 0);
    -- 

    inst1_operands: OperandExtractor
        port map(
            instruction => IFID_IMem_Op(31 downto 16),

            operand1 => opr_addr1_inst1,
            operand2 => opr_addr2_inst1,
            destination => dest_addr_inst1
        );

    dest_inst1 <= dest_addr_inst1;


    inst2_operands: OperandExtractor
        port map(
            instruction => IFID_IMem_Op(15 downto 0),

            operand1 => opr_addr1_inst2,
            operand2 => opr_addr2_inst2,
            destination => dest_addr_inst2
        );

    dest_inst2 <= dest_addr_inst2;

    data_priority_encoder: DualPriorityEncoder
        generic map (
            input_width => 2 ** 8,
            output_width => 8
        )
        port map(
            a => data_rrf_busy,
            y_first => data_rr_tag_inst1,
            valid_first => data_rf_full_first,
            y_second => data_rr_tag_inst2,
            valid_second => data_rf_full_second
        );

    rr1_inst1 <= data_rr_tag_inst1;
    rr1_inst2 <= data_rr_tag_inst2;

    dest_write_checker_inst1: DestinationWriteChecker
        port map(
            instruction => IFID_IMem_Op(31 downto 16),
            dest_write => data_reg_wr1
        );
    
    dest_write_checker_inst2: DestinationWriteChecker
        port map(
            instruction => IFID_IMem_Op(15 downto 0),
            dest_write => data_reg_wr2
        );

    data_register_file: DataRegisterFile
        port map(
            clk => clk,
            clr => clr,

            source_select_1 => opr_addr1_inst1,
            source_select_2 => opr_addr2_inst1,
            source_select_3 => opr_addr1_inst2,
            source_select_4 => opr_addr2_inst2,

            wr1 => data_reg_wr1, 
            wr2 => data_reg_wr2,
            dest_select_1 => dest_addr_inst1,
            dest_select_2 => dest_addr_inst2,
            tag_1 => data_rr_tag_inst1, 
            tag_2 => data_rr_tag_inst2,

            finish_alu_1 => finish_alu_pipe1, 
            finish_alu_2 => finish_alu_pipe2,
            rr_alu_1 => data_rr_alu_1, 
            rr_alu_2 => data_rr_alu_2,
            data_alu_1 => data_result_alu_1, 
            data_alu_2 => data_result_alu_2,

            finish_lhi => finish_lhi,
            rr_lhi => data_rr_lhi,
            data_lhi => data_result_lhi,

            complete => inst_complete_exec,
            inst_complete_dest => inst_complete_exec_dest,

            data_out_1 => opr1_inst1,
            data_out_2 => opr2_inst1,
            data_out_3 => opr1_inst2,
            data_out_4 => opr2_inst2,

            data_tag_1 => valid1_inst1,
            data_tag_2 => valid2_inst1,
            data_tag_3 => valid1_inst2,
            data_tag_4 => valid2_inst2,

            rrf_busy_out => data_rrf_busy
        );

    carry_priority_encoder: DualPriorityEncoder
        generic map (
            input_width => 2 ** 8,
            output_width => 8
        )
        port map(
            a => carry_rrf_busy,
            y_first => carry_rr_tag_inst1,
            valid_first => carry_rf_full_first,
            y_second => carry_rr_tag_inst2,
            valid_second => carry_rf_full_second
        );

    rr2_inst1 <= carry_rr_tag_inst1;
    rr2_inst2 <= carry_rr_tag_inst2;

    carry_write_checker_inst1: CarryWriteChecker
        port map(
            instruction => IFID_IMem_Op(31 downto 16),
            carry_write => carry_reg_wr1
        );

    carry_write_checker_inst2: CarryWriteChecker
        port map(
            instruction => IFID_IMem_Op(15 downto 0),
            carry_write => carry_reg_wr2
        );

    carry_register_file: FlagRegisterFile
        port map(
            clk => clk, 
            clr => clr,

            wr1 => carry_reg_wr1, 
            wr2 => carry_reg_wr2,
            tag_1 => carry_rr_tag_inst1,
            tag_2 => carry_rr_tag_inst2,

            finish_alu_1 => finish_alu_pipe1,
            finish_alu_2 => finish_alu_pipe2,
            rr_alu_1 => carry_rr_alu_1, 
            rr_alu_2 => carry_rr_alu_2,
            data_alu_1 => carry_result_alu_1,
            data_alu_2 => carry_result_alu_2,

            complete => inst_complete_exec, 

            data_out_1 => c_inst1, 
            data_out_2 => c_inst2,
            
            data_tag_1 => valid3_inst1, 
            data_tag_2 => valid3_inst2,

            rrf_busy_out => carry_rrf_busy
        );

    zero_priority_encoder: DualPriorityEncoder
        generic map (
            input_width => 2 ** 8,
            output_width => 8
        )
        port map(
            a => zero_rrf_busy,
            y_first => zero_rr_tag_inst1,
            valid_first => zero_rf_full_first,
            y_second => zero_rr_tag_inst2,
            valid_second => zero_rf_full_second
        );
    
    rr3_inst1 <= zero_rr_tag_inst1;
    rr3_inst2 <= zero_rr_tag_inst2;

    zero_write_checker_inst1: ZeroWriteChecker
        port map(
            instruction => IFID_IMem_Op(31 downto 16),
            zero_write => zero_reg_wr1
        );

    zero_write_checker_inst2: ZeroWriteChecker
        port map(
            instruction => IFID_IMem_Op(15 downto 0),
            zero_write => zero_reg_wr2
        );

    zero_register_file: FlagRegisterFile
        port map(
            clk => clk, 
            clr => clr,

            wr1 => zero_reg_wr1, 
            wr2 => zero_reg_wr2,
            tag_1 => zero_rr_tag_inst1,
            tag_2 => zero_rr_tag_inst2,

            finish_alu_1 => finish_alu_pipe1,
            finish_alu_2 => finish_alu_pipe2,
            rr_alu_1 => zero_rr_alu_1, 
            rr_alu_2 => zero_rr_alu_2,
            data_alu_1 => zero_result_alu_1,
            data_alu_2 => zero_result_alu_2,

            complete => inst_complete_exec,

            data_out_1 => z_inst1, 
            data_out_2 => z_inst2,
            
            data_tag_1 => valid4_inst1, 
            data_tag_2 => valid4_inst2,

            rrf_busy_out => zero_rrf_busy
        );

end architecture behavioural;