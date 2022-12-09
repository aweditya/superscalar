library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FlagRegisterFile is 
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
end entity FlagRegisterFile;

architecture behavior of FlagRegisterFile is  
    signal arf_data: std_logic_vector(0 downto 0);
    signal arf_valid: std_logic;
    signal arf_tag: std_logic_vector(7 downto 0);

    type rrf_data_type is array((integer'(2)**8)-1 downto 0) of std_logic_vector(0 downto 0);
    type rrf_valid_type is array((integer'(2)**8)-1 downto 0) of std_logic;
    type rrf_busy_type is array((integer'(2)**8)-1 downto 0) of std_logic;

    signal rrf_data: rrf_data_type;
    signal rrf_valid: rrf_valid_type;
    signal rrf_busy: rrf_busy_type;

    signal data_out_sig_1, data_out_sig_2: std_logic_vector(7 downto 0);
    signal data_tag_out_1, data_tag_out_2: std_logic;

begin
    write_process: process(clr, clk, wr1, tag_1, wr2, tag_2, finish_alu_1, data_alu_1, rr_alu_1, finish_alu_2, data_alu_2, rr_alu_2, complete, rrf_data, arf_tag)
        variable desired_tag: integer;

    begin
        if (clr = '1') then
            arf_data <= (others => '0');
            arf_valid <= '1';
            arf_tag <= (others => '0');

            for i in 0 to (integer'(2)**8)-1 loop
                rrf_data(i) <= (others => '0');
                rrf_valid(i) <= '1';
                rrf_busy(i) <= '0';
            end loop;

        else
            if rising_edge(clk) then
                if (wr1 = '1') then
                    arf_tag <= tag_1;
                    arf_valid <= '0';
                    rrf_valid(to_integer(unsigned(tag_1))) <= '0';
                    rrf_busy(to_integer(unsigned(tag_1))) <= '1';
                end if;

                if (wr2 = '1') then
                    arf_tag <= tag_2;
                    arf_valid <= '0';
                    rrf_valid(to_integer(unsigned(tag_2))) <= '0';
                    rrf_busy(to_integer(unsigned(tag_2))) <= '1';
                end if;

                if (finish_alu_1 = '1') then
                    rrf_data(to_integer(unsigned(rr_alu_1))) <= data_alu_1;
                    rrf_valid(to_integer(unsigned(rr_alu_1))) <= '1';
                end if;

                if (finish_alu_2 = '1') then
                    rrf_data(to_integer(unsigned(rr_alu_2))) <= data_alu_2;
                    rrf_valid(to_integer(unsigned(rr_alu_2))) <= '1';
                end if;

                if (complete = '1') then
                    desired_tag := to_integer(unsigned(arf_tag));
                    arf_data <= rrf_data(desired_tag);
                    rrf_busy(desired_tag) <= '0';
                    arf_valid <= '1';
                end if;
            end if;
        end if;
    end process write_process;

    source_read_1: process(clr, arf_data, rrf_data, arf_tag, arf_valid, rrf_valid)
        begin 
            if (clr = '1') then
                data_out_sig_1 <= (others => '0');
                data_tag_out_1 <= '1';

            else
                if (arf_valid = '1') then
                    data_out_sig_1 <= std_logic_vector(resize(unsigned(arf_data), 8));
                    data_tag_out_1 <= '1';

                else
                    if (rrf_valid(to_integer(unsigned(arf_tag)))) = '1' then
                        data_out_sig_1 <= std_logic_vector(resize(unsigned(rrf_data(to_integer(unsigned(arf_tag)))), 8));
                        data_tag_out_1 <= '1';

                    else
                        --sign extension--
                        data_out_sig_1 <= arf_tag;
                        data_tag_out_1 <= '0';

                    end if;
                end if;
            end if;
    end process source_read_1;
     
    source_read_2: process(clr, arf_data, rrf_data, arf_tag, arf_valid, rrf_valid, wr1, tag_1)
        begin 
            if (clr = '1') then
                data_out_sig_2 <= (others => '0');
                data_tag_out_2 <= '1';
                
            else
                if (wr1 = '1') then
                    data_out_sig_2 <= tag_1;
                    data_tag_out_2 <= '0';
                
                else
                    if (arf_valid = '1') then
                        data_out_sig_2 <= std_logic_vector(resize(unsigned(arf_data), 8));
                        data_tag_out_2 <= '1';

                    else
                        if (rrf_valid(to_integer(unsigned(arf_tag)))) = '1' then
                            data_out_sig_2 <= std_logic_vector(resize(unsigned(rrf_data(to_integer(unsigned(arf_tag)))), 8));
                            data_tag_out_2 <= '1';

                        else
                            data_out_sig_2 <= arf_tag;
                            data_tag_out_2 <= '0';

                        end if;
                    end if;
                end if;
            end if;
        end process source_read_2;

    get_rrf_busy_process: process(rrf_busy)
    begin
        for i in 0 to (integer'(2)**8)-1 loop
            rrf_busy_out(i) <= rrf_busy(i);
        end loop;
    end process get_rrf_busy_process;

    data_out_1 <= data_out_sig_1;
    data_out_2 <= data_out_sig_2;

    data_tag_1 <= data_tag_out_1;
    data_tag_2 <= data_tag_out_2;

end behavior;
