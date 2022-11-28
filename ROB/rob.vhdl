library ieee;
use ieee.std_logic_1164.all;

entity rob is 
    generic(
        size : integer := 256 -- size of the ROB
    );
    port(
        -- INPUTS -------------------------------------------------------------------------------------------
        wr_inst1, wr_inst2: in std_logic; -- write bits for newly decoded instructions 
        wr_ALU1, wr_ALU2: in std_logic; -- write bits for newly executed instructions
        rd: in std_logic; -- read bit for finished instructions
		clk: in std_logic; -- input clock
        clr: in std_logic; -- clear bit
        pc_inst1, pc_inst2: in std_logic_vector(15 downto 0); -- PC values for writing the newly decoded instructions
        pc_ALU1, pc_ALU2: in std_logic_vector(15 downto 0); -- PC values for identifying the newly executed instructions
        value_ALU1, value_ALU2: in std_logic_vector(15 downto 0); -- final output values obtained from the execution pipelines
        dest_inst1, dest_inst2: in std_logic_vector(4 downto 0); -- destination registers for newly decoded instructions
        rr1_inst1, rr1_inst2: in std_logic_vector(7 downto 0); -- RR1 for newly decoded instructions
        c_ALU1, z_ALU1, c_ALU2, z_ALU2: in std_logic; -- c and z values obtained from the execution pipelines
        rr2_inst1, rr2_inst2: in std_logic_vector(7 downto 0); -- RR2 for newly decoded instructions
        rr3_inst1, rr3_inst2: in std_logic_vector(7 downto 0); -- RR3 for newly decoded instructions
        finished_ALU1, finished_ALU2: in std_logic; -- finished bits obtained from the execution pipelines

        -- OUTPUTS -------------------------------------------------------------------------------------------
        value_out: out std_logic_vector(15 downto 0); -- final output value which will be written to ARF
        rr1_out: out std_logic_vector(7 downto 0); -- RR1 value to which value is written to
        c_out, z_out: out std_logic; -- final c and z values to be written to the flag registers
        rr2_out, rr3_out: out std_logic_vector(7 downto 0); -- RR2, RR3 values to which flags are written to
        dest_out: out std_logic_vector(4 downto 0); -- destination register for final output
        full_out, empty_out: out std_logic -- full and empty bits for the ROB Buffer
	);
end rob;

architecture behavioural of rob is
    -- defining the types required for different-sized columns
    type rob_type_16 is array(size-1 downto 0) of std_logic_vector(15 downto 0);
    type rob_type_5 is array(size-1 downto 0) of std_logic_vector(4 downto 0);
    type rob_type_8 is array(size-1 downto 0) of std_logic_vector(7 downto 0);
    type rob_type_1 is array(size-1 downto 0) of std_logic;

    -- defining the required columns, each with (size) entries
    signal rob_pc: rob_type_16:= (others => (others => '0'));
    signal rob_value: rob_type_16:= (others => (others => '0'));
    signal rob_dest: rob_type_5:= (others => (others => '0'));
    signal rob_rr1: rob_type_8:= (others => (others => '0'));
    signal rob_c: rob_type_1:= (others => '0');
    signal rob_rr2: rob_type_8:= (others => (others => '0'));
    signal rob_z: rob_type_1:= (others => '0');
    signal rob_rr3: rob_type_8:= (others => (others => '0'));
    signal rob_finished: rob_type_1:= (others => '0');
    signal rob_completed: rob_type_1:= (others => '0');

    -- defining the indexes for read/write, count and the full/empty bits
    signal wr_index: integer range 0 to size-1 := 0;
    signal rd_index: integer range 0 to size-1 := 0;
    signal count: integer range 0 to size := 0;
    signal full: std_logic;
    signal empty: std_logic;

