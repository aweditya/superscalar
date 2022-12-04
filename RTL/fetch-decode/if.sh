#!/bin/bash
ghdl -a if.vhdl if_tb.vhdl rom.vhdl pc.vhdl
ghdl -e IFStage
ghdl -e tb
ghdl -r tb --wave=if.ghw