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
		control_inst1, control_inst2: in std_logic_vector(5 downto 0); -- control values for the two instructions
        pc_inst1, pc_inst2: in std_logic_vector(15 downto 0); -- pc values for the two instructions
        opr1_inst1, opr2_inst1, opr1_inst2, opr2_inst2: in std_logic_vector(15 downto 0); -- operand values for the two instructions
        imm9_inst1, imm9_inst2: in std_logic_vector(8 downto 0); -- imm6 values for the two instructions
        c_inst1, z_inst1, c_inst2, z_inst2: in std_logic_vector(7 downto 0); -- carry and zero values for the two instructions
        valid1_inst1, valid2_inst1, valid3_inst1, valid4_inst1: in std_logic; -- valid bits for first instruction
        valid1_inst2, valid2_inst2, valid3_inst2, valid4_inst2: in std_logic; -- valid bits for second instruction

        -- ALU execution pipeline forwarding for data, carry and zero
        --wr_ALU1, wr_ALU2: in std_logic; -- write bits for newly executed instructions
        rd_ALU1, rd_ALU2: in std_logic;  -- read bits for issuing ready instructions
        data_ALU1, data_ALU2: in std_logic_vector(15 downto 0);
        rr1_ALU1, rr1_ALU2: in std_logic_vector(7 downto 0);
        c_ALU1_in, c_ALU2_in: in std_logic;
        rr2_ALU1, rr2_ALU2: in std_logic_vector(7 downto 0);
        z_ALU1_in, z_ALU2_in: in std_logic;
        rr3_ALU1, rr3_ALU2: in std_logic_vector(7 downto 0);
        finished_ALU1, finished_ALU2: std_logic;

        -- LHI execution pipeline forwarding for data
        rd_LHI: in std_logic;
        data_LHI: in std_logic_vector(15 downto 0);
        rr_LHI: in std_logic_vector(7 downto 0);
        finished_LHI: std_logic;

        -- OUTPUTS
        -- ALU execution pipeline
        pc_ALU1, pc_ALU2: out std_logic_vector(15 downto 0); -- PC values forwarded to each execution pipeline
        control_ALU1, control_ALU2: out std_logic_vector(5 downto 0); -- control to go to the control generator for the ALU pipelines
        ra_ALU1, rb_ALU1, ra_ALU2, rb_ALU2: out std_logic_vector(15 downto 0); -- operand values forwarded to each execution pipeline
        imm6_ALU1, imm6_ALU2: out std_logic_vector(5 downto 0); -- imm6 values forwarded to each execution pipeline
        c_ALU1_out, z_ALU1_out, c_ALU2_out, z_ALU2_out: out std_logic; -- carry and zero values forwarded to each execution pipeline
        finished_ALU1_out, finished_ALU2_out: out std_logic; -- instruction has been scheduled to the pipeline

        -- LHI execution pipeline
        pc_LHI: out std_logic_vector(15 downto 0); -- PC value
        imm9_LHI: out std_logic_vector(8 downto 0); -- imm9 value
        finished_LHI_out: out std_logic; -- instruction has been scheduled to the pipeline

        -- RS status bits
        almost_full_out, full_out, empty_out: out std_logic -- full and empty bits for the RS
	);
end rs;

