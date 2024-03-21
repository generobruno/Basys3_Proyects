/**

**/

module ID
    #(
        // Parameters
        parameter INST_SZ = 32,
        parameter REG_SZ = 5,
        parameter FORW_EQ = 1,
        parameter OPCODE_SZ = 6,
        parameter FUNCT_SZ = 6
    )
    (
        // Inputs
        input                           i_clk,                      // Clock
        input                           i_reset,                    // Reset
        input [INST_SZ-1 : 0]           i_instruction_D,            // Instruction Fetched
        input [INST_SZ-1 : 0]           i_npc_D,                    // NPC
        input                           i_forward_eq_a_FU,          // Forwarding Eq A Control Line
        input                           i_forward_eq_b_FU,          // Forwarding Eq B Control Line
        input [INST_SZ-1 : 0]           i_alu_result_M,             // Previous ALU Result (for Eq Forward)
        input                           i_branch_MC,                // Branch Control Line
        input                           i_equal_MC,                 // Equal Control Line
        input                           i_reg_write_W,              // RegWrite Control Line
        input [REG_SZ-1 : 0]            i_write_register_D,         // Write Register
        input [INST_SZ-1 : 0]           i_write_data_D,             // Write Data
        input [REG_SZ-1 : 0]            i_debug_addr,               // Debug Address 
        // Outputs
        output [INST_SZ-1 : 0]          o_reg,                      // Debug Register
        output [INST_SZ-1 : 0]          o_jump_addr_D,              // Jump Address
        output [INST_SZ-1 : 0]          o_branch_addr_D,            // Branch Address
        output [INST_SZ-1 : 0]          o_read_data_1_D,            // Read Data 1 (from reg mem)
        output [INST_SZ-1 : 0]          o_read_data_2_D,            // Read Data 2 (from reg mem)
        output                          o_pc_src_D,                 // PCSrc Control Line
        output [INST_SZ-1 : 0]          o_instr_imm_D,              // Instruction Immediate (instr[15:0])
        output [4 : 0]                  o_instr_rs_D,               // Instruction RS (instr[25:21]) 
        output [4 : 0]                  o_instr_rt_D,               // Instruction RT (instr[20:16])
        output [4 : 0]                  o_instr_rd_D,               // Instruction RD (instr[15:11])
        output [2 : 0]                  o_alu_op_MC,                // ALUOp Control Line
        output                          o_reg_dst_MC,               // RegDst Control Line
        output                          o_jal_sel_MC,               // JALSel Control Line
        output                          o_alu_src_MC,               // ALUSrc Control Line
        output                          o_branch_MC,                // Branch Control Line
        output                          o_equal_MC,                 // Equal Control Line
        output                          o_mem_read_MC,              // MemRead Control Line
        output                          o_mem_write_MC,             // MemWrite Control Line
        output [2 : 0]                  o_bhw_MC,                   // Memory Size Control Line
        output                          o_jump_MC,                  // Jump Control Line
        output                          o_jump_sel_MC,              // JumpSel Control Line
        output                          o_reg_write_MC,             // RegWrite Control Line
        output                          o_bds_sel_MC,               // BDSSel Control Line
        output                          o_mem_to_reg_MC,            // MemToReg Control Line
        output                          o_halt_MC                   // Halt Control Line
    );

    //! Signal Declaration
    wire xnor_result;
    wire comparison;
    wire [INST_SZ-1:0] extended_imm;
    wire [INST_SZ-1:0] shifted_imm;
    wire [INST_SZ-1:0] read_data_1;
    wire [INST_SZ-1:0] read_data_2;

    //! Instantiations
    mpx_2to1 #(.N(INST_SZ)) forw_eq_a_mpx
        (.input_a(o_read_data_1_D), .input_b(i_alu_result_M),
        .i_select(i_forward_eq_a_FU),
        .o_output(read_data_1));

    mpx_2to1 #(.N(INST_SZ)) forw_eq_b_mpx
        (.input_a(o_read_data_2_D), .input_b(i_alu_result_M),
        .i_select(i_forward_eq_b_FU),
        .o_output(read_data_2));

    comparator #(.INST_SZ(INST_SZ)) comparator
        (.i_read_data_1(read_data_1),
        .i_read_data_2(read_data_2),
        .o_comparison(comparison));

    register_mem #(.B(INST_SZ), .W(REG_SZ)) register_mem
        (.i_clk(i_clk), .i_reset(i_reset),
        .i_reg_write_MC(i_reg_write_W), .i_debug_addr(i_debug_addr),
        .i_read_reg_1(i_instruction_D[25 : 21]), .i_read_reg_2(i_instruction_D[20 : 16]),
        .i_write_register(i_write_register_D), .i_write_data(i_write_data_D),
        .o_read_data_1(o_read_data_1_D), .o_read_data_2(o_read_data_2_D), .o_reg(o_reg));

    //  Main Control Unit
    MainControlUnit #(.OPCODE_SZ(OPCODE_SZ), .FUNCT_SZ(FUNCT_SZ)) MainControlUnit
        (
            // Inputs
            .i_instr_op_D(i_instruction_D[31 : 26]),
            .i_instr_funct_D(i_instruction_D[5 : 0]),
            // Output Control Lines
            .o_alu_op_MC(o_alu_op_MC),
            .o_reg_dst_MC(o_reg_dst_MC),
            .o_jal_sel_MC(o_jal_sel_MC),
            .o_alu_src_MC(o_alu_src_MC),
            .o_branch_MC(o_branch_MC),
            .o_equal_MC(o_equal_MC),
            .o_mem_read_MC(o_mem_read_MC),
            .o_mem_write_MC(o_mem_write_MC),
            .o_bhw_MC(o_bhw_MC),
            .o_jump_MC(o_jump_MC),
            .o_jump_sel_MC(o_jump_sel_MC),
            .o_reg_write_MC(o_reg_write_MC),
            .o_bds_sel_MC(o_bds_sel_MC),
            .o_mem_to_reg_MC(o_mem_to_reg_MC),
            .o_halt_MC(o_halt_MC)
        );

    //! Assignments
    // Shift instruction index to get jump address
    assign o_jump_addr_D = {i_npc_D[31:28], {i_instruction_D[25 : 0]}, {2{1'b0}}};

    // Decide if branch or not
    assign xnor_result = ~(comparison ^ i_equal_MC);
    assign o_pc_src_D = xnor_result & i_branch_MC;

    // Sign extension of o_instr_imm_D to INST_SZ length
    assign extended_imm = {{INST_SZ-16{i_instruction_D[15]}}, i_instruction_D[15:0]};
    assign o_instr_imm_D        =      extended_imm; 

    // Left shift extended immediate by 2 bits
    assign shifted_imm = extended_imm << 2;
    // Adding shifted immediate to i_npc_D to get o_branch_addr_D
    assign o_branch_addr_D      =      i_npc_D + shifted_imm;

    assign o_instr_rs_D         =      i_instruction_D[25 : 21]; 
    assign o_instr_rt_D         =      i_instruction_D[20 : 16]; 
    assign o_instr_rd_D         =      i_instruction_D[15 : 11]; 

endmodule