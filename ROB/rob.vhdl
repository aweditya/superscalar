library ieee;
use ieee.std_logic_1164.all;

entity rob is 
    generic(
        size : integer := 256
    )
    port(
        wr: in std_logic;
        rd: in std_logic;
		clk: in std_logic;
        clr: in std_logic;
        pc_in: in std_logic_vector(15 downto 0);
        value_in: in std_logic_vector(15 downto 0);
        dest_in: in std_logic_vector(4 downto 0);
        rr1_in: in std_logic_vector(7 downto 0);
        c_in, z_in: in std_logic;
        rr2_in, rr3_in: in std_logic_vector(2 downto 0);
        finished_in: in std_logic;

        value_out: out std_logic_vector(15 downto 0);
        rr1_out: out std_logic_vector(7 downto 0);
        c_out, z_out: out std_logic;
        rr2_out, rr3_out: out std_logic_vector(2 downto 0);
        dest_out: out std_logic_vector(4 downto 0);
        full_out, empty_out: out std_logic;
	);
end rob;

architecture behavioural of rob is
    -- defining the types required for different-sized columns
    type rob_type_16 is array(size-1 downto 0) of std_logic_vector(15 downto 0);
    type rob_type_5 is array(size-1 downto 0) of std_logic_vector(4 downto 0);
    type rob_type_8 is array(size-1 downto 0) of std_logic_vector(7 downto 0);
    type rob_type_1 is array(size-1 downto 0) of std_logic;
    type rob_type_3 is array(size-1 downto 0) of std_logic_vector(2 downto 0);

    -- defining the required columns, each with (size) entries
    signal rob_pc: rob_type_16:= (others => (others => '0'));
    signal rob_value: rob_type_16:= (others => (others => '0'));
    signal rob_dest: rob_type_5:= (others => (others => '0'));
    signal rob_rr1: rob_type_8:= (others => (others => '0'));
    signal rob_c: rob_type_1:= (others => '0');
    signal rob_rr2: rob_type_3:= (others => (others => '0'));
    signal rob_z: rob_type_1:= (others => '0');
    signal rob_rr3: rob_type_3:= (others => (others => '0'));
    signal rob_finished: rob_type_1:= (others => '0');
    signal rob_completed: rob_type_1:= (others => '0');

    -- defining the indexes for read/write, count and the full/empty bits
    signal wr_index: integer range 0 to size-1 := 0;
    signal rd_index: integer range 0 to size-1 := 0;
    signal count: integer range 0 to size-1 := 0;
    signal full: std_logic;
    signal empty: std_logic;

begin

    p1: process(clr, wr)
        begin
        -- clear data and index when reset is set
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
        -- keeps tracks of the total number of entries in the ROB
        if (wr = '1' and rd = '0') then
            count <= count + 1;
        elsif (wr = '0' and rd = '1') then
            count <= count - 1;
        end if;
        -- keeps tracks of the wr_index
        if (wr = '1' and full = '0') then
            if wr_index = size-1 then
                wr_index <= 0;
            else
                wr_index <= wr_index + 1;
            end if;
        end if;
        -- keeps tracks of the rd_index      
        if (rd = '1' and empty = '0') then
            if rd_index = size-1 then
                rd_index <= 0;
            else
                rd_index <= rd_index + 1;
            end if;
        end if;
        -- writes to the empty entry pointed to by by wr_index
        if (wr = '1') then
            rob_pc(wr_index) <= pc_in;
            rob_value(wr_index) <= value_in;
            rob_dest(wr_index) <= dest_in;
            rob_rr1(wr_index) <= rr1_in;
            rob_c(wr_index) <= c_in;
            rob_rr2(wr_index) <= rr2_in;
            rob_z(wr_index) <= z_in;
            rob_rr3(wr_index) <= rr3_in;
            rob_finished(wr_index) <= finished_in;
            rob_completed(wr_index) <= '0';
        end if;
    end process p1;

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

end behavioural