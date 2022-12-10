library ieee;
use ieee.std_logic_1164.all;

entity rob is 
    generic(
        size : integer := 256 -- size of the ROB
    );
    port(
        -- INPUTS -------------------------------------------------------------------------------------------
        clk: in std_logic; -- input clock
        clr: in std_logic; -- clear bit
        rd: in std_logic; -- read bit for finished instructions

        -- Logic for newly decoded instructions
        wr_inst1, wr_inst2: in std_logic; -- write bits for newly decoded instructions 
        pc_inst1, pc_inst2: in std_logic_vector(15 downto 0); -- PC values for writing the newly decoded instructions
        dest_inst1, dest_inst2: in std_logic_vector(2 downto 0); -- destination registers for newly decoded instructions
        rr1_inst1, rr1_inst2: in std_logic_vector(7 downto 0); -- RR1 for newly decoded instructions
        rr2_inst1, rr2_inst2: in std_logic_vector(7 downto 0); -- RR2 for newly decoded instructions
        rr3_inst1, rr3_inst2: in std_logic_vector(7 downto 0); -- RR3 for newly decoded instructions

        -- Logic for newly executed ALU instructions
        wr_ALU1, wr_ALU2: in std_logic; -- write bits for newly executed ALU instructions
        pc_ALU1, pc_ALU2: in std_logic_vector(15 downto 0); -- PC values for identifying the newly executed ALU instructions
        value_ALU1, value_ALU2: in std_logic_vector(15 downto 0); -- final output values obtained from the ALU execution pipelines
        c_ALU1, c_ALU2: in std_logic; -- c values obtained from the ALU execution pipelines
        z_ALU1, z_ALU2: in std_logic; -- z values obtained from the ALU execution pipelines

        -- Logic for newly executed LHI instructions
        wr_LHI: in std_logic; -- write bits for newly executed LHI instructions
        pc_LHI: in std_logic_vector(15 downto 0); -- PC values for identifying the newly executed LHI instructions
        value_LHI: in std_logic_vector(15 downto 0); -- final output values obtained from the LHI execution pipeline

        -- OUTPUTS -------------------------------------------------------------------------------------------
        -- ALU execution pipeline
        rr1_ALU1, rr1_ALU2: out std_logic_vector(7 downto 0); -- RR1 values for both ALU pipelines to which value is written
        rr2_ALU1, rr2_ALU2: out std_logic_vector(7 downto 0); -- RR2 values for both ALU pipelines to which carry flag is written
        rr3_ALU1, rr3_ALU2: out std_logic_vector(7 downto 0); -- RR3 values for both ALU pipelines to which zero flag is written

        -- LHI execution pipeline
        rr_LHI: out std_logic_vector(7 downto 0); -- RR value for LHI pipeline to which value is written

        -- Instruction retirement
        dest_out: out std_logic_vector(2 downto 0); -- destination register for final output
        completed: out std_logic -- bit for when an instruction is completed
	);
end rob;

architecture behavioural of rob is
    -- defining the types required for different-sized columns
    type rob_type_3 is array(size - 1 downto 0) of std_logic_vector(2 downto 0);
    type rob_type_8 is array(size - 1 downto 0) of std_logic_vector(7 downto 0);
    type rob_type_16 is array(size - 1 downto 0) of std_logic_vector(15 downto 0);

    -- defining the required columns, each with (size) entries
    signal rob_pc: rob_type_16:= (others => (others => '0'));
    signal rob_value: rob_type_16:= (others => (others => '0'));

    signal rob_dest: rob_type_3:= (others => (others => '0'));
    signal rob_rr1: rob_type_8:= (others => (others => '0'));

    signal rob_c: std_logic_vector(size - 1 downto 0) := (others => '0');
    signal rob_rr2: rob_type_8:= (others => (others => '0'));

    signal rob_z: std_logic_vector(size - 1 downto 0) := (others => '0');
    signal rob_rr3: rob_type_8:= (others => (others => '0'));

    signal rob_finished: std_logic_vector(size - 1 downto 0) := (others => '0');

    -- defining the indexes for read/write, count and the full/empty bits
    signal rd_index, wr_index: integer range 0 to size - 1 := 0;
    signal empty: std_logic := '1';
    signal full: std_logic := '0';
    signal length: integer := 0;

    signal retire: std_logic := '0';
    signal retire_dest: std_logic_vector(2 downto 0) := (others => '0');

