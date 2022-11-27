library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arf is 
    port(
        clk, clr, wr: in std_logic;
        reg_select: in std_logic_vector(4 downto 0);
        data_in: in std_logic_vector(15 downto 0);
        reg_tag: out std_logic_vector(7 downto 0);
        data_out: out std_logic_vector(15 downto 0);
        reg_valid: out std_logic
    );
end arf;

architecture arf_beh of arf is  
    type arf_data_type is array(31 downto 0) of std_logic_vector(15 downto 0);
    type arf_valid_type is array(31 downto 0) of std_logic;
    type arf_tag_type is array(31 downto 0) of std_logic_vector(7 downto 0);

    signal arf_data: arf_data_type;
    signal arf_valid: arf_valid_type;
    signal arf_tag: arf_tag_type;

    signal reg_tag_sig: std_logic_vector(7 downto 0);
    signal data_out_sig: std_logic_vector(15 downto 0);
    signal reg_valid_sig: std_logic;

begin

    arf_process: process(clk, clr, wr, reg_select, data_in)
        begin
        if clr = '1' then
            for i in 0 to 31 loop
                arf_data(i) <= (others => '0');
                arf_valid(i) <= '0';
                arf_tag(i) <= (others => '0');
            end loop;
        else
            if rising_edge(clk) then 
                if wr = '1' then
                    arf_data(to_integer(unsigned(reg_select))) <= data_in;
                    arf_valid(to_integer(unsigned(reg_select))) <= '1';
                end if;
                reg_tag_sig <= arf_tag(to_integer(unsigned(reg_select)));
                reg_valid_sig <= arf_valid(to_integer(unsigned(reg_select)));
                data_out_sig <= arf_data(to_integer(unsigned(reg_select)));
            end if;
        end if;
    end process arf_process;

    reg_tag <= reg_tag_sig;
    reg_valid <= reg_valid_sig;
    data_out <= data_out_sig;

end arf_beh;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arf_flags is 
    port(
        clk, clr, wr, sel: in std_logic; -- if sel = 0 then z, if sel = 1 then c 
        data_in: in std_logic;
        reg_tag: out std_logic_vector(2 downto 0);
        data_out: out std_logic;
        reg_valid: out std_logic
    );
end arf_flags;

architecture arf_flag_beh of arf_flags is
    signal c_data, z_data, c_valid, z_valid : std_logic;
    signal c_tag, z_tag: std_logic_vector(2 downto 0);

    signal reg_tag_sig: std_logic_vector(2 downto 0);
    signal data_out_sig: std_logic;
    signal reg_valid_sig: std_logic;

begin

    flag_process: process(clk, clr, wr, sel, data_in)
        begin
        if clr = '1' then
            c_data <= '0';
            z_data <= '0';
            c_tag <= (others => '0');
            z_tag <= (others => '0');
        else
            if rising_edge(clk) then 
                if sel = '0' then
                    reg_tag_sig <= z_tag;
                    reg_valid_sig <= z_valid;
                    data_out_sig <= z_data;
                    if wr = '1' then
                        z_data <= data_in;
                        z_valid <= '1';
                    end if;
                else
                    reg_tag_sig <= c_tag;
                    reg_valid_sig <= c_valid;
                    data_out_sig <= c_data;
                    if wr = '1' then
                        c_data <= data_in;
                        c_valid <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process flag_process;
    reg_tag <= reg_tag_sig;
    reg_valid <= reg_valid_sig;
    data_out <= data_out_sig;
end arf_flag_beh;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rrf is 
    port(
        clk, clr, wr: in std_logic;
        reg_select: in std_logic_vector(7 downto 0);
        data_in: in std_logic_vector(15 downto 0);
        data_out: out std_logic_vector(15 downto 0);
        reg_valid: out std_logic
    );
end rrf;

