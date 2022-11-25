library ieee;
use ieee.std_logic_1164.all;

entity bit1shift is
	 port (
        A: in std_logic_vector(15 downto 0);
        Op: out std_logic_vector(15 downto 0)
    ) ;
end bit1shift;

architecture a1 of bit1shift is
begin
	shifter : process( A(15 downto 0))
	variable temp : std_logic_vector(16 downto 0);
	begin
		temp := A&"0";
		Op <=temp(15 downto 0);
	end process ; 
end a1 ;