begin
    rob_operation: process(clr, clk) 
        variable count: integer;
        variable head, tail: integer;
        
    begin
        if (clr = '1') then
            -- clear data and indices when reset is set
            rob_pc <= (others => (others => '0'));
            rob_value <= (others => (others => '0'));
            rob_dest <= (others => (others => '0'));
            rob_rr1 <= (others => (others => '0'));
            rob_c <= (others => '0');
            rob_rr2 <= (others => (others => '0'));
            rob_z <= (others => '0');
            rob_rr3 <= (others => (others => '0'));
            rob_finished <= (others => '0');
            wr_index <= 0;
            rd_index <= 0;
            retire <= '0';
            empty <= '1';
            full <= '0';

            count := 0;
            head := 0;
            tail := 0;

        else
            -- FIFO logic and adding newly decoded instructions to the ROB
            if (rising_edge(clk)) then
                -- Writes 1st instruction to the empty entry pointed to by wr_index
                if (wr_inst1 = '1') then
                    rob_pc(tail) <= pc_inst1;
                    rob_dest(tail) <= dest_inst1;
                    rob_rr1(tail) <= rr1_inst1;
                    rob_rr2(tail) <= rr2_inst1;
                    rob_rr3(tail) <= rr3_inst1;
                    rob_finished(tail) <= '0';

                    count := count + 1;
                end if;

                -- Write index for the 1st instruction
                if (wr_inst1 = '1' and not (count = size)) then
                    if tail = size - 1 then
                        tail := 0;
                    else
                        tail := tail + 1;
                    end if;
                end if;

                -- Writes 2nd instruction to the empty entry pointed to by wr_index
                if (wr_inst2 = '1') then
                    rob_pc(tail) <= pc_inst2;
                    rob_dest(tail) <= dest_inst2;
                    rob_rr1(tail) <= rr1_inst2;
                    rob_rr2(tail) <= rr2_inst2;
                    rob_rr3(tail) <= rr3_inst2;
                    rob_finished(tail) <= '0';

                    count := count + 1;
                end if;

                -- Write index for the 2nd instruction
                if (wr_inst2 = '1' and not (count = size)) then
                    if tail = size - 1 then
                        tail := 0;
                    else
                        tail := tail + 1;
                    end if;
                end if;

                -- Keep track of the rd_index     
                if (rob_finished(head) = '1') then
                    if (rd = '1' and not (count = 0)) then
                        rob_finished(head) <= '0';

                        retire_dest <= rob_dest(head);
                        retire <= '1';

                        if head = size - 1 then
                            head := 0;
                        else
                            head := head + 1;
                        end if;
    
                        count := count - 1;
                    end if;
                else
                    retire_dest <= (others => '0');
                    retire <= '0';
                end if;
                
                -- Writing output values from the execution pipelines
                -- Write executed data from ALU1 into corresponding ROB entry
                if (wr_ALU1 = '1') then
                    for i in 0 to size - 1 loop
                        if (rob_pc(i) = pc_ALU1) then
                            rob_value(i) <= value_ALU1;
                            rob_c(i) <= c_ALU1;
                            rob_z(i) <= z_ALU1;
                            rob_finished(i) <= '1';
                            exit;
                        end if;
                    end loop;
                end if;

                -- Write executed data from ALU2 into corresponding ROB entry
                if (wr_ALU2 = '1') then
                    for i in 0 to size-1 loop
                        if (rob_pc(i) = pc_ALU2) then
                            rob_value(i) <= value_ALU2;
                            rob_c(i) <= c_ALU2;
                            rob_z(i) <= z_ALU2;
                            rob_finished(i) <= '1';
                            exit;
                        end if;
                    end loop;
                end if;

                -- Write executed data from LHI into corresponding ROB entry
                if (wr_LHI = '1') then
                    for i in 0 to size-1 loop
                        if (rob_pc(i) = pc_LHI) then
                            rob_value(i) <= value_LHI;
                            rob_finished(i) <= '1';
                            exit;
                        end if;
                    end loop;
                end if;
            end if;

            rd_index <= head;
            wr_index <= tail;
            length <= count;

            -- Check empty, full
            if (count = 0) then
                empty <= '1';
            else
                empty <= '0';
            end if;

            if (count = size) then
                full <= '1';
            else
                full <= '0';
            end if;
        end if;
    end process rob_operation;

    completed <= retire;
    dest_out <= retire_dest;

    read_rr_alu1: process(rob_pc, rob_rr1, rob_rr2, rob_rr3, wr_AlU1, pc_ALU1)
    begin
        if (wr_ALU1 = '1') then
            for i in 0 to size - 1 loop
                if (rob_pc(i) = pc_ALU1) then
                    -- Read rename registers for ALU1 from corresponding ROB entry
                    rr1_ALU1 <= rob_rr1(i);
                    rr2_ALU1 <= rob_rr2(i);
                    rr3_ALU1 <= rob_rr3(i);
                    exit;
                end if;
            end loop;

        else
            rr1_ALU1 <= (others => '0');
            rr2_ALU1 <= (others => '0');
            rr3_ALU1 <= (others => '0');
        end if;
    end process read_rr_alu1;

    read_rr_alu2: process(rob_pc, rob_rr1, rob_rr2, rob_rr3, wr_ALU2, pc_ALU2)
    begin
        if (wr_ALU2 = '1') then
            for i in 0 to size-1 loop
                if (rob_pc(i) = pc_ALU2) then
                    -- Read rename registers for ALU2 from corresponding ROB entry
                    rr1_ALU2 <= rob_rr1(i);
                    rr2_ALU2 <= rob_rr2(i);
                    rr3_ALU2 <= rob_rr3(i);
                    exit;
                end if;
            end loop;
        else
            rr1_ALU2 <= (others => '0');
            rr2_ALU2 <= (others => '0');
            rr3_ALU2 <= (others => '0');
        end if;
    end process read_rr_alu2;

    read_rr_lhi: process(rob_pc, rob_rr1, wr_LHI, pc_LHI)
    begin
        if (wr_LHI = '1') then
            for i in 0 to size-1 loop
                if (rob_pc(i) = pc_LHI) then
                -- Read rename register for LHI from corresponding ROB entry
                rr_LHI <= rob_rr1(i);
                end if;
            end loop;
        else
            rr_LHI <= (others => '0');
        end if;
    end process read_rr_lhi;
end architecture behavioural;