/**

**/

module HazardDetectionUnit
    #(
        // Parameters
        parameter       INPUT_SZ = 5
    )
    (
        // Inputs
        input                           i_mem_to_reg_M,             // MemToReg from MEM
        input                           i_mem_read_E,               // MemRead from EX
        input                           i_reg_write_E,              // RegWrite from EX
        input                           i_branch_D,                 // Branch from ID
        input [INPUT_SZ-1 : 0]          i_instr_rs_D,               // Instruction RS from ID
        input [INPUT_SZ-1 : 0]          i_instr_rt_D,               // Instruction RT from ID
        input [INPUT_SZ-1 : 0]          i_instr_rt_E,               // Instruction RT from EX
        input [INPUT_SZ-1 : 0]          i_instr_rd_E,               // Instruction RD from EX
        input [INPUT_SZ-1 : 0]          i_instr_rd_M,               // Instruction RD from MEM
        // Outputs
        output                          o_stall_pc_HD,              // Stall PC Control Line
        output                          o_stall_if_id_HD,           // Stall_IF/ID Control Line
        output                          o_flush_id_ex_HD            // Flush_ID/EX Control Line
    );

    //! Signal Declaration
    reg stall_pc;
    reg stall_if_id;
    reg flush_id_ex;

    // Body    
    always @(*) 
    begin
        if(i_mem_read_E & ((i_instr_rt_E == i_instr_rs_D) | (i_instr_rt_E == i_instr_rt_D))) 
            begin
                // Load Stall 
                stall_pc    = 1'b1;
                stall_if_id = 1'b1;
                flush_id_ex = 1'b1;
            end
        else if((i_branch_D & i_reg_write_E & ((i_instr_rd_E == i_instr_rs_D) | (i_instr_rd_E == i_instr_rt_D))) 
                | (i_branch_D & i_mem_to_reg_M & ((i_instr_rd_M == i_instr_rs_D) | (i_instr_rd_M == i_instr_rt_D)))) 
            begin
                // Branch Stall
                stall_pc    = 1'b1;
                stall_if_id = 1'b1;
                flush_id_ex = 1'b1;
            end
        else 
            begin
                // No stall
                stall_pc    = 1'b0;
                stall_if_id = 1'b0;
                flush_id_ex = 1'b0;
            end
    end

    //! Assignments
    assign o_stall_pc_HD    =   stall_pc;
    assign o_stall_if_id_HD =   stall_if_id;
    assign o_flush_id_ex_HD =   flush_id_ex;

endmodule