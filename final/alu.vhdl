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
  function add(in1: in std_logic_vector(15 downto 0); in2: in std_logic_vector(15 downto 0))
        return std_logic_vector is
        variable sum: std_logic_vector(16 downto 0) := (others => '0');
	variable c: std_logic_vector(15 downto 0);
        begin
        sum(0) := in1(0) xor in2(0);
        c(0) := in1(0) and in2(0);
        Adder:  for i in 1 to 15 loop
                sum(i) := in1(i) xor in2(i) xor c(i-1);
                c(i) := (in1(i) and in2(i)) or (in1(i) and c(i-1)) or (in2(i) and c(i-1));
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
        Op<=temp(15 downto 0);
        if temp="00000000000000000" then
        carry <= '0';
                zero <= '1';
        else
        zero <= '0';
        end if;
    else
        temp := "00000000000000000";
        Op<=temp(15 downto 0);
        carry <= '0';
        zero <= '0';
    end if;
end process;
end a1;