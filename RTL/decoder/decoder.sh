#!/bin/bash
ghdl -a decoder.vhdl decoder_tb.vhdl
ghdl -e Decoder
ghdl -e tb
ghdl -r tb --wave=decoder.ghw