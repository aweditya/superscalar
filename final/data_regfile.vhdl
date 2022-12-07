library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DataRegisterFile is 
    port(
        clk, clr: in std_logic;
        source_select_1, source_select_2, source_select_3, source_select_4: in std_logic_vector(2 downto 0);

        wr1, wr2: in std_logic;
        dest_select_1, dest_select_2: in std_logic_vector(2 downto 0);
        tag_1, tag_2: in std_logic_vector(7 downto 0);

        finish_alu_1, finish_alu_2: in std_logic;
        rr_alu_1, rr_alu_2: in std_logic_vector(7 downto 0);
        data_alu_1, data_alu_2: in std_logic_vector(15 downto 0);

        complete: in std_logic;
        inst_complete_dest: in std_logic_vector(2 downto 0);

        data_out_1, data_out_2, data_out_3, data_out_4: out std_logic_vector(15 downto 0);
        data_tag_1, data_tag_2, data_tag_3, data_tag_4: out std_logic;

        rrf_busy_out: out std_logic_vector((integer'(2)**8)-1 downto 0)
    );
end entity DataRegisterFile;

architecture behavior of DataRegisterFile is  

    type arf_data_type is array((integer'(2)**3)-1 downto 0) of std_logic_vector(15 downto 0);
    type arf_valid_type is array((integer'(2)**3)-1 downto 0) of std_logic;
    type arf_tag_type is array((integer'(2)**3)-1 downto 0) of std_logic_vector(7 downto 0);

    type rrf_data_type is array((integer'(2)**8)-1 downto 0) of std_logic_vector(15 downto 0);
    type rrf_valid_type is array((integer'(2)**8)-1 downto 0) of std_logic;
    type rrf_busy_type is array((integer'(2)**8)-1 downto 0) of std_logic;

    signal rrf_data: rrf_data_type;
    signal rrf_valid: rrf_valid_type;
    signal rrf_busy: rrf_busy_type;

    signal arf_data: arf_data_type;
    signal arf_valid: arf_valid_type;
    signal arf_tag: arf_tag_type;

    signal data_out_sig_1, data_out_sig_2, data_out_sig_3, data_out_sig_4: std_logic_vector(15 downto 0);
    signal data_tag_out_1, data_tag_out_2, data_tag_out_3, data_tag_out_4: std_logic;

begin
    clear: process(clr)
        begin
        if clr = '1' then
            for i in 0 to (integer'(2)**3)-1 loop
                arf_data(i) <= (others => '0');
                arf_valid(i) <= '0';
                arf_tag(i) <= (others => '0');
                rrf_data(i) <= (others => '0');
                rrf_valid(i) <= '1';
                rrf_busy(i) <= '0';
            end loop;

            for i in (integer'(2)**3) to (integer'(2)**8)-1 loop
                rrf_data(i) <= (others => '0');
                rrf_valid(i) <= '1';
                rrf_busy(i) <= '0';
            end loop;

            data_out_sig_1 <= (others => '0');
            data_out_sig_2 <= (others => '0');
            data_out_sig_3 <= (others => '0');
            data_out_sig_4 <= (others => '0');

            data_tag_out_1 <= '0';
            data_tag_out_2 <= '0';
            data_tag_out_3 <= '0';
            data_tag_out_4 <= '0';

        end if;
    end process clear;


    source_read_1: process(source_select_1, arf_data, rrf_data)
        begin 
            if (arf_valid(to_integer(unsigned(source_select_1))) = '1') then
                data_out_sig_1 <= arf_data(to_integer(unsigned(source_select_1)));
                data_tag_out_1 <= '0';

            else
                if (rrf_valid(to_integer(unsigned(arf_tag(to_integer(unsigned(source_select_1))))))) = '1' then
                    data_out_sig_1 <= rrf_data(to_integer(unsigned(arf_tag(to_integer(unsigned(source_select_1))))));
                    data_tag_out_1 <= '0';

                else
                    --sign extension--
                    data_out_sig_1 <= std_logic_vector(resize(unsigned(arf_tag(to_integer(unsigned(source_select_1)))), 16));
                    data_tag_out_1 <= '1';

                end if;
            end if;
    end process source_read_1;
     
    source_read_2: process(source_select_2, arf_data, rrf_data)
        begin 
            if (arf_valid(to_integer(unsigned(source_select_2))) = '1') then
                data_out_sig_2 <= arf_data(to_integer(unsigned(source_select_2)));
                data_tag_out_2 <= '0';

            else
                if (rrf_valid(to_integer(unsigned(arf_tag(to_integer(unsigned(source_select_2))))))) = '1' then
                    data_out_sig_2 <= rrf_data(to_integer(unsigned(arf_tag(to_integer(unsigned(source_select_2))))));
                    data_tag_out_2 <= '0';

                else
                    --sign extension--
                    data_out_sig_2 <= std_logic_vector(resize(unsigned(arf_tag(to_integer(unsigned(source_select_2)))), 16));
                    data_tag_out_2 <= '1';

                end if;
            end if;
    end process source_read_2;
 
    -- Including dest_select_1 and tag_1 to handle dependencies within the same fetch group
    -- Convention: source_read_1 and source_read_2 are operands for the first instruction
    source_read_3: process(source_select_3, arf_data, rrf_data, dest_select_1, wr1, tag_1)
        begin
            if (arf_valid(to_integer(unsigned(source_select_3))) = '1') then
                data_out_sig_3 <= arf_data(to_integer(unsigned(source_select_3)));
                data_tag_out_3 <= '0';

            else
                if (rrf_valid(to_integer(unsigned(arf_tag(to_integer(unsigned(source_select_3))))))) = '1' then
                    data_out_sig_3 <= rrf_data(to_integer(unsigned(arf_tag(to_integer(unsigned(source_select_3))))));
                    data_tag_out_3 <= '0';

                else
                    --sign extension--
                    if (source_select_3 = dest_select_1 and wr1 = '1') then
                        data_out_sig_3 <= std_logic_vector(resize(unsigned(tag_1), 16));
                    else
                        data_out_sig_3 <= std_logic_vector(resize(unsigned(arf_tag(to_integer(unsigned(source_select_3)))), 16));
                    end if;
                    
                    data_tag_out_3 <= '1';

                end if;
            end if;
    end process source_read_3;
  
    source_read_4: process(source_select_4, arf_data, rrf_data, dest_select_1, wr1, tag_1)
        begin
            if (arf_valid(to_integer(unsigned(source_select_4))) = '1') then
                data_out_sig_4 <= arf_data(to_integer(unsigned(source_select_4)));
                data_tag_out_4 <= '0';

            else
                if (rrf_valid(to_integer(unsigned(arf_tag(to_integer(unsigned(source_select_4))))))) = '1' then
                    data_out_sig_4 <= rrf_data(to_integer(unsigned(arf_tag(to_integer(unsigned(source_select_4))))));
                    data_tag_out_4 <= '0';

                else
                    --sign extension--
                    if (source_select_4 = dest_select_1 and wr1 = '1') then
                        data_out_sig_4 <= std_logic_vector(resize(unsigned(tag_1), 16));
                    else
                        data_out_sig_4 <= std_logic_vector(resize(unsigned(arf_tag(to_integer(unsigned(source_select_4)))), 16));
                    end if;
                    
                    data_tag_out_4 <= '1';

                end if;
            end if;
    end process source_read_4;


    destination_allocate_1: process(clk, wr1, dest_select_1, tag_1)
        begin
            if rising_edge(clk) then
                if (wr1 = '1') then
                    arf_tag(to_integer(unsigned(dest_select_1))) <= tag_1;
                    arf_valid(to_integer(unsigned(dest_select_1))) <= '0';
                    rrf_valid(to_integer(unsigned(tag_1))) <= '0';
                    rrf_busy(to_integer(unsigned(tag_1))) <= '1';
                end if;
            end if;
    end process destination_allocate_1;

    destination_allocate_2: process(clk, wr2, dest_select_2, tag_2)
        begin
            if rising_edge(clk) then
                if (wr2 = '1') then
                    arf_tag(to_integer(unsigned(dest_select_2))) <= tag_2;
                    arf_valid(to_integer(unsigned(dest_select_2))) <= '0';
                    rrf_valid(to_integer(unsigned(tag_2))) <= '0';
                    rrf_busy(to_integer(unsigned(tag_2))) <= '1';
                end if;
            end if;
    end process destination_allocate_2;


    instr_finish_1: process(clk, finish_alu_1, data_alu_1, rr_alu_1)
        begin
            if rising_edge(clk) then
                if (finish_alu_1 = '1') then
                    rrf_data(to_integer(unsigned(rr_alu_1))) <= data_alu_1;
                    rrf_valid(to_integer(unsigned(rr_alu_1))) <= '1';
                end if;
            end if;
    end process instr_finish_1;
 
    instr_finish_2: process(clk, finish_alu_2, data_alu_2, rr_alu_2)
        begin
            if rising_edge(clk) then
                if (finish_alu_2 = '1') then
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
                    reg_num := to_integer(unsigned(inst_complete_dest));
                    desired_tag := to_integer(unsigned(arf_tag(reg_num)));
                    arf_data(reg_num) <= rrf_data(desired_tag);
                    rrf_busy(desired_tag) <= '0';
                    arf_valid(reg_num) <= '1';
                end if;
            end if;
    end process instr_complete;

    get_rrf_busy_process: process(rrf_busy)
    begin
        for i in 0 to (integer'(2)**8)-1 loop
            rrf_busy_out(i) <= rrf_busy(i);
        end loop;
    end process get_rrf_busy_process;

    data_out_1 <= data_out_sig_1;
    data_out_2 <= data_out_sig_2;
    data_out_3 <= data_out_sig_3;
    data_out_4 <= data_out_sig_4;

    data_tag_1 <= data_tag_out_1;
    data_tag_2 <= data_tag_out_2;
    data_tag_3 <= data_tag_out_3;
    data_tag_4 <= data_tag_out_4;

end behavior;
