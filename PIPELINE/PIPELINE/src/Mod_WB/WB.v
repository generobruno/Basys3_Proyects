/**

**/

module WB
    #(
        // Parameters
        parameter INST_SZ = 32
    )
    (
        // Inputs
        input [INST_SZ-1 : 0]           i_alu_result_M,             // ALU Result
        input [INST_SZ-1 : 0]           i_read_data_M,              // Read Data (from data mem)
        input [INST_SZ-1 : 0]           i_branch_delay_slot_M,      // Branch Delay Slot
        input                           i_mem_to_reg_W,             // MemToReg Control Line
        input                           i_bds_sel_W,                // BDSSel Control Line
        // Outputs
        output [INST_SZ-1 : 0]          o_write_data_W              // Write Data
    );

    //! Signal Declaration
    wire [INST_SZ-1 : 0]    mem_to_reg;

    //! Instantiations
    mpx_2to1 #(.N(INST_SZ)) mem_to_reg_mpx
        (.input_a(i_alu_result_M), .input_b(i_read_data_M),
        .i_select(i_mem_to_reg_W),
        .o_output(mem_to_reg));
        
    mpx_2to1 #(.N(INST_SZ)) bds_sel_mpx
        (.input_a(mem_to_reg), .input_b(i_branch_delay_slot_M),
        .i_select(i_bds_sel_W),
        .o_output(o_write_data_W));

endmodule