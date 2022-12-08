#!/bin/bash
ghdl -a *.vhdl
ghdl -e tb
ghdl -r tb --wave=out.ghw
