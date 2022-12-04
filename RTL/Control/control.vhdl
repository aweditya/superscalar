--This functional unit controls the flow of the pipeline. It checks if fetch, decode, rs, rob and write-back stages can tick without any issue; and if so, ticks the pipeline. It also checks for stalls and flushes the pipeline if required. It also checks for the end of the program and stops the pipeline.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY Control IS
    PORT(

        --INPUTS------------------------------------
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        wr_fetch : IN STD_LOGIC;
        wr_decode : IN STD_LOGIC;
        wr_ALU : IN STD_LOGIC; --iffy
        wr_rs : IN STD_LOGIC;
        wr_rob : IN STD_LOGIC;
        wr_wb_mem : IN STD_LOGIC;
        wr_wb_regfile : IN STD_LOGIC;

        --OUTPUTS----------------------------------
        adv_fetch : OUT STD_LOGIC;
        adv_decode : OUT STD_LOGIC; --In our implementation, we have ifid together, will handle manually if required.
        adv_rs : OUT STD_LOGIC;
        adv_ALU : OUT STD_LOGIC; --Here, we have the signal for ALU pipeline. Ideally, we should have a control signal for each of the pipelines.
        adv_rob : OUT STD_LOGIC;
        adv_wb : OUT STD_LOGIC;
        flush_out : OUT STD_LOGIC; -- In case of a branch misprediction, we need to flush the pipeline. This will route to all of the pipelines and flush them.
        -- stall : OUT STD_LOGIC -- For completeness sake, will remove if not required.
        end_of_program : OUT STD_LOGIC -- This will be used to stop the pipeline. Equivalent to a permanent stall, differs in functioning.
    );
END Control;

ARCHITECTURE Behavioral OF Control IS
    COMPONENT IFStage IS
        PORT (
            reset : IN STD_LOGIC;
            clk : IN STD_LOGIC;
            wr_IFID : OUT STD_LOGIC; -- Logic required in case of pipeline stall. For the time being, we always write
            IFID_inc_D, IFID_PC_D : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            IFID_IMem_D : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;
    COMPONENT aluexecpipe IS
        PORT (
            control_sig_in : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
            ra_data, rb_data, pc_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            imm_data : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
            c_in, z_in : IN STD_LOGIC := '0';
            c_out, z_out : OUT STD_LOGIC;
            pc_out, result : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    END COMPONENT;
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
            dest_inst1, dest_inst2 : IN STD_LOGIC_VECTOR(4 DOWNTO 0); -- destination registers for newly decoded instructions
            rr1_inst1, rr1_inst2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- RR1 for newly decoded instructions
            c_ALU1, z_ALU1, c_ALU2, z_ALU2 : IN STD_LOGIC; -- c and z values obtained from the execution pipelines
            rr2_inst1, rr2_inst2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- RR2 for newly decoded instructions
            rr3_inst1, rr3_inst2 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- RR3 for newly decoded instructions
            finished_ALU1, finished_ALU2 : IN STD_LOGIC; -- finished bits obtained from the execution pipelines

            -- OUTPUTS -------------------------------------------------------------------------------------------
            value_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- output value which will be written to RRF
            rr1_ALU1, rr1_ALU2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- RR1 values for both ALU pipelines to which value is written to
            rr2_ALU1, rr2_ALU2, rr3_ALU1, rr3_ALU2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- RR2, RR3 values for both ALU pipelines to which flags are written to
            dest_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0); -- destination register for final output
            full_out, empty_out : OUT STD_LOGIC -- full and empty bits for the ROB Buffer
        );
    END COMPONENT;
    COMPONENT rs IS
        GENERIC (
            size : INTEGER := 256
        );
        PORT (
            -- INPUTS -------------------------------------------------------------------------------------------
            wr_inst1, wr_inst2 : IN STD_LOGIC; -- write bits for newly decoded instructions 
            wr_ALU1, wr_ALU2 : IN STD_LOGIC; -- write bits for newly executed instructions
            rd_ALU1, rd_ALU2 : IN STD_LOGIC; -- read bits for issuing ready instructions
            clk : IN STD_LOGIC; -- input clock
            clr : IN STD_LOGIC; -- clear bit
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

            -- OUTPUTS -------------------------------------------------------------------------------------------
            pc_ALU1, pc_ALU2 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- pc values forwarded to each execution pipeline
            ra_ALU1, rb_ALU1, ra_ALU2, rb_ALU2 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- operand values forwarded to each execution pipeline
            imm6_ALU1, imm6_ALU2 : OUT STD_LOGIC_VECTOR(5 DOWNTO 0); -- imm6 values forwarded to each execution pipeline
            c_ALU1_out, z_ALU1_out, c_ALU2_out, z_ALU2_out : OUT STD_LOGIC; -- carry and zero values forwarded to each execution pipeline
            full_out, empty_out : OUT STD_LOGIC -- full and empty bits for the RS
        );
    END COMPONENT;

    -- COMPONENT writeback IS
    --     PORT (
        signal mem_ops : std_logic;
    -- );
    -- END COMPONENT;

    SIGNAL all_advance : STD_LOGIC;
    SIGNAL flush_request : STD_LOGIC;
    Signal stall_request : STD_LOGIC;
BEGIN

    PROCESS (clk, rst)
    BEGIN
        IF (rst='1') THEN
            flush_request <= '1';
        ELSIF (rising_edge(clk)) THEN
            flush_request <= '0';
        END IF;
    END PROCESS;
    tick : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            all_advance <= not (flush_request or stall_request); 
        END IF;
        --only proceed if the pipeline has ticked, which only happens if the fetch, rs, and rob can proceed
    END PROCESS;

    fetch_tick : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            adv_fetch <= all_advance AND wr_decode;
        END IF;
    END PROCESS;

    decode_tick : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            adv_decode <= all_advance AND wr_rs;
        END IF;
    END PROCESS;
    -- ALU_tick: process(clk)
    -- begin
    --     if rising_edge(clk) then
    --         adv_ALU <= all_advance & wr_rob;
    --         end if;
    -- end process;
    rob_tick : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            if (mem_ops='1') then
                adv_rob <= all_advance AND wr_wb_mem;
            else
                adv_rob <= all_advance AND wr_wb_regfile;
            end if;
            flush_out<=flush_request;
        END IF;
    END PROCESS;
    
    end architecture;