/**

**/

module pc
    #(
        // Parameters
        parameter PC_SZ = 32
    )
    (
        // Inputs
        input wire                      i_clk,                      // Clock
        input wire                      i_reset,                    // Reset
        input wire                      i_enable,                   // Enable
        input [PC_SZ-1 : 0]             i_pc,                       // New PC
        // Outputs
        output [PC_SZ-1 : 0]            o_pc                        // Output PC
    );

    //! Signal Declaration
    reg [PC_SZ-1 : 0]               prog_counter;

    // Body
    always @(posedge i_clk) 
    begin
        if(i_reset)
        begin
            prog_counter <= 0;
        end
        else if(i_enable)
        begin
            prog_counter <= i_pc;
        end    
    end

    initial 
    begin
        prog_counter <= 0;    
    end

    //! Assignments
    assign o_pc = prog_counter;

endmodule