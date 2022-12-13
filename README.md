# Superscalar Reduced Instruction Set Computer

## Course Project - CS 683 - Advanced Computer Architecture

## *Course Instructor - Prof. Virendra Singh*

### This repository contains our design of a 2-way out-of-order superscalar architecture and consists of all the Design Documents, Testbenches and Hardware Descriptions in **VHDL**

### Instruction Set Architecture Specification

It is the same as **17** instructions supported by the [**IITB-RISC-22**](https://github.com/rohankalbag/multicycle-risc), their encoding can be found in the [Problem Statement](https://github.com/rohankalbag/Multicycle-RISC-Microprocessor/blob/master/Documentation/Multicycle%20Problem%20Statement.pdf).

## Assembler

An assembler for the **IITB-RISC-22** was designed in Python to convert any input program stored as  `.asm` into a sequence of machine level 16 bit word instructions stored in   ./`source.bin` . The source code for it can be found in `./assembler.py.` The assembler also provides support for both **inline** and **out of** **line comments** for documentation to be present in the `.asm` file.

To assemble the code for a file called `code.asm` in the same directory as `assembler.py` can be done in the following way.

````bash
python assembler.py code
````

## Bootloader

An software emulated bootloader for the **IITB-RISC-22** was designed in Python to dump the binary file into the memory of the **IITB-RISC-22**. The source code for it can be found in `./bootloader.py` . It takes as input the binary file `source.bin` and loads the instructions into the file `./final/rom.vhdl`.

To load the binary file `source.bin` into memory do the following

```bash
python bootloader.py code
```


## Software Requirements

- [GHDL](https://github.com/ghdl/ghdl)
- [GTKWave](http://gtkwave.sourceforge.net/)

### Contributors

- Rohan Kalbag
- Anubhav Bhatla
- Aditya Sriram
- Nikhil Kaniyeri
