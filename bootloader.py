# IITB RISC SOFTWARE BOOTLOADER

"""
Authors: Rohan Rajesh Kalbag
This bootloader takes in source.bin and loads it into rom.vhdl

Command Format: python bootloader.py
"""

import sys

memfile_start = '''
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ROM is
    port(
		A: in std_logic_vector(15 downto 0);
		Dout: out std_logic_vector(31 downto 0)
	);
end entity ROM;

architecture behavioural of ROM is
	type mem_index is array(63 downto 0) of std_logic_vector(15 downto 0);
	signal mem: mem_index := (\n'''

memfile_end = '''
signal addr: std_logic_vector(15 downto 0);

begin
	process (A, mem)
	begin	
		addr <= A;
	end process;

	Dout <= mem(to_integer(unsigned(addr))) & mem(to_integer(unsigned(addr)) + 1);
end architecture behavioural;'''

if __name__ == '__main__':
	words = []
	params = sys.argv
	n1 = 4
	n2 = 248
	if(len(params) == 1):
		n1 = hex(n1)[2:].zfill(4).upper()
		n2 = hex(n2)[2:].zfill(4).upper()

	elif(len(params) <= 2):
		print("Enter two valid numbers 0 <= n <= 65535 for location 61, 62")
		exit()

	else:
		n1 = int(params[1]) 
		n2 = int(params[2])
		if(n1 > 65535 or n2 > 65535 or n1 < 0 or n2 < 0):
			print("Enter two valid numbers 0 <= n <= 65535 for location 61, 62")
			exit()
		else:
			n1 = hex(n1)[2:].zfill(4).upper()
			n2 = hex(n2)[2:].zfill(4).upper()

	with open('source.bin', 'r') as file:
		binary = file.read()
		word = ''
		inst_count = 0
		for i,j in enumerate(binary):
			if(i%16 != 0 or i == 0):
				word += j
			else:
				words.append(f'\t{inst_count} => "' + word + '",\n')
				word = binary[i]
				inst_count += 1
		words.append(f'\t{inst_count} => "' + word + '",\n')
	
	if(len(words) > 64):
		print("Memory insuffient to load the instructions")
		exit()

	if(len(words) < 64):
		words.append("\tOTHERS => (OTHERS => '1'));")
    
	words = ''.join(words)
	
	with open('final/rom.vhdl', 'w') as file:
		file.write(memfile_start + words + memfile_end)
		print("Booted into memory successfully")



