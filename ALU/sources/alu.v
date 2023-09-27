/**
    Arithmetic-Logic Unit
    ALU parametrizable que realiza las siguientes operaciones
        1. ADD  : 100000
        2. SUB  : 100010
        3. AND  : 100100
        4. OR   : 100101
        5. XOR  : 100110
        6. SRA  : 000011
        7. SRL  : 000010
        8. NOR  : 100111

    Para instanciarla y sobreescribir el parametro por defecto:
        alu #(.N(5), .NSel(6)) uut (
            .i_clock(clk),
            .i_alu_A(o_alu_A),
            .i_alu_B(o_alu_B),
            .i_alu_Op(o_alu_Op),
            .o_alu_Result(o_alu_Result)
        );
**/

module alu
    #(
        // Parameters
        parameter N = 4,                                // ALU Size
        parameter NSel = 6                              // ALU Op Size
    )
    (
        // Inputs
        input [N-1 : 0]        i_alu_A, i_alu_B,       // ALU Operands 
        input [NSel-1 : 0]     i_alu_Op,               // ALU Operation
        // Outputs
        output wire [N-1 : 0]    o_alu_Result           // ALU Result
    );

    // Operation parameters
    localparam ADD = 6'b100000;     // Add Word - If overflow, then trap
    localparam SUB = 6'b100010;     // Subtract Word - If overflow, then trap
    localparam AND = 6'b100100;     // Logical bitwise AND 
    localparam OR  = 6'b100101;     // Logical bitwise OR
    localparam XOR = 6'b100110;     // Logical bitwise XOR
    localparam SRA = 6'b000011;     // Shift Word Right Arithmetic
    localparam SRL = 6'b000010;     // Shift Word Right Logic
    localparam NOR = 6'b100111;     // Logical bitwise NOR 

    // Register aux
    reg [N-1 : 0]    alu_Result;          // ALU Result
    assign o_alu_Result = alu_Result;

    // Body
    always @(*)
    begin
        //! Make Operation depending on ALU Op
        case(i_alu_Op)
            ADD     : 
            begin
                alu_Result = $signed(i_alu_A) + $signed(i_alu_B);
                //! Flag Detection
                // Ovf = Operands of same sign and result of different sign
                //overflow_Flag = ((i_alu_A[N-1] & i_alu_B[N-1] & ~o_alu_Result[N-1]) | (~i_alu_A[N-1] & ~i_alu_B[N-1] & o_alu_Result[N-1]));
            end
            SUB     : 
            begin
                alu_Result = $signed(i_alu_A) - $signed(i_alu_B);
                //! Flag Detection
                // Ovf = Operands of different sign and result of same sign as B (substraend)
                //overflow_Flag = ((~i_alu_A[N-1] & i_alu_B[N-1] & o_alu_Result[N-1])) | ((i_alu_A[N-1] & ~i_alu_B[N-1] & ~o_alu_Result[N-1]));
                //zero_Flag = (o_alu_Result == 0);
            end
            AND     : alu_Result = i_alu_A & i_alu_B;
            OR      : alu_Result = i_alu_A | i_alu_B;
            XOR     : alu_Result = i_alu_A ^ i_alu_B;
            SRA     : alu_Result = $signed(i_alu_A) >>> i_alu_B;
            SRL     : alu_Result = i_alu_A >> i_alu_B;
            NOR     : alu_Result = ~ (i_alu_A | i_alu_B);
            default : 
            begin
                alu_Result = {N {1'b0}};
            end
        endcase
    end

endmodule
