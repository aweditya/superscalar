#!/bin/bash
ghdl -a *.vhdl
ghdl -e DualPriorityEncoder
ghdl -e tb
ghdl -r tb --wave=dual_priority_encoder.ghw
