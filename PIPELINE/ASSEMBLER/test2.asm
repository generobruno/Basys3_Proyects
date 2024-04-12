xori $r1, $r0, 0003     
xori $r2, $r0, 0004     
j 56
xori $r1, $r0, 0001     
xori $r2, $r0, 0001
subu $r3, $r2, $r1        
bne $r1, $r2, 65532
addu $r4, $r1, $r2 
sw $r4, 16($r3)    
lw $r5, 16($r3)    
slt $r6, $r1, $r5  
sw $r4, 16($r3)   
xori $r4, $r3, 0001
xori $r6, $r6, 0001
addi $r15, $r0, 65535    
sw $r15, 24($r13)  
lhu $r30, 24($r13)
halt