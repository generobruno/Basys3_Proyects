`timescale 1ns/1ps

module AluControl_tb();
    // Parameters
    parameter ALU_OP    = 3;
    parameter FUNCT     = 6;
    parameter INST_SZ   = 32;

    // Operation parameters
    localparam SLL      = 32'b000000_00000_00000_00000_00000_000000;
    localparam ADDU     = 32'b000000_00001_00010_00011_00000_100001;
    localparam LW       = 32'b100011_00001_00010_0000000000000000;
    localparam SW       = 32'b101011_00001_00010_0000000000000000;
    localparam ADDI     = 32'b001000_00001_00010_0000000000000000;
    localparam ANDI     = 32'b000100_00001_00010_0000000000000000;
    localparam ORI      = 32'b000101_00001_00010_0000000000000000;
    localparam XORI     = 32'b001110_00001_00010_0000000000000000;
    localparam LUI      = 32'b001111_00000_00010_0000000000000000;
    localparam SLTI     = 32'b001010_00001_00010_0000000000000000;
    localparam JR       = 32'b000000_00001_000000000000000_001000;
    localparam JALR     = 32'b000000_00001_00000_00000_001001;

    // Declarations
    reg [INST_SZ-1 : 0] i_instruction_ID_EX;
    reg [ALU_OP-1 : 0] alu_op_MC;
    wire [INST_SZ-1 : 0] instr_imm_D;
    wire [FUNCT-1 : 0] alu_sel;

    assign instr_imm_D = {{INST_SZ-16{i_instruction_ID_EX[15]}}, i_instruction_ID_EX[15:0]};

    // Instantiations
    AluControl #(.ALU_OP(), .FUNCT()) alu_control 
        (.i_instr_funct_E(instr_imm_D[5:0]), 
        .i_alu_op_MC(alu_op_MC),
        .o_alu_sel_AC(alu_sel));
    
    // Task
    initial 
    begin
        // Shift Instrucion
        i_instruction_ID_EX = SLL;
        alu_op_MC = 3'b010;
        #10;
        // 3-Operand ALU Instrucion
        i_instruction_ID_EX = ADDU;
        alu_op_MC = 3'b010;
        #10;
        // Normal CPU Load Instrucion
        i_instruction_ID_EX = LW;
        alu_op_MC = 3'b000;
        #10;    
        // Normal CPU Store Instrucion
        i_instruction_ID_EX = SW;
        alu_op_MC = 3'b000;
        #10;    
        // ALU with imm Instrucions
        i_instruction_ID_EX = ADDI;
        alu_op_MC = 3'b000;
        #10;    
        i_instruction_ID_EX = ANDI;
        alu_op_MC = 3'b001;
        #10;    
        i_instruction_ID_EX = ORI;
        alu_op_MC = 3'b011;
        #10;
        i_instruction_ID_EX = XORI;
        alu_op_MC = 3'b100;
        #10;
        i_instruction_ID_EX = LUI;
        alu_op_MC = 3'b101;
        #10;
        i_instruction_ID_EX = SLTI;
        alu_op_MC = 3'b111;
        #10;
        i_instruction_ID_EX = JR;
        alu_op_MC = 3'b010;
        #10;
        i_instruction_ID_EX = JALR;
        alu_op_MC = 3'b010;
        #10;
        $finish;          
    end

    always @(*)
    begin
        $display("INSTRUCTION: %b \n instr_imm_D=%b, alu_op=%b --> alu_sel=%b \n", 
        i_instruction_ID_EX, instr_imm_D, alu_op_MC, alu_sel);
    end

endmodule