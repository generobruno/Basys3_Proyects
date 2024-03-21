/**

**/

module mpx_3to1
    #(
        // Parameters
        parameter N     =   32
    )
    (   
        // Input 
        input wire [N-1 : 0]    input_a,        // Input 1
        input wire [N-1 : 0]    input_b,        // Input 2
        input wire [N-1 : 0]    input_c,        // Input 3
        input wire [1 : 0]      i_select,       // Control Line
        // Output
        output wire [N-1 : 0]   o_output        // Output Line 
    );

    // Parameters
    localparam A = 2'b00;
    localparam B = 2'b01;
    localparam C = 2'b10;

    reg [N-1 : 0] mpx_out;
    assign o_output = mpx_out;

    always @(*) 
    begin
        case(i_select)
            A:          mpx_out = input_a;
            B:          mpx_out = input_b;
            C:          mpx_out = input_c;
            default:    mpx_out = input_a;
        endcase
    end

endmodule