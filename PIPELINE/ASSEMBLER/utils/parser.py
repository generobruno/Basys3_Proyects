import re

from utils.formats import LookupTables
from utils.utils import Utils

class BaseInstruction(object):
    def __init__(self, instrRegex):
        # Regex
        self.instrRegex = re.compile(instrRegex)
        # LookupTables
        self.instrLookup = LookupTables()
        # Converter Function
        self.formatFunct = lambda s, n: Utils.int2bs(s, n) # Binary Conversion

    def parseInstr(self, instr):
        match = self.instrRegex.match(instr)
        if not match:
            return '', ()

        groups = list(filter(lambda x: x is not None, match.groups()))
        operator = groups[0]
        operands = groups[1:]

        return operator, operands

class RTypeInstruction(BaseInstruction):
    def __init__(self):
        RTypeRegex = r'(\w+)\s+(\$r\d+)\s?,?\s+(\$r\d+)\s?,?\s+(\$r\d+)' # OPCODE $rd, $rt, $rs
        super(RTypeInstruction, self).__init__(RTypeRegex)

    def parseInstr(self, instr):
        operator, operands = super(RTypeInstruction, self).parseInstr(instr)
        fmt_ops = []
        
        # Get function field
        funct_field = self.instrLookup.funct(operator)
        
        # Get Registers Number
        operands = list(map(lambda x: self.instrLookup.reg(x) if isinstance(x, str) and x.startswith("$") else x, operands))

        # Check the operator and format operands accordingly
        if operator in ['sll', 'srl', 'sra']:
            # OP rd, rt, sa -> [0b00000, 'rt', 'rd', 'sa']
            fmt_ops.append(self.formatFunct(0b00000, 5))  
            fmt_ops.append(self.formatFunct(operands[1],5))  # rt
            fmt_ops.append(self.formatFunct(operands[0],5))  # rd
            fmt_ops.append(self.formatFunct(operands[2],5))  # sa
            fmt_ops.append(self.formatFunct(funct_field, 6))
        elif operator in ['sllv', 'srlv', 'srav']:
            # OP rd, rt, rs -> ['rs', 'rt', 'rd', 0b00000]
            fmt_ops.append(self.formatFunct(operands[1], 5))  # rs
            fmt_ops.append(self.formatFunct(operands[2], 5))  # rt
            fmt_ops.append(self.formatFunct(operands[0], 5))  # rd
            fmt_ops.append(self.formatFunct(0b00000, 5))
            fmt_ops.append(self.formatFunct(funct_field, 6))
        else:
            # OP rd, rs, rt -> ['rs', 'rt', 'rd', 0b00000]
            fmt_ops.append(self.formatFunct(operands[1], 5))  # rs
            fmt_ops.append(self.formatFunct(operands[2], 5))  # rt
            fmt_ops.append(self.formatFunct(operands[0], 5))  # rd
            fmt_ops.append(self.formatFunct(0b00000, 5)) 
            fmt_ops.append(self.formatFunct(funct_field, 6))
        
        return operator, fmt_ops

class ITypeInstruction(BaseInstruction):
    def __init__(self):
        ITypeRegex = r'(\w+)\s+(\$r\d+)\s?,?\s*(\$r\d+)?\s*,?\s*(\d+)'
        super(ITypeInstruction, self).__init__(ITypeRegex)

    def parseInstr(self, instr):
        operator, operands = super(ITypeInstruction, self).parseInstr(instr)
        fmt_ops = []
        
        # Get Registers Number
        operands = list(map(lambda x: self.instrLookup.reg(x) if isinstance(x, str) and x.startswith("$") else x, operands))

        # Check the operator and format operands accordingly
        if operator in ['lui']:
            # OP rt, immediate -> [ 0b00000, 'rt', 'immediate']
            fmt_ops.append(self.formatFunct(0b00000,5))  
            fmt_ops.append(self.formatFunct(operands[0],5))     # rt
            fmt_ops.append(self.formatFunct(operands[1],16))    # imm
        else:
            # OP rt, rs, immediate -> ['rs', 'rt', 'immediate']
            fmt_ops.append(self.formatFunct(operands[1], 5))    # rs
            fmt_ops.append(self.formatFunct(operands[0], 5))    # rt
            fmt_ops.append(self.formatFunct(operands[2], 16))   # imm

        return operator, fmt_ops

class LSTypeInstruction(BaseInstruction):
    def __init__(self):
        LSTypeRegex = r'(\w+)\s+(\$r\d+)\s?,?\s*(-?\d+)\s?\(\s*(\$r\d+)\s*\)'
        super(LSTypeInstruction, self).__init__(LSTypeRegex)
        
    def parseInstr(self, instr):
        operator, operands = super(LSTypeInstruction, self).parseInstr(instr)
        fmt_ops = []
        
        # Get Registers Number
        operands = list(map(lambda x: self.instrLookup.reg(x) if isinstance(x, str) and x.startswith("$") else x, operands))

        # OP rt, offset(base) -> ['base', 'rt', 'offset']
        fmt_ops.append(self.formatFunct(operands[2],5))     # base    
        fmt_ops.append(self.formatFunct(operands[0],5))     # rt
        fmt_ops.append(self.formatFunct(operands[1],16))    # offset

        return operator, fmt_ops

