/**

**/

module comparator
    #(
        // Parameters
        parameter INST_SZ   =   32
    )
    (
        // Inputs
        input wire [INST_SZ-1 : 0]      i_read_data_1,              // Read Data 1
        input wire [INST_SZ-1 : 0]      i_read_data_2,              // Read Data 2
        // Outputs
        output wire                     o_comparison                // Output PC
    );

    //! Signal Declaration
    reg result;

    // Body
    always @(*) 
    begin
        if(i_read_data_1 == i_read_data_2)
        begin
            result = 1;
        end
        else
        begin
            result = 0;
        end
    end

    //! Assignments
    assign o_comparison = result;

endmodule