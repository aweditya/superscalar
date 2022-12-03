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
        -- Will need to add more inputs to handle forwarding logic

        -- OUTPUTS
        wr_inst1, wr_inst2: out std_logic; -- write bits for newly decoded instructions 
        wr_ALU1, wr_ALU2: out std_logic; -- write bits for newly executed instructions
        rd_ALU1, rd_ALU2: out std_logic;  -- read bits for issuing ready instructions
		control_inst1, control_inst2: out std_logic_vector(5 downto 0); -- control values for the two instructions
        pc_inst1, pc_inst2: out std_logic_vector(15 downto 0); -- pc values for the two instructions
        opr1_inst1, opr2_inst1, opr1_inst2, opr2_inst2: in std_logic_vector(15 downto 0); -- operand values for the two instructions
        imm6_inst1, imm6_inst2: in std_logic_vector(5 downto 0); -- imm6 values for the two instructions
        c_inst1, z_inst1, c_inst2, z_inst2: in std_logic_vector(7 downto 0); -- carry and zero values for the two instructions
        valid1_inst1, valid2_inst1, valid3_inst1, valid4_inst1: in std_logic; -- valid bits for first instruction
        valid1_inst2, valid2_inst2, valid3_inst2, valid4_inst2: in std_logic; -- valid bits for second instruction
        data_ALU1, data_ALU2: in std_logic_vector(15 downto 0); -- data forwarded from the execution pipelines
        rr1_ALU1, rr1_ALU2, rr2_ALU1, rr2_ALU2, rr3_ALU1, rr3_ALU2: out std_logic_vector(7 downto 0); -- rr values coming from the ROB corresponding to execution pipeline outputs
        c_ALU1_in, z_ALU1_in, c_ALU2_in, z_ALU2_in: in std_logic; -- carry and zero values forwarded from the execution pipelines
        finished_ALU1, finished_ALU2: std_logic -- finished bits coming from the execution pipelines
    );
end entity IDStage;

architecture behavioural of IDStage is
    component DataRegisterFile is 
        port(
            clk, clr, wr_1, wr_2, complete: in std_logic;
            reg_select_1, reg_select_2, reg_select_3, reg_select_4, dest: in std_logic_vector(4 downto 0);
            tag_1, tag_2, tag_3, tag_4: in std_logic_vector(7 downto 0);
            data_alu_1, data_alu_2: in std_logic_vector(15 downto 0);
            rr_alu_1, rr_alu_2: in std_logic_vector(7 downto 0);
            finish_alu_1, finish_alu_2: in std_logic;

            data_out_1, data_out_2, data_out_3, data_out_4: out std_logic_vector(15 downto 0);
            data_tag_1, data_tag_2, data_tag_3, data_tag_4: out std_logic
        );
    end component;

    component FlagRegisterFile is 
        port(
            clk, clr, wr_1, wr_2, complete: in std_logic;
            reg_select_1, reg_select_2, dest: in std_logic_vector(1 downto 0);
            tag_1, tag_2: in std_logic_vector(7 downto 0);
            data_alu_1, data_alu_2: in std_logic_vector(7 downto 0);
            rr_alu_1, rr_alu_2: in std_logic_vector(7 downto 0);
            finish_alu_1, finish_alu_2: in std_logic;

            data_out_1, data_out_2: out std_logic_vector(7 downto 0);
            data_tag_1, data_tag_2: out std_logic
        );
    end component;
    
    component OperandExtractor is
        port(
            instruction: std_logic_vector(15 downto 0);

            operand1, operand2: std_logic_vector(4 downto 0);
            destination: std_logic_vector(4 downto 0)
        );
    end component;

    signal wr_inst1_sig, wr_inst2_sig: std_logic := '1';
    signal wr_ALU1_sig, wr_ALU2_sig: std_logic := '1';

    signal opr_addr1_inst1, opr_addr2_inst1, opr_addr1_inst2, opr_addr2_inst2: std_logic_vector(4 downto 0) := (others => '0');
    signal dest_addr_inst1, dest_addr_inst2: std_logic_vector(4 downto 0) := (others => '0'); 

