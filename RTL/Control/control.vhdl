--This functional unit controls the flow of the pipeline. It checks if fetch, decode, rs, rob and write-back stages can tick without any issue; and if so, ticks the pipeline. It also checks for stalls and flushes the pipeline if required. It also checks for the end of the program and stops the pipeline.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY Control IS
    PORT (

        --INPUTS------------------------------------
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        wr_fetch : IN STD_LOGIC;
        -- wr_rs : IN STD_LOGIC_VECTOR;

        rs_full_input : IN STD_LOGIC; --connect to full_out,
        rs_almost_full_input : IN STD_LOGIC; --connect to almost_full_out,

        wr_wb_mem : IN STD_LOGIC;
        wr_wb_regfile : IN STD_LOGIC;

        end_of_program : IN STD_LOGIC; -- This will be used to stop the pipeline. Equivalent to a permanent stall, differs in functioning.
        -- wr_rob : IN STD_LOGIC;
        -- wr_decode : IN STD_LOGIC;
        -- wr_ALU : IN STD_LOGIC; --iffy
        --OUTPUTS----------------------------------
        adv_fetch : OUT STD_LOGIC;
        adv_rs : OUT STD_LOGIC;
        adv_wb : OUT STD_LOGIC;

        rs_full: out std_logic;  --connect to rs_almost_full, rs_full of id stage
        rs_almost_full: out std_logic;

        flush_out : OUT STD_LOGIC; -- In case of a branch misprediction, we need to flush the pipeline. This will route to all of the pipelines and flush them.
        stall_out : OUT STD_LOGIC; -- For completeness sake, will remove if not required.
        

        -- adv_decode : OUT STD_LOGIC; --In our implementation, we have ifid together, will handle manually if required.
        adv_rob : OUT STD_LOGIC
        -- adv_ALU : OUT STD_LOGIC; --Here, we have the signal for ALU pipeline. Ideally, we should have a control signal for each of the pipelines.

    );
END Control;

ARCHITECTURE Behavioral OF Control IS

    -- COMPONENT writeback IS
    --     PORT (
    SIGNAL mem_ops : STD_LOGIC;
    -- );
    -- END COMPONENT;

    SIGNAL all_advance : STD_LOGIC;
    SIGNAL flush_request : STD_LOGIC;
    SIGNAL stall_request : STD_LOGIC;
BEGIN

    PROCESS (clk, rst)
    BEGIN
        IF (rst = '1' OR end_of_program = '1') THEN
            flush_request <= '1';
        ELSIF (rising_edge(clk)) THEN
            flush_request <= '0';
        END IF;
    END PROCESS;

    pipeline_tick : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            all_advance <= NOT (flush_request OR stall_request);
        END IF;
        --generate pipeline advance signals only if there is no pending flush or stall. This is the global signal that affects all pipeline stages.
    END PROCESS;

    fetch_tick : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            adv_fetch <= all_advance AND not rs_full_input; --fetch stall case handled for rs/rob full.
            -- stall_request <= NOT wr_rs;
        END IF;
    END PROCESS;

    stall_generate : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF (rs_full_input = '1') THEN
                stall_request <= '1';
            ELSE
                stall_request <= '0';
            END IF;
        END IF;
    END PROCESS;

    ----NOT REQUIRED----
    -- decode_tick : PROCESS (clk)
    -- BEGIN
    --     IF rising_edge(clk) THEN
    --         adv_decode <= all_advance AND wr_rs;
    --     END IF;
    -- END PROCESS;
    --------------------
    ----EXECUTE STAGE TICK GENERATOR----
    -- ALU_tick: process(clk)
    -- begin
    --     if rising_edge(clk) then
    --         adv_ALU <= all_advance & wr_rob;
    --         end if;
    -- end process;
    -------------------------------------

    rob_tick : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF (mem_ops = '1') THEN
                adv_rob <= all_advance AND wr_wb_mem;
            ELSE
                adv_rob <= all_advance AND wr_wb_regfile;
            END IF;
            flush_out <= flush_request;
            stall_out <= stall_request;  --flush request accepted 
        END IF;
    END PROCESS;

END ARCHITECTURE;