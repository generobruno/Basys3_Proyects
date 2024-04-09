xori $r1, $r0, 0003     # 00hex
xori $r2, $r0, 0004     # 04hex
j 56                    # 08hex: Jump to Next3
xori $r1, $r0, 0001     # 0Chex: Next2
xori $r2, $r0, 0001     # 10hex
subu $r3, $r2, $r1      # 14hex: Next1 
bne $r1, $r2, 65532     # 18hex
addu $r4, $r1, $r2      # 1Chex
sw $r4, 16($r3)         # 20hex
lw $r5, 16($r3)         # 24hex
slt $r6, $r1, $r5       # 28hex
slt $r4, 16($r3)        # 2Chex
xori $r4, $r3, 0001     # 30hex
xori $r6, $r6, 0001     # 34hex
addi $r15, $r0, 65535    # 38hex: Next3 -> Add FFFF in reg[15]
sw $r15, 24($r13)       # 3Chex
lhu $r30, 24($r13)      # 40hex: Test LHU
halt