class JTypeInstruction(BaseInstruction):
    def __init__(self):
        JTypeRegex = r'(\w+)\s+(\$r\d+|(\w+))(?:\s*?,?\s*(\$r\d+)(?!\$r\d+))?$'
        super(JTypeInstruction, self).__init__(JTypeRegex)

    def parseInstr(self, instr):
        operator, operands = super(JTypeInstruction, self).parseInstr(instr)
        fmt_ops = []
        
        # Get function field
        funct_field = self.instrLookup.funct(operator)
        
        # Get Registers Number
        operands = list(map(lambda x: self.instrLookup.reg(x) if isinstance(x, str) and x.startswith("$") else x, operands))

        if operator in ['jr']:
            # OP rs -> ['rs', 0b000000000000000]
            fmt_ops.append(self.formatFunct(operands[0],5))     # rs
            fmt_ops.append(self.formatFunct(0b0,15))     
            fmt_ops.append(self.formatFunct(funct_field, 6))
        elif operator in ['jalr']:
            # OP rd, rs -> ['rs', 0b00000, 'rd', 0b00000]
            if len(operands) > 1:
                fmt_ops.append(self.formatFunct(operands[1],5))     # rs
            else:
                fmt_ops.append(self.formatFunct(31,5))
            fmt_ops.append(self.formatFunct(0b0,5)) 
            fmt_ops.append(self.formatFunct(operands[0],5))     # rd
            fmt_ops.append(self.formatFunct(0b0,5)) 
            fmt_ops.append(self.formatFunct(funct_field, 6)) 
        else:
            # OP instr_index -> ['instr_index']
            fmt_ops.append(self.formatFunct(operands[0],26))     # rt

        return operator, fmt_ops

class InstructionParser:
    def __init__(self, labelsMap={}):
        self.instrObjMap = {
            'R-TYPE':       RTypeInstruction,
            'I-TYPE':       ITypeInstruction,
            'LOAD-STORE':   LSTypeInstruction,
            'J-TYPE':       JTypeInstruction
        }

        self.formatFuncMap = {
            'binary': lambda s, n: Utils.int2bs(s, n),
            'hex': lambda s, n: Utils.bs2hex(Utils.int2bs(s, n))
        }

        self.labelsMap = labelsMap

        self.instrLookup = LookupTables()
        self.instrObj = None

    def extractLabels(self, instr):
        if not instr:
            return '', ''

        split = instr.split(':', 1)

        if len(split) < 2:
            return '', instr

        return split[0], split[1].strip()

    def parse(self, instr):
        label, instr = self.extractLabels(instr)
        if not instr:
            return '', '', None

        # Parse Opcode and Instruction Type
        operator = instr.split(' ')[0]
        instrType = self.instrLookup.type(operator)
        if not instrType:
            return '', '', None

        # Parse Instruction Type tokens
        instrObj = self.instrObjMap[instrType]()
        operator, operands = instrObj.parseInstr(instr) 

        if label:
            operands = list(operands)
            if label not in self.labelsMap:
                operands[-1] = None

            operands[-1] = str(self.labelsMap[label])
            operands = tuple(operands)

        return instrType, operator, operands

    def convert(self, instr, format='binary', formatFunc=None):
        if not instr:
            return ''

        if formatFunc is None:
            formatFunc = self.formatFuncMap[format]

        # Get operator (Instruction Name) and operands
        _, operator, operands = self.parse(instr)
        if not operator:
            return ''

        # Convert OpCode to 6 bits
        opcode = self.instrLookup.opcode(operator)
        convertedOpcode = formatFunc(opcode, 6)

        # Form complete instruction
        convertedOutput = convertedOpcode + ''.join(operands)
        return convertedOutput

"""
if __name__ == '__main__':
    # Test
    ip = InstructionParser()
    print("R-TYPE")
    print(ip.convert('sll $r6, $r2, $r0'))
    print(ip.convert('srl $r6, $r2, $r4'))
    print(ip.convert('sra $r6 $r2 $r4'))
    print(ip.convert('sllv $r6 $r2 $r4'))
    print(ip.convert('srlv $r6 $r2 $r4'))
    print(ip.convert('srav $r6 $r2 $r4'))
    print(ip.convert('addu $r6 $r2 $r4'))
    print(ip.convert('subu $r6 $r2 $r4'))
    print(ip.convert('and $r6 $r2 $r4'))
    print(ip.convert('or $r6 $r2 $r4'))
    print(ip.convert('xor $r6 $r2 $r4'))
    print(ip.convert('nor $r6 $r2 $r4'))
    print(ip.convert('slt $r6 $r2 $r4'))
    print("I-TYPE")
    print(ip.convert('addi $r2, $r4, 100'))
    print(ip.convert('andi $r2, $r4, 100'))
    print(ip.convert('ori $r2, $r4, 100'))
    print(ip.convert('xori $r2, $r4, 100'))
    print(ip.convert('lui $r2, $r4, 100'))
    print(ip.convert('slti $r2, $r4, 100'))
    print(ip.convert('beq $r2, $r4, 100'))
    print(ip.convert('bne $r2, $r4, 100'))
    print("LOAD-STORE")
    print(ip.convert('lb $r3, 10($r2)'))
    print(ip.convert('lh $r3, 10($r2)'))
    print(ip.convert('lw $r3, 10($r2)'))
    print(ip.convert('lbu $r3, 10($r2)'))
    print(ip.convert('lhu $r3, 10($r2)'))
    print(ip.convert('lwu $r3, 10($r2)'))
    print(ip.convert('sb $r3, 10($r2)'))
    print(ip.convert('sh $r3, 10($r2)'))
    print(ip.convert('sw $r3, 10($r2)'))
    print("J-TYPE")
    print(ip.convert('j 100'))
    print(ip.convert('jal 100'))
    print(ip.convert('jr $r3'))
    print(ip.convert('jalr $r3, $r5'))
    print(hex(int(ip.convert('addu $r6 $r2 $r4', format='binary'), 2)))
"""