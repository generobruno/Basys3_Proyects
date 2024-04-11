xori $r1, $r0, 0003     # 00hex
xori $r2, $r0, 0004     # 04hex
j 20                    
xori $r1, $r0, 0001     # 0Chex: Next2
xori $r2, $r0, 0001     # 10hex
subu $r3, $r2, $r1      # 14hex: Next1 -> Data Hazard (Forwarding)
bne $r1, $r2, 65532     # 18hex: Data and Control Hazard (Forwarding)
addu $r4, $r1, $r2      # 1Chex:
sw $r4, 16($r3)         # 20hex: Data Hazard (Forwarding)
lw $r5, 16($r3)         # 24hex
slt $r6, $r1, $r5       # 28hex: Data Hazard (Stalling and Forwarding)
sw $r4, 16($r3)        # 2Chex
xori $r4, $r3, 0001     # 30hex: No Data Hazard (Stalling)
xori $r6, $r6, 0001     # 34hex
halt