architecture rrf_behave of rrf is 
    type rrf_data_type is array(255 downto 0) of std_logic_vector(15 downto 0);
    type rrf_valid_type is array(255 downto 0) of std_logic;

    signal rrf_data: rrf_data_type;
    signal rrf_valid: rrf_valid_type;

    signal data_out_sig: std_logic_vector(15 downto 0);
    signal reg_valid_sig: std_logic;

begin

    rrf_process: process(clk, clr, wr, reg_select, data_in)
        begin
        if clr = '1' then
            for i in 0 to 255 loop
                rrf_data(i) <= (others => '0');
                rrf_valid(i) <= '0';
            end loop;
        else
            if rising_edge(clk) then 
                if wr = '1' then
                    rrf_data(to_integer(unsigned(reg_select))) <= data_in;
                    rrf_valid(to_integer(unsigned(reg_select))) <= '1';
                end if;
                reg_valid_sig <= rrf_valid(to_integer(unsigned(reg_select)));
                data_out_sig <= rrf_data(to_integer(unsigned(reg_select)));
            end if;
        end if;
    end process rrf_process;
    reg_valid <= reg_valid_sig;
    data_out <= data_out_sig;
end rrf_behave;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rrf_z is 
    port(
        clk, clr, wr: in std_logic;
        reg_select: in std_logic_vector(2 downto 0);
        data_in: in std_logic;
        data_out: out std_logic;
        reg_valid: out std_logic
    );
end rrf_z;

architecture rrf_behave_z of rrf_z is 
    type rrfz_data_type is array(7 downto 0) of std_logic;
    type rrfz_valid_type is array(7 downto 0) of std_logic;

    signal rrfz_data: rrfz_data_type;
    signal rrfz_valid: rrfz_valid_type;

    signal data_out_sig: std_logic;
    signal reg_valid_sig: std_logic;

begin

    rrf_process: process(clk, clr, wr, reg_select, data_in)
        begin
        if clr = '1' then
            for i in 0 to 7 loop
                rrfz_data(i) <= '0';
                rrfz_valid(i) <= '0';
            end loop;
        else
            if rising_edge(clk) then 
                if wr = '1' then
                    rrfz_data(to_integer(unsigned(reg_select))) <= data_in;
                    rrfz_valid(to_integer(unsigned(reg_select))) <= '1';
                end if;
                reg_valid_sig <= rrfz_valid(to_integer(unsigned(reg_select)));
                data_out_sig <= rrfz_data(to_integer(unsigned(reg_select)));
            end if;
        end if;
    end process rrf_process;
    reg_valid <= reg_valid_sig;
    data_out <= data_out_sig;
end rrf_behave_z;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rrf_c is 
    port(
        clk, clr, wr: in std_logic;
        reg_select: in std_logic_vector(2 downto 0);
        data_in: in std_logic;
        data_out: out std_logic;
        reg_valid: out std_logic
    );
end rrf_c;

architecture rrf_behave_c of rrf_c is 
    type rrfc_data_type is array(7 downto 0) of std_logic;
    type rrfc_valid_type is array(7 downto 0) of std_logic;

    signal rrfc_data: rrfc_data_type;
    signal rrfc_valid: rrfc_valid_type;

    signal data_out_sig: std_logic;
    signal reg_valid_sig: std_logic;

begin

    rrf_process: process(clk, clr, wr, reg_select, data_in)
        begin
        if clr = '1' then
            for i in 0 to 7 loop
                rrfc_data(i) <= '0';
                rrfc_valid(i) <= '0';
            end loop;
        else
            if rising_edge(clk) then 
                if wr = '1' then
                    rrfc_data(to_integer(unsigned(reg_select))) <= data_in;
                    rrfc_valid(to_integer(unsigned(reg_select))) <= '1';
                end if;
                reg_valid_sig <= rrfc_valid(to_integer(unsigned(reg_select)));
                data_out_sig <= rrfc_data(to_integer(unsigned(reg_select)));
            end if;
        end if;
    end process rrf_process;
    reg_valid <= reg_valid_sig;
    data_out <= data_out_sig;
end rrf_behave_c;
