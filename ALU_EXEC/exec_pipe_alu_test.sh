ghdl -a *.vhdl
ghdl -e aluexecpipe
ghdl -e tb
ghdl -r tb --wave=waveform.ghw
