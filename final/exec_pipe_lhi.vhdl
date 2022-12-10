library ieee;
use ieee.std_logic_1164.all;

entity lhiexecpipe is
    port(
        pc_in: in std_logic_vector(15 downto 0);
        data_in: in std_logic_vector(8 downto 0);

        pc_out: out std_logic_vector(15 downto 0);
        data_out: out std_logic_vector(15 downto 0)
    );
end entity lhiexecpipe;

architecture behavioural of lhiexecpipe is
begin
    data_out <= data_in & "0000000"; 
    pc_out <= pc_in;
end architecture behavioural;