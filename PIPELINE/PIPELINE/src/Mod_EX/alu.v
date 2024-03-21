module alu
    #(
        // Parameters
        parameter N = 32,                               // ALU Size
        parameter ALU_OP = 3,
        parameter NSel = 6                              // ALU Op Size
    )
    (
        // Inputs
        input [N-1 : 0]        i_alu_A, i_alu_B,       // ALU Operands 
        input [4 : 0]          i_shamt,
        input [NSel-1 : 0]     i_alu_Op,               // ALU Operation
        input [ALU_OP-1 : 0]   i_alu_op_MC,            // ALUOp Control Line
        // Outputs
        output wire [N-1 : 0]    o_alu_Result          // ALU Result
    );

    // Operation parameters
    localparam ADD  =       6'b100000;      // Add Word 
    localparam SUB  =       6'b100010;      // Subtract Word 
    localparam AND  =       6'b100100;      // Logical bitwise AND 
    localparam ADDU =       6'b100001;      // Add Word Unsigned
    localparam SUBU =       6'b100011;      // Subtract Word Unsigned
    localparam OR   =       6'b100101;      // Logical bitwise OR
    localparam XOR  =       6'b100110;      // Logical bitwise XOR
    localparam NOR  =       6'b100111;      // Logical bitwise NOR
    localparam SRA  =       6'b000011;      // Shift Word Right Arithmetic
    localparam SRL  =       6'b000010;      // Shift Word Right Logic
    localparam SLL  =       6'b000000;      // Shift Word Left Logic
    localparam SLLV =       6'b000100;      // Shift Word Left Logic Variable
    localparam SRLV =       6'b000110;      // Shift Word Right Logic Variable
    localparam SRAV =       6'b000111;      // Shift Word Right Arithmetic Variable
    localparam SLT  =       6'b101010;      // Set on Less Than
    localparam LUI  =       6'b110110;      // Load Upper Immediate

    localparam I_TYPE_ANDI  =   3'b001;         // ANDI
    localparam I_TYPE_ORI   =   3'b011;         // ORI
    localparam I_TYPE_XORI  =   3'b100;         // XORI
    localparam I_TYPE_LUI   =   3'b101;         // LUI

    // Register aux
    reg [N-1 : 0]    alu_Result;          // ALU Result
    assign o_alu_Result = alu_Result;

    wire [N-1 : 0] ext_shamt;
    assign ext_shamt = {{N-5{1'b0}}, i_shamt}; 

    wire [N-1 : 0] zero_ext_imm;
    assign zero_ext_imm = {{N-16{1'b0}}, i_alu_B[15:0]};

    reg [N-1 : 0] alu_b; // Input to ALU operation

    // Select alu_b based on the control signal i_alu_op_MC
    always @(*) //TODO Revisar si esto esta bien o es mejor hacer un modulo de control
    begin
        case(i_alu_op_MC)
            I_TYPE_ANDI, I_TYPE_ORI, I_TYPE_XORI, I_TYPE_LUI: alu_b = zero_ext_imm;
            default: alu_b = i_alu_B;
        endcase
    end

    // Make Operation depending on ALU Op
    always @(*)
    begin
        case(i_alu_Op)
            ADD     : alu_Result = $signed(i_alu_A) + $signed(alu_b);
            SUB     : alu_Result = $signed(i_alu_A) - $signed(alu_b);
            ADDU    : alu_Result = i_alu_A + alu_b;
            SUBU    : alu_Result = i_alu_A - alu_b;
            AND     : alu_Result = i_alu_A & alu_b;
            OR      : alu_Result = i_alu_A | alu_b;
            XOR     : alu_Result = i_alu_A ^ alu_b;
            SRA     : alu_Result = $signed(alu_b) >>> ext_shamt;
            SRL     : alu_Result = alu_b >> ext_shamt;
            NOR     : alu_Result = ~ (i_alu_A | alu_b);
            SLL     : alu_Result = alu_b << ext_shamt;
            SLLV    : alu_Result = alu_b << i_alu_A;
            SRLV    : alu_Result = alu_b >> i_alu_A;
            SRAV    : alu_Result = $signed(alu_b) >>> i_alu_A;
            SLT     : alu_Result = $signed(i_alu_A) < $signed(alu_b);
            LUI     : alu_Result = {alu_b[N-1], alu_b[14:0], 16'h0000};
            default : alu_Result = {N {1'b0}};
        endcase
    end

endmodule
