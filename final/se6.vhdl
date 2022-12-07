library ieee;
use ieee.std_logic_1164.all;

entity bitextender6 is
    port (
        A: in std_logic_vector(5 downto 0);
        Op: out std_logic_vector(15 downto 0)
    ) ;
end bitextender6;

architecture behavior of bitextender6 is
begin
	alu : process(A)
	begin
	if A(5) ='0' then
		Op <= "0000000000"&A;
	elsif A(5) ='1' then 
		Op <= "1111111111"&A;
	end if;
	end process ; -- alu	
end behavior;