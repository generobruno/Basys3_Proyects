/**

**/

module AluControl
    #(
        // Parameters
        parameter ALU_OP    = 3,
        parameter FUNCT     = 6,
        parameter INST_SZ   = 32
    )
    (
        // Inputs
        input [FUNCT-1 : 0]             i_instr_funct_E,            // Instruction Function
        input [ALU_OP-1 : 0]            i_alu_op_MC,                // ALUOp Control Line
        // Outputs
        output reg [FUNCT-1 : 0]        o_alu_sel_AC                // ALUSel Control Line
    );

    // ALU Operation parameters
    localparam ADD  =       6'b100000;      // Add Word 
    localparam AND  =       6'b100100;      // Logical bitwise AND 
    localparam OR   =       6'b100101;      // Logical bitwise OR
    localparam XOR  =       6'b100110;      // Logical bitwise XOR
    localparam SRA  =       6'b000011;      // Shift Word Right Arithmetic
    localparam SLT  =       6'b101010;      // Set on Less Than
    localparam LUI  =       6'b110110;      // Load Upper Immediate

    // ALUOp Parameters
    localparam R_TYPE       =   3'b010;         // R-Type Instruction
    localparam LOAD_STORE   =   3'b000;         // Load/Store Operation
    localparam I_TYPE_ANDI  =   3'b001;         // ANDI
    localparam I_TYPE_ORI   =   3'b011;         // ORI
    localparam I_TYPE_XORI  =   3'b100;         // XORI
    localparam I_TYPE_LUI   =   3'b101;         // LUI
    localparam I_TYPE_SLTI  =   3'b111;         // SLTI

    //! Select Desired ALU Operation
    always @(*) 
    begin
        case(i_alu_op_MC)
            R_TYPE:                         o_alu_sel_AC = i_instr_funct_E;
            LOAD_STORE:                     o_alu_sel_AC = ADD; // Also for ADDI
            I_TYPE_ANDI:                    o_alu_sel_AC = AND;
            I_TYPE_ORI:                     o_alu_sel_AC = OR;
            I_TYPE_XORI:                    o_alu_sel_AC = XOR;
            I_TYPE_LUI:                     o_alu_sel_AC = LUI; 
            I_TYPE_SLTI:                    o_alu_sel_AC = SLT;
            default:                        o_alu_sel_AC = ADD;
        endcase
    end

endmodule