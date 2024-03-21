class LookupTables:
    REGISTERS = { # 32 Registers
        '$r0'   :        '0',
        '$r1'   :        '1',
        '$r2'   :        '2',
        '$r3'   :        '3',
        '$r4'   :        '4',
        '$r5'   :        '5',
        '$r6'   :        '6',
        '$r7'   :        '7',
        '$r8'   :        '8',
        '$r9'   :        '9',
        '$r10'   :       '10',
        '$r11'   :       '11',
        '$r12'   :       '12',
        '$r13'   :       '13',
        '$r14'   :       '14',
        '$r15'   :       '15',
        '$r16'   :       '16',
        '$r17'   :       '17',
        '$r18'   :       '18',
        '$r19'   :       '19',
        '$r20'   :       '20',
        '$r21'   :       '21',
        '$r22'   :       '22',
        '$r23'   :       '23',
        '$r24'   :       '24',
        '$r25'   :       '25',
        '$r26'   :       '26',
        '$r27'   :       '27',
        '$r28'   :       '28',
        '$r29'   :       '29',
        '$r30'   :       '30',
        '$r31'   :       '31'       
    }
    
    INSTRUCTIONS = { # 36 Instructions 
        'R-TYPE': { # Opcode, operands (rs, rt, rd, sa = 5bit), funct 
            'sll':      (0b000000, [ 0b00000, 'rt', 'rd', 'sa'], 0b000000),     # SLL rd, rt, sa
            'srl':      (0b000000, [ 0b00000, 'rt', 'rd', 'sa'], 0b000010),     # SRL rd, rt, sa
            'sra':      (0b000000, [ 0b00000, 'rt', 'rd', 'sa'], 0b100011),     # SRA rd, rt, sa
            'sllv':     (0b000000, ['rs', 'rt', 'rd', 0b000000], 0b000100),     # SLLV rd, rt, rs
            'srlv':     (0b000000, ['rs', 'rt', 'rd', 0b000000], 0b000110),     # SRLV rd, rt, rs
            'srav':     (0b000000, ['rs', 'rt', 'rd', 0b000000], 0b000111),     # SRAV rd, rt, rs
            'addu':     (0b000000, ['rs', 'rt', 'rd', 0b000000], 0b100001),     # ADDU rd, rs, rt
            'subu':     (0b000000, ['rs', 'rt', 'rd', 0b000000], 0b100011),     # SUBU rd, rs, rt
            'and':      (0b000000, ['rs', 'rt', 'rd', 0b000000], 0b100100),     # AND rd, rs, rt
            'or':       (0b000000, ['rs', 'rt', 'rd', 0b000000], 0b100101),     # OR rd, rs, rt
            'xor':      (0b000000, ['rs', 'rt', 'rd', 0b000000], 0b100001),     # XOR rd, rs, rt
            'nor':      (0b000000, ['rs', 'rt', 'rd', 0b000000], 0b100110),     # NOR rd, rs, rt
            'slt':      (0b000000, ['rs', 'rt', 'rd', 0b000000], 0b101010),     # SLT rd, rs, rt
        },
        
        'I-TYPE': { # Opcode, operands (offset, immediate = 16bit; base = 5bit)
            'addi':     (0b001000, ['rs', 'rt', 'immediate']),                  # ADDI rt, rs, immediate
            'andi':     (0b001100, ['rs', 'rt', 'immediate']),                  # ANDI rt, rs, immediate
            'ori':      (0b001101, ['rs', 'rt', 'immediate']),                  # ORI rt, rs, immediate
            'xori':     (0b001110, ['rs', 'rt', 'immediate']),                  # XORI rt, rs, immediate
            'lui':      (0b001111, [ 0b00000, 'rt', 'immediate']),              # LUI rt, immediate
            'slti':     (0b001010, ['rs', 'rt', 'immediate']),                  # SLTI rt, rs, immediate
            'beq':      (0b000100, ['rs', 'rt', 'offset']),                     # BEQ rs, rt, offset
            'bne':      (0b000101, ['rs', 'rt', 'offset'])                      # BNE rs, rt, offset
        },
        
        'LOAD-STORE': { # Opcode, operands (offset = 16bit; base = 5bit)
            'lb':       (0b100000, ['base', 'rt', 'offset']),                   # LB rt, offset(base)
            'lh':       (0b100001, ['base', 'rt', 'offset']),                   # LH rt, offset(base)
            'lw':       (0b100011, ['base', 'rt', 'offset']),                   # LW rt, offset(base)
            'lbu':      (0b100100, ['base', 'rt', 'offset']),                   # LBU rt, offset(base)
            'lhu':      (0b100101, ['base', 'rt', 'offset']),                   # LHU rt, offset(base)
            'lwu':      (0b100111, ['base', 'rt', 'offset']),                   # LWU rt, offset(base)
            'sb':       (0b101000, ['base', 'rt', 'offset']),                   # SB rt, offset(base)
            'sh':       (0b101001, ['base', 'rt', 'offset']),                   # SH rt, offset(base)
            'sw':       (0b101011, ['base', 'rt', 'offset']),                   # SW rt, offset(base)
        },
        
        'J-TYPE': { # Opcode, operands (instr_index = 26bit)
            'jr':       (0b000000, ['rs', 0b000000000000000], 0b001000),        # JR rs
            'jalr':     (0b000000, ['rs', 0b00000, 'rd', 0b00000], 0b001001),   # JALR rd, rs
            'j':        (0b000010, ['instr_index']),                            # J instr_index
            'jal':      (0b000011, ['instr_index'])                             # JAL instr_index
        }
    }
    
    def __init__(self):
        self.opcodeDict = self.INSTRUCTIONS
        self.regsDict = self.REGISTERS
    
    # Return operation type
    def type(self, operator):
        for k in self.opcodeDict:
            if operator in self.opcodeDict[k]:
                return k
        
        return ''
    
    # Return operation opcode
    def opcode(self, operator):
        k = self.type(operator)
        if k == '':
            return -1
        
        return self.opcodeDict[k][operator][0]

    # Return function field
    def funct(self, operator):
        k = self.type(operator)
        if k == '' or k != 'R-TYPE':
            return -1
        
        return self.opcodeDict[k][operator][2]
    
    # Return Register number
    def reg(self, operand):
        for k in self.regsDict:
            if operand == k:
                return self.regsDict[k]
            
        return ''