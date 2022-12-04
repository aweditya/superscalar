library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FlagRegisterFile is 
    port(
        clk, clr: in std_logic;

        reg_select_1, reg_select_2, dest: in std_logic_vector(1 downto 0);
        tag_1, tag_2: in std_logic_vector(7 downto 0);

        wr1, wr2: in std_logic;
        finish_alu_1, finish_alu_2: in std_logic;
        rr_alu_1, rr_alu_2: in std_logic_vector(7 downto 0);
        data_alu_1, data_alu_2: in std_logic_vector(15 downto 0);

        complete: in std_logic;
        inst_complete_dest: in std_logic_vector(2 downto 0);

        data_out_1, data_out_2: out std_logic_vector(7 downto 0);
        data_tag_1, data_tag_2: out std_logic
    );
end entity FlagRegisterFile;

architecture behavior of FlagRegisterFile is  

    signal arf_data: std_logic;
    signal arf_valid: std_logic;
    signal arf_tag: std_logic_vector(7 downto 0);

    type rrf_data_type is array((integer'(2)**8)-1 downto 0) of std_logic;
    type rrf_valid_type is array((integer'(2)**8)-1 downto 0) of std_logic;
    type rrf_busy_type is array((integer'(2)**8)-1 downto 0) of std_logic;

    signal rrf_data: rrf_data_type;
    signal rrf_valid: rrf_valid_type;
    signal rrf_busy: rrf_busy_type;

    signal data_out_sig_1, data_out_sig_2: std_logic_vector(7 downto 0);
    signal data_tag_out_1, data_tag_out_2: std_logic;

begin
    clear: process(clr)
    begin
        if clr = '1' then
            arf_data <= '0';
            arf_valid <= '0';
            arf_tag <= (others => '0');

            for i in 0 to (integer'(2)**8)-1 loop
                rrf_data(i) <= (others => '0');
                rrf_valid(i) <= '1';
                rrf_busy(i) <= '0';
            end loop;

            data_out_sig_1 <= (others => '0');
            data_out_sig_2 <= (others => '0');

            data_tag_out_1 <= '0';
            data_tag_out_2 <= '0';

        end if;
    end process clear;

    source_read_1: process(clk, tag_1, arf_data, rrf_data)
    begin 
        if (arf_valid = '1') then
            data_out_sig_1 <= std_logic_vector(resize(unsigned(arf_data), 8));
            data_tag_out_1 <= '0';

        else
            if (rrf_valid(to_integer(unsigned(arf_tag)))) = '1' then
                data_out_sig_1 <= std_logic_vector(resize(unsigned(rrf_data(to_integer(unsigned(arf_tag)))), 8));
                data_tag_out_1 <= '0';

            else
                --sign extension--
                data_out_sig_1 <= arf_tag;
                data_tag_out_1 <= '1';

            end if;
        end if;
    end process source_read_1;
    
    source_read_2: process(clk, reg_select_2, tag_2, arf_data, rrf_data)
        begin 
            if arf_valid(to_integer(unsigned(reg_select_2))) = '1' then
                data_out_sig_2 <= arf_data(to_integer(unsigned(reg_select_2)));
                data_tag_out_2 <= '0';

            else
                if(rrf_valid(to_integer(unsigned(tag_2)))) = '1' then
                    data_out_sig_2 <= rrf_data(to_integer(unsigned(tag_2)));
                    data_tag_out_2 <= '0';

                else
                    --sign extension--
                    data_out_sig_2 <= std_logic_vector(resize(unsigned(tag_2), 8));
                    data_tag_out_2 <= '1';

                end if;
            end if;
    end process source_read_2;


    destination_allocate_1: process(clk, wr_1, reg_select_1, tag_1)
        begin
            if rising_edge(clk) then
                if wr_1 = '1' then 
                    arf_tag(to_integer(unsigned(reg_select_1))) <= tag_1;
                    arf_valid(to_integer(unsigned(reg_select_1))) <= '0';
                    rrf_valid(to_integer(unsigned(tag_1))) <= '0';
                    rrf_busy(to_integer(unsigned(tag_1))) <= '1';
                end if;
            end if;
    end process destination_allocate_1;

    destination_allocate_2: process(clk, wr_2, reg_select_2, tag_2)
        begin
            if rising_edge(clk) then
                if wr_2 = '1' then 
                    arf_tag(to_integer(unsigned(reg_select_2))) <= tag_2;
                    arf_valid(to_integer(unsigned(reg_select_2))) <= '0';
                    rrf_valid(to_integer(unsigned(tag_2))) <= '0';
                    rrf_busy(to_integer(unsigned(tag_2))) <= '1';
                end if;
            end if;
    end process destination_allocate_2;


    instr_finish_1: process(clk, finish_alu_1, data_alu_1, rr_alu_1)
        begin
            if rising_edge(clk) then
                if (finish_alu_1 = '1' and wr_1 = '1') then
                    rrf_data(to_integer(unsigned(rr_alu_1))) <= data_alu_1;
                    rrf_valid(to_integer(unsigned(rr_alu_1))) <= '1';
                end if;
            end if;
    end process instr_finish_1;
 
    instr_finish_2: process(clk, finish_alu_2, data_alu_2, rr_alu_2)
        begin
            if rising_edge(clk) then
                if (finish_alu_2 = '1' and wr_2 = '1') then
                    rrf_data(to_integer(unsigned(rr_alu_2))) <= data_alu_2;
                    rrf_valid(to_integer(unsigned(rr_alu_2))) <= '1';
                end if;
            end if;
    end process instr_finish_2;


    instr_complete: process(clk, inst_complete_dest, complete, rrf_data, arf_tag)
        variable desired_tag: integer;
        variable reg_num: integer;

        begin
            if rising_edge(clk) then
                if (complete = '1') then
                    reg_num := to_integer(unsigned(dest));
                    desired_tag := to_integer(unsigned(arf_tag(reg_num)));
                    arf_data(reg_num) <= rrf_data(desired_tag);
                    rrf_busy(desired_tag) <= '0';
                    arf_valid(reg_num) <= '1';
                end if;
            end if;
    end process instr_complete;

    data_out_1 <= data_out_sig_1;
    data_out_2 <= data_out_sig_2;

    data_tag_1 <= data_tag_out_1;
    data_tag_2 <= data_tag_out_2;

end behavior;