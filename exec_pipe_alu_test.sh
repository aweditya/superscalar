ghdl -a exec_pipe_alu.vhdl
ghdl -a alu.vhdl
ghdl -a bit1shift.vhdl
ghdl -a se6.vhdl
ghdl -a exec_pipe_alu_tb.vhdl

ghdl -e aluexecpipe
ghdl -e tb
ghdl -r tb --wave=waveform.ghw
