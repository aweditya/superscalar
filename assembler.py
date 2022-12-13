
#IITB RISC ASSEMBLER

'''
Authors: Nikhil Kaniyeri, Rohan Rajesh Kalbag
This assembler is capable of converting IITB-RISC-22 ISA assembly instructions to binaries
Which can be fed to the memory of our processor using a bootloader

If filename.asm is to be assembled then
Command Format: python assembler.py <filename>
'''

import sys
binaries = ''

if __name__ == '__main__':
    params = sys.argv
    if(len(params) > 1):
        filename = params[1]
        with open(filename + '.asm', 'r') as t:
            code = t.readlines()
            # comment handler
            code = [i for i in code if i[0] != ';' or len(i) != 0]
            
            for i, j in enumerate(code):
                if ';' in j:
                    j = j.split(';')[0]
                    code[i] = j
            code = [i for i in code if i != '']
            for line in code:
                inst, args = line.split()[:2]
                args = args.split(',')
                if(inst=="add" or inst=="adc" or inst=="adz" or inst=="adl"):
                    binaries+="0001"
                    regs = ''
                    for i in args:
                        if i[0] == "r":
                            regs = bin(int(i[1]))[2:].zfill(3) + regs
                    
                    binaries += regs[3:6] + regs[:3] + regs[6:] # due to encoding being ra rb rc, asm being rc ra rb
        
                    binaries += "0"
                    if (inst == "add"):
                        binaries += "00"
                    elif (inst == "adc"):
                        binaries += "10"
                    elif (inst == "adz"):
                        binaries += "01"
                    else:
                        binaries += "11"
                if(inst == "adi"):
                    binaries += "0000"
                    regs = ''
                    for i in args:
                        if i[0] == "r":
                            regs = bin(int(i[1]))[2:].zfill(3) + regs
                        else:
                            binaries += regs
                            binaries += bin(int(i))[2:].zfill(6)
                if(inst == "ndu" or inst == "ndc" or inst == "ndz"):
                    binaries += "0010"
                    regs = ''
                    for i in args:
                        if i[0] == "r":
                            regs = bin(int(i[1]))[2:].zfill(3) + regs
                    binaries += regs[3:6] + regs[:3] + regs[6:] # due to encoding being ra rb rc, asm being rc ra rb
                    binaries += "0"
                    if(inst == "ndu"):
                        binaries += "00"
                    elif (inst == "ndc"):
                        binaries += "10"
                    elif (inst == "ndz"):
                        binaries += "01"
                if(inst == "lhi"):
                    binaries += "0011"
                    for i in args:
                        if i[0]=="r":
                            binaries += bin(int(i[1]))[2:].zfill(3)
                        else:
                            binaries += bin(int(i))[2:].zfill(9)
                if(inst == "lw"):
                    binaries += "0111"
                    for i in args:
                        if i[0]=="r":
                            binaries += bin(int(i[1]))[2:].zfill(3)
                        else:
                            binaries += bin(int(i))[2:].zfill(6)
                if(inst == "sw"):
                    binaries += "0101"
                    for i in args:
                        if i[0] == "r":
                            binaries += bin(int(i[1]))[2:].zfill(3)
                        else:
                            binaries += bin(int(i))[2:].zfill(6)
                if(inst == "lm"):
                    binaries += "1100"
                    for i in args:
                        if i[0] == "r":
                            binaries += bin(int(i[1]))[2:].zfill(3)
                        else:
                            binaries += bin(int(i))[2:].zfill(9)
                if(inst == "sm"):
                    binaries += "1101"
                    for i in args:
                        if i[0] == "r":
                            binaries += bin(int(i[1]))[2:].zfill(3)
                        else:
                            binaries += bin(int(i))[2:].zfill(9)
                if(inst == "beq"):
                    binaries += "1000"
                    for i in args:
                        if i[0] == "r":
                            binaries += bin(int(i[1]))[2:].zfill(3)
                        else:
                            binaries += bin(int(i))[2:].zfill(6)
                if(inst == "jal"):
                    binaries += "1001"
                    for i in args:
                        if i[0] == "r":
                            binaries += bin(int(i[1]))[2:].zfill(3)
                        else:
                            binaries += bin(int(i))[2:].zfill(9)
                if(inst == "jlr"):
                    binaries += "1010"
                    for i in args:
                        if i[0] == "r":
                            binaries += bin(int(i[1]))[2:].zfill(3)
                        binaries += "000000"                    
                if(inst == "jri"):
                    binaries += "1011"
                    for i in args:
                        if i[0] == "r":
                            binaries += bin(int(i[1]))[2:].zfill(3)
                        else:
                            binaries += bin(int(i))[2:].zfill(9)                  
        
        with open('source.bin', 'w') as file:
            file.write(binaries)
        
        print("Assembled code successfully to /source.bin")
    else:
        print("No filename was passed")
