`timescale 1ns/1ps

module MainControlUnit_tb();
    // Parameters
    localparam INST_SZ = 32;
    localparam OPCODE_SZ = 6;
    localparam FUNCT_SZ = 6;

    // Operation parameters
    localparam SLL      = 32'b000000_00000_00000_00000_00000_000000;
    localparam ADDU     = 32'b000000_00001_00010_00011_00000_100001;
    localparam LW       = 32'b100011_00001_00010_0000000000000000;
    localparam LH       = 32'b100001_00001_00010_0000000000000000;
    localparam SW       = 32'b101011_00001_00010_0000000000000000;
    localparam ADDI     = 32'b001000_00001_00010_0000000000000000;
    localparam BEQ      = 32'b000100_00001_00010_0000000000000000;
    localparam BNE      = 32'b000101_00001_00010_0000000000000000;
    localparam J        = 32'b000010_00000000000000000000000000;
    localparam JAL      = 32'b000011_00000000000000000000000000;
    localparam JR       = 32'b000000_00001_000000000000000_001000;
    localparam JALR     = 32'b000000_00001_00000_00000_001001;
    localparam HALT     = 32'b000000_00000_00000_00000_111111;

    // Declarations
    reg [INST_SZ-1 : 0] i_instruction_IF_ID;
    wire [2:0] alu_op_MC;
    wire reg_dst_MC;
    wire jal_sel_MC;
    wire alu_src_MC;
    wire branch_MC;
    wire equal_MC;
    wire mem_read_MC;
    wire mem_write_MC;
    wire [1:0] bhw_MC;
    wire jump_MC;
    wire jump_sel_MC;
    wire reg_write_MC;
    wire bds_sel_MC;
    wire mem_to_reg_MC;
    wire halt_MC;

    // Instantiations
    MainControlUnit #(.OPCODE_SZ(OPCODE_SZ), .FUNCT_SZ(FUNCT_SZ)) MainControlUnit
        (
            // Inputs
            .i_instr_op_D(i_instruction_IF_ID[31 : 26]),
            .i_instr_funct_D(i_instruction_IF_ID[5 : 0]),
            // Output Control Lines
            .o_alu_op_MC(alu_op_MC),
            .o_reg_dst_MC(reg_dst_MC),
            .o_jal_sel_MC(jal_sel_MC),
            .o_alu_src_MC(alu_src_MC),
            .o_branch_MC(branch_MC),
            .o_equal_MC(equal_MC),
            .o_mem_read_MC(mem_read_MC),
            .o_mem_write_MC(mem_write_MC),
            .o_bhw_MC(bhw_MC),
            .o_jump_MC(jump_MC),
            .o_jump_sel_MC(jump_sel_MC),
            .o_reg_write_MC(reg_write_MC),
            .o_bds_sel_MC(bds_sel_MC),
            .o_mem_to_reg_MC(mem_to_reg_MC),
            .o_halt_MC(halt_MC)
        );
    
    // Task
    initial 
    begin
        #10;
        // Shift Instrucion
        i_instruction_IF_ID = SLL;
        #10;
        // 3-Operand ALU Instrucion
        i_instruction_IF_ID = ADDU;
        #10;
        // Normal CPU Load Instrucion
        i_instruction_IF_ID = LW;
        #10;    
        // Normal CPU Store Instrucion
        i_instruction_IF_ID = SW;
        #10;    
        // ALU with imm Instrucion
        i_instruction_IF_ID = ADDI;
        #10;    
        // BEQ Instrucion
        i_instruction_IF_ID = BEQ;
        #10;    
        // BNE Instrucion
        i_instruction_IF_ID = BNE;
        #10;    
        // J Instrucion
        i_instruction_IF_ID = J;
        #10;
        // JAL Instrucion
        i_instruction_IF_ID = JAL;
        #10;
        // JR Instrucions
        i_instruction_IF_ID = JR;
        #10;
        // JALR Instrucion
        i_instruction_IF_ID = JALR;
        #10;
        // HALT Instruction
        i_instruction_IF_ID = HALT;
        #10;
        // LH Instruction
        i_instruction_IF_ID = LH;
        #10;

        $finish;          
    end

    always @(*)
    begin
        $display("INSTRUCTION: %b \n reg_dst=%d, jal_sel=%d, alu_src=%d, alu_op=%b, branch=%d, equal=%d, mem_read=%d, mem_write=%d, bhw=%d, jump=%d, jump_sel=%d, reg_write=%d, bds_sel=%d, mem_to_reg=%d, halt=%d", 
        i_instruction_IF_ID, reg_dst_MC, jal_sel_MC, alu_src_MC, alu_op_MC, branch_MC, equal_MC, mem_read_MC, mem_write_MC, bhw_MC, jump_MC, jump_sel_MC, reg_write_MC, bds_sel_MC, mem_to_reg_MC, halt_MC);
    end

endmodule