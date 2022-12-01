#!/bin/bash
ghdl -a priority_encoder.vhdl priority_encoder_tb.vhdl
ghdl -e PriorityEncoder
ghdl -e tb
ghdl -r tb --wave=priority_encoder.ghw