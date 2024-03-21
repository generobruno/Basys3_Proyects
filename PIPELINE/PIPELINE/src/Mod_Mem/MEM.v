/**

**/

module MEM
    #(
        // Parameters
        parameter INST_SZ = 32,
        parameter MEM_SZ  = 5
    )
    (
        // Inputs
        input                           i_clk,                      // Clock
        input [MEM_SZ-1 : 0]            i_debug_addr,               // Debug Memory Address
        input [INST_SZ-1 : 0]           i_alu_result_E,             // ALU Result
        input [INST_SZ-1 : 0]           i_operand_b_E,              // Operand B
        input                           i_mem_write_M,              // MemWrite Control Line
        input [2 : 0]                   i_bhw_M,                    // Memory Size Control Line
        // Outputs
        output [INST_SZ-1 : 0]          o_debug_mem,                // Data to send to debugger
        output [INST_SZ-1 : 0]          o_alu_result_M,             // ALU Result
        output [INST_SZ-1 : 0]          o_read_data_M               // Read Data (from data mem)
    );

    //! Instantiation
    data_mem #(.B(INST_SZ), .W(MEM_SZ)) data_mem
        (.i_clk(i_clk), 
        .i_mem_write(i_mem_write_M), .i_bhw(i_bhw_M),
        .i_addr(i_alu_result_E[MEM_SZ-1:0]), .i_debug_addr(i_debug_addr),
        .i_data(i_operand_b_E),
        .o_data(o_read_data_M), .o_debug_mem(o_debug_mem));
    
    //! Assignments
    assign o_alu_result_M           =   i_alu_result_E;

endmodule