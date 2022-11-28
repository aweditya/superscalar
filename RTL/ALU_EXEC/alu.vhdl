library ieee;
use ieee.std_logic_1164.all;

entity alu is
    port (
        A: in std_logic_vector(15 downto 0);
        B: in std_logic_vector(15 downto 0);
        S: in std_logic_vector(1 downto 0);
        --clk: in std_logic;
        Op: out std_logic_vector(15 downto 0);
        carry: out std_logic;
        zero: out std_logic
        );
end alu;

architecture a1 of alu is
  function add(A: in std_logic_vector(15 downto 0); B: in std_logic_vector(15 downto 0))
        return std_logic_vector is
        variable sum: std_logic_vector(16 downto 0) := (others => '0');
	variable c: std_logic_vector(15 downto 0);
	variable i: integer;
        begin
        sum(0) := A(0) xor B(0);
        c(0) := A(0) and B(0);
        Adder:  for i in 1 to 15 loop
                sum(i) := A(i) xor B(i) xor c(i-1);
                c(i) := (A(i) and B(i)) or (A(i) and c(i-1)) or (B(i) and c(i-1));
                end loop;
        sum(16) := c(15);
        return sum;
    end add;
begin
alu_proc: process(A, B, S)
variable temp: std_logic_vector(16 downto 0);
begin
    if S="01" then 
        temp := add(A,B);
        Op <= temp(15 downto 0);
        carry <= temp(16);
        if temp(15 downto 0)="0000000000000000" then
                zero<='1';
        else
                zero<='0';
        end if;
    elsif S="10" then
        temp := '0'&(A nand B);
        Op<=temp(15 downto 0);
        if temp="00000000000000000" then
                zero<='1';
        else
                zero <='0';
        end if;
    elsif S="11" then
        temp := '0'&(A xor B);
        if temp="00000000000000000" then
        carry <= '0';
                zero <= '1';
        else
        zero <= '0';
        end if;
    else
      null;
    end if;
end process;
end a1;