architecture behavioural of rs is
    -- defining the types required for different-sized columns
    type rs_type_4 is array(size-1 downto 0) of std_logic_vector(3 downto 0);
    type rs_type_6 is array(size-1 downto 0) of std_logic_vector(5 downto 0);
    type rs_type_8 is array(size-1 downto 0) of std_logic_vector(7 downto 0);
    type rs_type_9 is array(size-1 downto 0) of std_logic_vector(8 downto 0);
    type rs_type_16 is array(size-1 downto 0) of std_logic_vector(15 downto 0);

    -- defining the required columns, each with (size) entries
    signal rs_control: rs_type_6:= (others => (others => '0'));
    signal rs_pc: rs_type_16:= (others => (others => '0'));
    signal rs_opr1: rs_type_16:= (others => (others => '0'));
    signal rs_opr2: rs_type_16:= (others => (others => '0'));
    signal rs_imm_9: rs_type_9:= (others => (others => '0'));
    signal rs_c: rs_type_8:= (others => (others => '0'));
    signal rs_z: rs_type_8:= (others => (others => '0'));
    
    signal rs_v1, rs_v2, rs_v3, rs_v4: std_logic_vector(size - 1 downto 0) := (others => '0');
    signal rs_ready, rs_issued: std_logic_vector(size - 1 downto 0) := (others => '0');

    signal count: integer range 0 to size := 0;
    signal almost_full: std_logic;
    signal full: std_logic;
    signal empty: std_logic;

    signal finished_ALU1_sig, finished_ALU2_sig: std_logic;
    signal finished_LHI_sig: std_logic;

    component DualPriorityEncoderActiveHigh is
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

    signal first_free_entry, second_free_entry: std_logic_vector(7 downto 0) := (others => '0');
    signal valid_first_sig, valid_second_sig: std_logic := '0';

    -- ALU pipeline scheduling signals
    signal is_alu_instruction: std_logic_vector(size-1 downto 0) := (others => '0');
    signal ready_for_alu_pipeline: std_logic_vector(size-1 downto 0) := (others => '0');
    signal first_ready_alu_inst, second_ready_alu_inst: std_logic_vector(7 downto 0) := (others => '0');
    signal issue_valid_alu_first_sig, issue_valid_alu_second_sig: std_logic := '0';


    component PriorityEncoderActiveHigh is
        generic (
            input_width : integer := 2 ** 8;
            output_width : integer := 8 
        );
        port (
            a: in std_logic_vector(input_width - 1 downto 0);
            y: out std_logic_vector(output_width - 1 downto 0);
            all_zeros: out std_logic
        );
    end component;

    -- LHI pipeline scheduling signals
    signal is_lhi_instruction: std_logic_vector(size-1 downto 0) := (others => '0');
    signal ready_for_lhi_pipeline: std_logic_vector(size-1 downto 0) := (others => '0');
    signal ready_lhi_inst: std_logic_vector(7 downto 0) := (others => '0');
    signal issue_valid_lhi_sig: std_logic := '0';

