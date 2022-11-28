"""
Author: Nikhil Kaniyeri
Description: Converts human readable ASM code to binary that can be loaded directly on to the processor memory.
"""
import re
binary=""

with open("code.asm", 'r') as codedata:
    #codefull = codedata.read()
    for code in codedata:
        opcode,operands = code.split(" ")
        if (opcode=="add" or opcode=="adc" or opcode=="adz" or opcode=="adl"):
            binary+="0001"
            terms=operands.split(",")
            for i in terms:
                if i[0]=="r":
                    binary+=bin(int(i[1]))[2:].zfill(3)
            binary+="0"
            if(opcode=="add"):
                binary+="00"
            elif (opcode=="adc"):
                binary+="10"
            elif (opcode=="adz"):
                binary+="01"
            else:
                binary+="11"
        if (opcode=="adi"):
            binary+="0000"
            terms=operands.split(",")
            for i in terms:
                if i[0]=="r":
                    binary+=bin(int(i[1]))[2:].zfill(3)
                else:
                    binary+=i
        if (opcode=="ndu" or opcode=="ndc" or opcode=="ndz"):
            binary+="0010"
            terms=operands.split(",")
            for i in terms:
                if i[0]=="r":
                    binary+=bin(int(i[1]))[2:].zfill(3)
            binary+="0"
            if(opcode=="ndu"):
                binary+="00"
            elif (opcode=="ndc"):
                binary+="10"
            elif (opcode=="ndzz"):
                binary+="01"
        if (opcode=="lhi"):
            binary+="0000"
            terms=operands.split(",")
            for i in terms:
                if i[0]=="r":
                    binary+=bin(int(i[1]))[2:].zfill(3)
                else:
                    binary+=i
        if (opcode=="lw"):
            binary+="0111"
            terms=operands.split(",")
            for i in terms:
                if i[0]=="r":
                    binary+=bin(int(i[1]))[2:].zfill(3)
                else:
                    binary+=i
        if(opcode=="sw"):
            binary+="0101"
            terms=operands.split(",")
            for i in terms:
                if i[0]=="r":
                    binary+=bin(int(i[1]))[2:].zfill(3)
                else:
                    binary+=i
        if(opcode=="lm"):
            binary+="1100"
            terms=operands.split(",")
            for i in terms:
                if i[0]=="r":
                    binary+=bin(int(i[1]))[2:].zfill(3)
                else:
                    binary+=i
        if(opcode=="sm"):
            binary+="1101"
            terms=operands.split(",")
            for i in terms:
                if i[0]=="r":
                    binary+=bin(int(i[1]))[2:].zfill(3)
                else:
                    binary+=i
        if(opcode=="beq"):
            binary+="1000"
            terms=operands.split(",")
            for i in terms:
                if i[0]=="r":
                    binary+=bin(int(i[1]))[2:].zfill(3)
                else:
                    binary+=i
        if(opcode=="jal"):
            binary+="1001"
            terms=operands.split(",")
            for i in terms:
                if i[0]=="r":
                    binary+=bin(int(i[1]))[2:].zfill(3)
                else:
                    binary+=i
        if(opcode=="jlr"):
            binary+="1010"
            terms=operands.split(",")
            for i in terms:
                if i[0]=="r":
                    binary+=bin(int(i[1]))[2:].zfill(3)
                binary+="000000"                    
        if(opcode=="jri"):
            binary+="1011"
            terms=operands.split(",")
            for i in terms:
                if i[0]=="r":
                    binary+=bin(int(i[1]))[2:].zfill(3)
                else:
                    binary+=i    
        
        
                
            
print (binary)                    
            
        
        


        
