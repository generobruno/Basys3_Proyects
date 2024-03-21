`timescale 1ns/1ps

module pipeline_tb();
    // Parameters
    localparam T             =   10;    // Clock Period [ns]
    localparam INST_SZ       =   32;
    localparam PC_SZ         =   32;
    localparam OPCODE_SZ     =   6;
    localparam FUNCT_SZ      =   6;
    localparam REG_SZ        =   5;
    localparam MEM_SZ        =   10;
    localparam FORW_EQ       =   1;
    localparam FORW_ALU      =   2;
    localparam ALU_OP        =   3;
    localparam ALU_SEL       =   6;
    localparam FUNCT         =   6;

    // Operation Parameters
    localparam ADDU =           6'b100001;      // Add Word Unsigned 
    localparam SUBU =           6'b100011;      // Subtract Word Unsigned
    localparam AND  =           6'b100100;      // Logical bitwise AND 
    localparam OR   =           6'b100101;      // Logical bitwise OR
    localparam XOR  =           6'b100110;      // Logical bitwise XOR
    localparam NOR  =           6'b100111;      // Logical bitwise NOR
    localparam SLT  =           6'b101010;      // Set on Less Than
    localparam SRA  =           6'b000011;      // Shift Word Right Arithmetic
    localparam SRL  =           6'b000010;      // Shift Word Right Logic
    localparam SLL  =           6'b000000;      // Shift Word Left Logic
    localparam SLLV =           6'b000100;      // Shift Word Left Logic Variable
    localparam SRLV =           6'b000110;      // Shift Word Right Logic Variable
    localparam SRAV =           6'b000111;      // Shift Word Right Arithmetic Variable
    localparam JR       =       6'b001000;      // Jump Register
    localparam JALR     =       6'b001001;      // Jump and Link Register
    localparam NOP      =       32'hFFFF_FFFF;  // NOP

    // Declarations
    reg i_clk;
    reg i_reset;
    reg i_enable;
    reg i_write;
    reg [INST_SZ-1 : 0]           i_instruction;
    reg [REG_SZ-1 : 0]            i_debug_addr;

    wire [INST_SZ-1 : 0]          o_pc;
    wire [INST_SZ-1 : 0]          o_mem;
    wire [INST_SZ-1 : 0]          o_reg;
    wire                          o_halt;

    reg [INST_SZ-1 : 0] seed;
    reg [INST_SZ-1 : 0] expected_res;    
    reg [4 : 0]         reg_instr_rt;
    reg [4 : 0]         reg_instr_rs;   
    reg [4 : 0]         reg_instr_rd;   
    reg [4 : 0]         reg_sa;  
    reg [4 : 0]         reg_base;
    reg [15 : 0]        reg_offset;
    reg [15 : 0]        reg_immediate;
    reg [25 : 0]        reg_instr_index;

    integer i;

    // Instantiations
    pipeline #() Pipeline
        (
        // Inputs 
        .i_clk(i_clk), .i_reset(i_reset),
        .i_write(i_write), .i_enable(i_enable),
        .i_instruction(i_instruction),
        .i_debug_addr(i_debug_addr),
        // Outputs
        .o_pc(o_pc), .o_mem(o_mem),  .o_halt(o_halt), .o_reg(o_reg)
        );

    // Clock Generation
    always
    begin
        #(T) i_clk = ~i_clk;
    end
    
    // Task
    initial 
    begin
        i_clk = 1'b0;
        i_enable = 1'b0;
        i_reset = 1'b0;
        i_write = 1'b1;
        i_instruction = {INST_SZ{1'b0}};

        seed = 123456;
        expected_res = {INST_SZ{1'b0}};

        i_reset = 1'b1;
        #(T*2);
        i_reset = 1'b0;

        //! ADDI - Add Immediate Test: rt <- rs + imm
        // Inputs
        reg_instr_rs = 5'b0000;
        reg_immediate = 16'h0002;
        reg_instr_rt = 5'b00010;
        // reg[2] = 2

        i_instruction = {6'b001000, reg_instr_rs, reg_instr_rt, reg_immediate};

        #(T*2);

        //! SW - Store Test: mem[base+offset] <- rt
        // Inputs
        reg_base = 5'b00000;
        reg_offset = 16'h0002;
        reg_instr_rt = 5'b00010;
        // mem[0] = 2

        i_debug_addr = 5'b00001; // Signed offset + GPR[base] // TODO Revisar y ver caso LH (y LB)

        i_instruction = {6'b101011, reg_base, reg_instr_rt, reg_offset};

        #(T*2);

        //! LH - Load Test: rt <- mem[base+offset]
        // Inputs
        reg_base = 5'b00000;
        reg_offset = 16'h0002;
        reg_instr_rt = 5'b00101;
        // reg[5] = 2

        i_debug_addr = 5'b00010; // GPR[rt] (read_data_1) + offset // TODO Revisar

        i_instruction = {6'b100001, reg_base, reg_instr_rt, reg_offset};

        #(T*2);

        //! ADDU - Add Test: rd <- rs + rt
        // Inputs
        reg_instr_rs = 5'b00010;
        reg_instr_rt = 5'b00010;
        reg_instr_rd = 5'b01010;
        // reg[10] = 4

        i_instruction = {6'b000000, reg_instr_rs, reg_instr_rt, reg_instr_rd, 5'b00000, ADDU};

        #(T*2);

        //! SUBU - Sub Test: rd <- rs - rt
        // Inputs
        reg_instr_rs = 5'b01010;
        reg_instr_rt = 5'b00010;
        reg_instr_rd = 5'b00111;
        // reg[7] = 2

        i_instruction = {6'b000000, reg_instr_rs, reg_instr_rt, reg_instr_rd, 5'b00000, SUBU};

        #(T*2);

        //! AND - And Test: rd <- rs & rt
        // Inputs
        reg_instr_rs = 5'b00010;
        reg_instr_rt = 5'b00010;
        reg_instr_rd = 5'b01111;
        // reg[15] = 2

        i_instruction = {6'b000000, reg_instr_rs, reg_instr_rt, reg_instr_rd, 5'b00000, AND};

        #(T*2);

        //! ORI - Or Test: rt <- rs | imm
        // Inputs
        reg_instr_rs = 5'b0000;
        reg_immediate = 16'h0002;
        reg_instr_rt = 5'b11011;
        // reg[27] = 2

        i_instruction = {6'b001101, reg_instr_rs, reg_instr_rt, reg_immediate};

        #(T*2);

        //! Add To Test BEQ - 8th Inst (32'h20)
        // Inputs
        reg_instr_rs = 5'b00111;
        reg_immediate = 16'h0002;
        reg_instr_rt = 5'b00111;
        // reg[7] += 2 = 4 

        i_instruction = {6'b001000, reg_instr_rs, reg_instr_rt, reg_immediate};
        
        #(T*2);

        //! BEQ - Branch Test: rt <- rs | imm - 9th Inst
        // Inputs
        reg_instr_rs = 5'b01111;
        reg_offset = 16'h0003; 
        reg_instr_rt = 5'b11011;
        // if reg[27] == reg[15] -> branch to 11th (NPC + offset = NPC + 1 = 10th + 1)

        i_instruction = {6'b000100, reg_instr_rs, reg_instr_rt, reg_offset};

        #(T*2);

        //! Add To Test BEQ - 10th Inst (32'h28)
        // Inputs
        reg_instr_rs = 5'b00111;
        reg_immediate = 16'h0002;
        reg_instr_rt = 5'b00111;
        // reg[7] += 2 = -> 6 

        i_instruction = {6'b001000, reg_instr_rs, reg_instr_rt, reg_immediate};
        
        #(T*2);

        //! Add To Test BEQ - 11th Inst (32'h2C)
        // Inputs
        reg_instr_rs = 5'b00111;
        reg_immediate = 16'h0002;
        reg_instr_rt = 5'b00111;
        // reg[7] += 2 -> if BEQ 6 , else 8

        i_instruction = {6'b001000, reg_instr_rs, reg_instr_rt, reg_immediate};

        #(T*2);

        //! JAL - Jump Test: pc <- instr_index (JUMP TO 3Chex - Inst 15 (001111)) (GPR[31] <- PC+8 = 34h)
        // Inputs
        reg_instr_index = 26'h34; 
        // Jump to 14th Inst (PC = 38hex)
        
        i_instruction = {6'b000011, reg_instr_index};

        #(T*2);

        //! Add To Test J (13th Inst - 32'h34)
        // Inputs
        reg_instr_rs = 5'b00111;
        reg_immediate = 16'h0002;
        reg_instr_rt = 5'b00111;
        // reg[7] += 2 -> if J 6, else 8

        i_instruction = {6'b001000, reg_instr_rs, reg_instr_rt, reg_immediate};

        #(T*2);

        //! Add To Test J (14th Inst - 32'h38)
        // Inputs
        reg_instr_rs = 5'b00111;
        reg_immediate = 16'h0002;
        reg_instr_rt = 5'b00111;
        // reg[7] += 2 -> if J 6, else 10

        i_instruction = {6'b001000, reg_instr_rs, reg_instr_rt, reg_immediate};

        #(T*2);

        //! Add To Test J (15th Inst - 32'h3C)
        // Inputs
        reg_instr_rs = 5'b00111;
        reg_immediate = 16'h0002;
        reg_instr_rt = 5'b00111;
        // reg[7] += 2 -> if J 6, else 12

        i_instruction = {6'b001000, reg_instr_rs, reg_instr_rt, reg_immediate};

        #(T*2);

        //! HALT 
        i_instruction = 32'b000000_00000_00000_00000_111111;
        
        #(T*2);
        
        $display("LOADING PROGRAM...");

        i_write = 1'b0;
        i_instruction = {INST_SZ{1'b0}};
        #100;
        i_enable = 1'b1;
        
        $display("RUNNING...");

        // Wait for HALT
        @(posedge o_halt);
        
        $display("PROGRAM FINISHED.");
        i_enable = 1'b0;

        $display("\nDisplaying Memory Data:");
        for(i = 0; i < 5**2; i = i + 1)
        begin
            i_debug_addr = i; // Address
            #(T*2);
            $display("DEBUG DATA: %d from %b", o_mem, i_debug_addr[MEM_SZ-1:0]);
        end

        $display("\nDisplaying Registers:");
        for(i = 0; i < 32; i = i + 1)
        begin
            i_debug_addr = i; // Address
            #(T*2);
            $display("DEBUG REGS: %d from %b (%d)", o_reg, i_debug_addr[4:0], i_debug_addr[4:0]);
        end

        $display("\nTESTS PASSED!");
        
        $stop;
    end

endmodule