begin
    -- Control logic for wr_inst1, wr_inst2 (if the RS is full, we cannot write into it). For the time being,
    -- we assume that the RS is large enough so no capacity stalls occur
    instruction_write_control_process: process(wr_inst1_sig, wr_inst2_sig)
    begin
        wr_inst1_sig <= '1';
        wr_inst2_sig <= '1';
    end process instruction_write_control_process;

    wr_inst1 <= wr_inst1_sig;
    wr_inst2 <= wr_inst2_sig;
    --

    -- TODO 
    alu_write_control_process: process(wr_ALU1_sig, wr_ALU2_sig)
    begin

    end process alu_write_control_process;

    wr_ALU1 <= wr_ALU1_sig;
    wr_ALU2 <= wr_ALU2_sig;
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
    imm6_inst1 <= IFID_IMem_Op(21 downto 16);
    imm6_inst2 <= IFID_IMem_Op(5 downto 0);
    -- 

    inst1_operands: OperandExtractor
        port map(
            instruction => IFID_PC_Op,

            operand1 => opr_addr1_inst1,
            operand2 => opr_addr2_inst1,
            destination => dest_addr_inst1
        );

    inst2_operands: OperandExtractor
        port map(
            instruction => IFID_inc_Op,

            operand1 => opr_addr1_inst2,
            operand2 => opr_addr2_inst2,
            destination => dest_addr_inst2
        );

    data_register_file: DataRegisterFile
        generic map(
            arf_bit_size := 5,
            rrf_bit_size := 8,
            data_size := 16
        )
        port map(
            clk => clk,
            clr => clr,

            wr_1 =>,
            wr_2 =>,
            complete =>,

            reg_select_1 => opr_addr1_inst1,
            reg_select_2 => opr_addr2_inst1,
            reg_select_3 => opr_addr1_inst2,
            reg_select_4 => opr_addr2_inst2,

            tag_1 =>,
            tag_2 =>,
            tag_3 =>,
            tag_4 =>,

            data_alu_1 =>,
            data_alu_2 =>,

            rr_alu_1 =>,
            rr_alu_2 =>,

            finish_alu_1 =>,
            finish_alu_2 =>,

            data_out_1 => opr1_inst1,
            data_out_2 => opr2_inst1,
            data_out_3 => opr1_inst2,
            data_out_4 => opr2_inst2,

            data_tag_1 => valid1_inst1,
            data_tag_2 => valid2_inst1,
            data_tag_3 => valid1_inst2,
            data_tag_4 => valid2_inst2
        );

    carry_register_file: FlagRegisterFile
        generic map(
            arf_bit_size := 2,
            rrf_bit_size := 8,
            data_size := 8
        )
        port map(
            clk => clk,
            clr => clr,

            wr_1 =>,
            wr_2 =>,
            complete =>,

            reg_select_1 =>,
            reg_select_2 =>,
            
            tag_1 =>,
            tag_2 =>,
            
            data_alu_1 =>,
            data_alu_2 =>,

            rr_alu_1 =>,
            rr_alu_2 =>,

            finish_alu_1 =>,
            finish_alu_2 =>,

            data_out_1 => c_inst1,
            data_out_2 => c_inst2,

            data_tag_1 => valid3_inst1,
            data_tag_2 => valid3_inst2
        );

    zero_register_file: FlagRegisterFile
        generic map(
            arf_bit_size := 2,
            rrf_bit_size := 8,
            data_size := 8
        )
        port map(
            clk => clk,
            clr => clr,

            wr_1 =>,
            wr_2 =>,
            complete =>,

            reg_select_1 =>,
            reg_select_2 =>,

            tag_1 =>,
            tag_2 =>,

            data_alu_1 =>,
            data_alu_2 =>,

            rr_alu_1 =>,
            rr_alu_2 =>,

            finish_alu_1 =>,
            finish_alu_2 =>,

            data_out_1 => z_inst1,
            data_out_2 => z_inst2,

            data_tag_1 => valid4_inst1,
            data_tag_2 => valid4_inst2
        );
end architecture behavioural;