begin
    allocate_unit: DualPriorityEncoderActiveHigh
        generic map(
            input_width => 2 ** 8,
            output_width => 8
        )
        port map(
            a => rs_issued,
            y_first => first_free_entry,
            valid_first => valid_first_sig,
            y_second => second_free_entry,
            valid_second => valid_second_sig
        );

    -- ALU scheduling
    check_if_alu_instruction: process(rs_control)
    begin
        for i in 0 to size -1 loop
            if (rs_control(i)(5 downto 2) = "0001" or rs_control(i)(5 downto 2) = "0010" or rs_control(i)(5 downto 2) = "0000") then
                is_alu_instruction(i) <= '1';
            else
                is_alu_instruction(i) <= '0';
            end if;
        end loop;
    end process check_if_alu_instruction;

    is_ready_for_alu_pipeline: process(is_alu_instruction, rs_ready, rs_issued)
    begin
        ready_for_alu_pipeline <= is_alu_instruction and rs_ready and (not rs_issued);
    end process is_ready_for_alu_pipeline;

    alu_issuing_unit: DualPriorityEncoderActiveHigh
        generic map(
            input_width => 2 ** 8,
            output_width => 8
        )
        port map(
            a => ready_for_alu_pipeline,
            y_first => first_ready_alu_inst,
            valid_first => issue_valid_alu_first_sig,
            y_second => second_ready_alu_inst,
            valid_second => issue_valid_alu_second_sig
        );

    -- LHI scheduling
    check_if_lhi_instruction: process(rs_control)
    begin
        for i in 0 to size -1 loop
            if (rs_control(i)(5 downto 2) = "0011") then
                is_lhi_instruction(i) <= '1';
            else
                is_lhi_instruction(i) <= '0';
            end if;
        end loop;
    end process check_if_lhi_instruction;

    is_ready_for_lhi_pipeline: process(is_lhi_instruction, rs_ready, rs_issued)
    begin
        ready_for_lhi_pipeline <= is_lhi_instruction and rs_ready and (not rs_issued);
    end process is_ready_for_lhi_pipeline;

    lhi_issuing_unit: PriorityEncoderActiveHigh
        generic map(
            input_width => 2 ** 8,
            output_width => 8
        )
        port map(
            a => ready_for_lhi_pipeline,
            y => ready_lhi_inst,
            all_zeros => issue_valid_lhi_sig
        );

    rs_operation: process(clr, clk)
        variable instruction_count: integer range 0 to size := 0;

    begin
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
            rs_issued <= (others => '1');

            -- ALU signal initialisation
            pc_ALU1 <= (others => '0');
            ra_ALU1 <= (others => '0');
            rb_ALU1 <= (others => '0');
            imm6_ALU1 <= (others => '0');
            c_ALU1_out <= '0';
            z_ALU1_out <= '0'; 
            control_ALU1 <= (others => '0');
            finished_ALU1_sig <= '0';

            pc_ALU2 <= (others => '0');
            ra_ALU2 <= (others => '0');
            rb_ALU2 <= (others => '0');
            imm6_ALU2 <= (others => '0');
            c_ALU2_out <= '0';
            z_ALU2_out <= '0'; 
            control_ALU2 <= (others => '0');
            finished_ALU2_sig <= '0';

            -- LHI signal initialisation
            pc_LHI <= (others => '0');
            imm9_LHI <= (others => '0');
            finished_LHI_sig <= '0';
            
            instruction_count := 0;

        else
            if (rising_edge(clk)) then
                -- Write the first instruction to it at the clock edge
                if (wr_inst1 = '1') then
                    rs_control(to_integer(unsigned(first_free_entry))) <= control_inst1;
                    rs_pc(to_integer(unsigned(first_free_entry))) <= pc_inst1;
                    rs_opr1(to_integer(unsigned(first_free_entry))) <= opr1_inst1;
                    rs_v1(to_integer(unsigned(first_free_entry))) <= valid1_inst1;
                    rs_opr2(to_integer(unsigned(first_free_entry))) <= opr2_inst1;
                    rs_v2(to_integer(unsigned(first_free_entry))) <= valid2_inst1;
                    rs_imm_9(to_integer(unsigned(first_free_entry))) <= imm9_inst1;
                    rs_c(to_integer(unsigned(first_free_entry))) <= c_inst1;
                    rs_v3(to_integer(unsigned(first_free_entry))) <= valid3_inst1;
                    rs_z(to_integer(unsigned(first_free_entry))) <= z_inst1;
                    rs_v4(to_integer(unsigned(first_free_entry))) <= valid4_inst1;
                    rs_issued(to_integer(unsigned(first_free_entry))) <= '0';

                    instruction_count := instruction_count + 1;
                end if;

                -- Write the second instruction to it at the clock edge
                if (wr_inst2 = '1') then
                    rs_control(to_integer(unsigned(second_free_entry))) <= control_inst2;
                    rs_pc(to_integer(unsigned(second_free_entry))) <= pc_inst2;
                    rs_opr1(to_integer(unsigned(second_free_entry))) <= opr1_inst2;
                    rs_v1(to_integer(unsigned(second_free_entry))) <= valid1_inst2;
                    rs_opr2(to_integer(unsigned(second_free_entry))) <= opr2_inst2;
                    rs_v2(to_integer(unsigned(second_free_entry))) <= valid2_inst2;
                    rs_imm_9(to_integer(unsigned(second_free_entry))) <= imm9_inst2;
                    rs_c(to_integer(unsigned(second_free_entry))) <= c_inst2;
                    rs_v3(to_integer(unsigned(second_free_entry))) <= valid3_inst2;
                    rs_z(to_integer(unsigned(second_free_entry))) <= z_inst2;
                    rs_v4(to_integer(unsigned(second_free_entry))) <= valid4_inst2;
                    rs_issued(to_integer(unsigned(second_free_entry))) <= '0';

                    instruction_count := instruction_count + 1;
                end if;

                for i in 0 to size - 1 loop
                    -- Updating operands received from ALU execution pipeline
                    -- Update operand 1
                    if (rs_v1(i) = '0' and rs_opr1(i)(7 downto 0) = rr1_ALU1 and finished_ALU1 = '1') then
                        rs_opr1(i) <= data_ALU1;
                        rs_v1(i) <= '1';
                    end if;

                    if (rs_v1(i) = '0' and rs_opr1(i)(7 downto 0) = rr1_ALU2 and finished_ALU2 = '1') then
                        rs_opr1(i) <= data_ALU2;
                        rs_v1(i) <= '1';
                    end if;

                    -- Update operand 2
                    if (rs_v2(i) = '0' and rs_opr2(i)(7 downto 0) = rr1_ALU1 and finished_ALU1 = '1') then
                        rs_opr2(i) <= data_ALU1;
                        rs_v2(i) <= '1';
                    end if;
    
                    if (rs_v2(i) = '0' and rs_opr2(i)(7 downto 0) = rr1_ALU2 and finished_ALU2 = '1') then
                        rs_opr2(i) <= data_ALU2;
                        rs_v2(i) <= '1';
                    end if;

                    -- Update carry flag
                    if (rs_v3(i) = '0' and rs_c(i) = rr2_ALU1 and finished_ALU1 = '1') then
                        rs_c(i) <= "0000000" & c_ALU1_in;
                        rs_v3(i) <= '1';
                    end if;

                    if (rs_v3(i) = '0' and rs_c(i) = rr2_ALU2 and finished_ALU2 = '1') then
                        rs_c(i) <= "0000000" & c_ALU2_in;
                        rs_v3(i) <= '1';
                    end if;

                    -- Update zero flag
                    if (rs_v4(i) = '0' and rs_z(i) = rr3_ALU1 and finished_ALU1 = '1') then
                        rs_z(i) <= "0000000" & z_ALU1_in;
                        rs_v4(i) <= '1';
                    end if;
    
                    if (rs_v4(i) = '0' and rs_z(i) = rr3_ALU2 and finished_ALU2 = '1') then
                        rs_z(i) <= "0000000" & z_ALU2_in;
                        rs_v4(i) <= '1';
                    end if;

                    -- Updating operands received from LHI execution pipeline
                    -- Update operand 1
                    if (rs_v1(i) = '0' and rs_opr1(i)(7 downto 0) = rr_LHI and finished_LHI = '1') then
                        rs_opr1(i) <= data_LHI;
                        rs_v1(i) <= '1';
                    end if;

                    -- Update operand 2
                    if (rs_v2(i) = '0' and rs_opr2(i)(7 downto 0) = rr_LHI and finished_LHI = '1') then
                        rs_opr2(i) <= data_LHI;
                        rs_v2(i) <= '1';
                    end if;
                end loop;

                -- ALU scheduling
                -- Finding a ready entry and forwarding it to ALU pipeline-1
                if (rd_ALU1 = '1' and rs_issued(to_integer(unsigned(first_ready_alu_inst))) = '0' and issue_valid_alu_first_sig = '0') then
                    pc_ALU1 <= rs_pc(to_integer(unsigned(first_ready_alu_inst)));
                    ra_ALU1 <= rs_opr1(to_integer(unsigned(first_ready_alu_inst)));
                    rb_ALU1 <= rs_opr2(to_integer(unsigned(first_ready_alu_inst)));
                    imm6_ALU1 <= rs_imm_9(to_integer(unsigned(first_ready_alu_inst)))(5 downto 0);
                    c_ALU1_out <= rs_c(to_integer(unsigned(first_ready_alu_inst)))(0);
                    z_ALU1_out <= rs_z(to_integer(unsigned(first_ready_alu_inst)))(0); 
                    control_ALU1 <= rs_control(to_integer(unsigned(first_ready_alu_inst)));
                    rs_issued(to_integer(unsigned(first_ready_alu_inst))) <= '1';
                    finished_ALU1_sig <= '1';

                    instruction_count := instruction_count - 1;
                else
                    finished_ALU1_sig <= '0';
                end if;

                -- Finding a ready entry and forwarding it to ALU pipeline-2
                if (rd_ALU2 = '1' and rs_issued(to_integer(unsigned(second_ready_alu_inst))) = '0' and issue_valid_alu_second_sig = '0') then
                    pc_ALU2 <= rs_pc(to_integer(unsigned(second_ready_alu_inst)));
                    ra_ALU2 <= rs_opr1(to_integer(unsigned(second_ready_alu_inst)));
                    rb_ALU2 <= rs_opr2(to_integer(unsigned(second_ready_alu_inst)));
                    imm6_ALU2 <= rs_imm_9(to_integer(unsigned(second_ready_alu_inst)))(5 downto 0);
                    c_ALU2_out <= rs_c(to_integer(unsigned(second_ready_alu_inst)))(0);
                    z_ALU2_out <= rs_z(to_integer(unsigned(second_ready_alu_inst)))(0);
                    control_ALU2 <= rs_control(to_integer(unsigned(second_ready_alu_inst)));
                    rs_issued(to_integer(unsigned(second_ready_alu_inst))) <= '1';
                    finished_ALU2_sig <= '1';

                    instruction_count := instruction_count - 1;
                else
                    finished_ALU2_sig <= '0';
                end if;

                -- LHI scheduling
                -- Finding a ready entry and forwarding it to the LHI pipeline
                if (rd_LHI = '1' and rs_issued(to_integer(unsigned(ready_lhi_inst))) = '0' and issue_valid_lhi_sig = '0') then
                    pc_LHI <= rs_pc(to_integer(unsigned(ready_lhi_inst)));
                    imm9_LHI <= rs_imm_9(to_integer(unsigned(ready_lhi_inst)));
                    rs_issued(to_integer(unsigned(ready_lhi_inst))) <= '1';
                    finished_LHI_sig <= '1';

                    instruction_count := instruction_count - 1;
                else
                    finished_LHI_sig <= '0';
                end if;
            end if;
        end if;

        count <= instruction_count;
    end process rs_operation;

    update_ready_process: process(clr, rs_control, rs_v1, rs_v2, rs_v3, rs_v4)
    begin
        if (clr = '1') then
            rs_ready <= (others => '0');
        else
            for i in 0 to size - 1 loop
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
                elsif (rs_control(i)(5 downto 2) = "0011") then
                    -- LHI (no operands so always ready)
                    rs_ready(i) <= '1';
                else 
                    -- Default (more cases for other instructions)
                    rs_ready(i) <= rs_v1(i) AND rs_v2(i) AND rs_v3(i) AND rs_v4(i);
                end if;
            end loop;
        end if;
    end process update_ready_process;

    -- sets the full and empty bits to take care of stalls
    almost_full <= '1' when count = size - 1 else '0';
    full  <= '1' when count = size else '0';
    empty <= '1' when count = 0 else '0';
    almost_full_out <= almost_full;
    full_out <= full;
    empty_out <= empty; 

    finished_ALU1_out <= finished_ALU1_sig;
    finished_ALU2_out <= finished_ALU2_sig;
    finished_LHI_out <= finished_LHI_sig;
    
end behavioural;