begin

    p1: process(clk, clr, wr_inst1, wr_inst2, rd, full, empty)
        begin
        -- both write and read from the ROB Buffer happens at the rising edge of clock
        if rising_edge(clk) then
            -- clear data and indices when reset is set
            if (clr = '1') then
                rob_pc <= (others => (others => '0'));
                rob_value <= (others => (others => '0'));
                rob_dest <= (others => (others => '0'));
                rob_rr1 <= (others => (others => '0'));
                rob_c <= (others => '0');
                rob_rr2 <= (others => (others => '0'));
                rob_z <= (others => '0');
                rob_rr3 <= (others => (others => '0'));
                rob_finished <= (others => '0');
                rob_completed <= (others => '0');
                wr_index <= 0;
                rd_index <= 0;
                count <= 0;
            end if;
            -- keeps track of the total number of entries in the ROB
            if (wr_inst1 = '1' and wr_inst2 = '1' and rd = '1') then
                count <= count + 1;
            elsif (wr_inst1 = '1' and wr_inst2 = '1' and rd = '0') then
                count <= count + 2;
            elsif (wr_inst1 = '1' and wr_inst2 = '0' and rd = '0') then
                count <= count + 1;
            elsif (wr_inst1 = '0' and wr_inst2 = '1' and rd = '0') then
                count <= count + 1;
            elsif (wr_inst1 = '0' and wr_inst2 = '0' and rd = '1') then
                count <= count - 1;
            end if;
            -- keeps track of the wr_index for the 1st instruction
            if (wr_inst1 = '1' and full = '0') then
                if wr_index = size-1 then
                    wr_index <= 0;
                else
                    wr_index <= wr_index + 1;
                end if;
            end if;
            -- writes 1st instruction to the empty entry pointed to by wr_index
            if (wr_inst1 = '1') then
                rob_pc(wr_index) <= pc_inst1;
                rob_dest(wr_index) <= dest_inst1;
                rob_rr1(wr_index) <= rr1_inst1;
                rob_rr2(wr_index) <= rr2_inst1;
                rob_rr3(wr_index) <= rr3_inst1;
                rob_finished(wr_index) <= '0';
                rob_completed(wr_index) <= '0';
            end if;
            -- keeps tracks of the wr_index for the 2nd instruction
            if (wr_inst2 = '1' and full = '0') then
                if wr_index = size-1 then
                    wr_index <= 0;
                else
                    wr_index <= wr_index + 1;
                end if;
            end if;
            -- writes 2nd instruction to the empty entry pointed to by wr_index
            if (wr_inst2 = '1') then
                rob_pc(wr_index) <= pc_inst2;
                rob_dest(wr_index) <= dest_inst2;
                rob_rr1(wr_index) <= rr1_inst2;
                rob_rr2(wr_index) <= rr2_inst2;
                rob_rr3(wr_index) <= rr3_inst2;
                rob_finished(wr_index) <= '0';
                rob_completed(wr_index) <= '0';
            end if;
            -- keeps tracks of the rd_index      
            if (rd = '1' and empty = '0') then
                if rd_index = size-1 then
                    rd_index <= 0;
                else
                    rd_index <= rd_index + 1;
                end if;
            end if;
        end if;
    end process p1;

    p2: process(clk, wr_ALU1, wr_ALU2)
        begin
        if rising_edge(clk) then
            -- write executed data from ALU1 into corresponding ROB entry
            if (wr_ALU1 = '1') then
                for i in 0 to size-1 loop
                    if (rob_pc(i) = pc_ALU1) then
                        rob_value(i) <= value_ALU1;
                        rob_c(i) <= c_ALU1;
                        rob_z(i) <= z_ALU1;
                        rob_finished(i) <= finished_ALU1;
                    end if;
                end loop;
            end if;
            -- write executed data from ALU2 into corresponding ROB entry
            if (wr_ALU2 = '1') then
                for i in 0 to size-1 loop
                    if (rob_pc(i) = pc_ALU2) then
                        rob_value(i) <= value_ALU2;
                        rob_c(i) <= c_ALU2;
                        rob_z(i) <= z_ALU2;
                        rob_finished(i) <= finished_ALU2;
                    end if;
                end loop;
            end if;
        end if;
    end process p2;

    -- reads values from the entry pointed to by rd_index
    value_out <= rob_value(rd_index);
    dest_out <= rob_dest(rd_index);
    rr1_out <= rob_rr1(rd_index);
    c_out <= rob_c(rd_index);
    rr2_out <= rob_rr2(rd_index);
    z_out <= rob_z(rd_index);
    rr3_out <= rob_rr3(rd_index);

    -- sets the full and empty bits to take care of stalls
    full  <= '1' when count = size else '0';
    empty <= '1' when count = 0 else '0';
    full_out <= full;
    empty_out <= empty;       

end behavioural;