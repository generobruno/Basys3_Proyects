/**

**/

module pc_adder
    #(
        // Parameters
        parameter   PC_SZ   =   32      // Number of bits
    )
    (
        // Inputs
        input wire [PC_SZ-1 : 0]        i_pc,                       // Input PC
        // Outputs
        output wire [PC_SZ-1 : 0]       o_pc,                       // Output PC
        output wire [PC_SZ-1 : 0]       o_bds                       // Branch Delay Slot
    );

    //! Signal Declaration
    reg [PC_SZ-1 : 0]               prog_counter;
    reg [PC_SZ-1 : 0]               branch_delay_slot;

    // Body
    always @(*) 
    begin
        prog_counter = i_pc + 4;
        branch_delay_slot = i_pc + 8;
    end

    //! Assignments
    assign o_pc = prog_counter;
    assign o_bds = branch_delay_slot;

endmodule