/**

**/

module IF
    #(
        // Parameters
        parameter INST_SZ   = 32,
        parameter PC_SZ     = 32,
        parameter MEM_SZ    = 10
    )
    (
        // Inputs
        input                           i_clk,                      // Clock
        input                           i_reset,                    // Reset
        input                           i_write,                    // Write Memory Control Line
        input                           i_enable,                   // Enable Execution
        input [INST_SZ-1 : 0]           i_instruction_F,            // Saved Instruction
        input [INST_SZ-1 : 0]           i_branch_addr_D,            // Branch Address
        input [INST_SZ-1 : 0]           i_jump_addr_D,              // Jump Address
        input [INST_SZ-1 : 0]           i_rs_addr_D,                // GPR[rs] Address
        input                           i_pc_src_D,                 // PCSrc Control Line
        input                           i_jump_D,                   // Jump Control Line
        input                           i_jump_sel_D,               // JumpSel Control Line
        input                           i_stall_pc_HD,              // StallPC Control Line
        // Outputs
        output [INST_SZ-1 : 0]          o_pc,                       // PC Out
        output [INST_SZ-1 : 0]          o_npc_F,                    // NPC
        output [INST_SZ-1 : 0]          o_branch_delay_slot_F,      // Branch Delay Slot
        output [INST_SZ-1 : 0]          o_instruction_F             // Instruction Fetched
    );

    //! Signal Declaration
    wire [INST_SZ-1 : 0] o_pc_src_mpx;
    wire [INST_SZ-1 : 0] o_jump_mpx;
    wire [INST_SZ-1 : 0] o_jump_sel_mpx;
    wire [INST_SZ-1 : 0] instr_addr;

    //! Instantiations
    mpx_2to1 #(.N(INST_SZ)) pc_src_mpx
        (.input_a(o_npc_F), .input_b(i_branch_addr_D), // TODO Revisar
        .i_select(i_pc_src_D),
        .o_output(o_pc_src_mpx));

    mpx_2to1 #(.N(INST_SZ)) jump_mpx
        (.input_a(o_pc_src_mpx), .input_b(i_jump_addr_D>>2), //TODO REVISAR
        .i_select(i_jump_D),
        .o_output(o_jump_mpx));

    mpx_2to1 #(.N(INST_SZ)) jump_sel_mpx
        (.input_a(o_jump_mpx), .input_b((i_rs_addr_D & ~2'b11)), // Naturally-aligned GPR[rs]
        .i_select(i_jump_sel_D),
        .o_output(o_jump_sel_mpx));

    pc #(.PC_SZ(PC_SZ)) prog_counter
        (.i_clk(i_clk), .i_reset(i_reset), .i_enable(i_stall_pc_HD & i_enable),
        .i_pc(o_jump_sel_mpx), 
        .o_pc(instr_addr));

    pc_adder #(.PC_SZ(PC_SZ)) pc_adder
        (.i_pc(instr_addr),
        .o_pc(o_npc_F), .o_bds(o_branch_delay_slot_F));

    instruction_mem #(.B(INST_SZ), .W(MEM_SZ), .PC(PC_SZ)) inst_mem
        (.i_clk(i_clk), .i_reset(i_reset),
        .i_write(i_write & ~i_enable), 
        .i_addr(instr_addr), .i_data(i_instruction_F), 
        .o_data(o_instruction_F));

    //! Assignments
    assign o_pc = instr_addr;

endmodule