/**

**/

module EX
    #(
        // Parameters
        parameter INST_SZ = 32,
        parameter ALU_OP = 3,
        parameter FORW_ALU = 2,
        parameter ALU_SEL = 6
    )
    (
        // Inputs
        input [INST_SZ-1 : 0]           i_read_data_1_E,            // Read Data 1 (from reg mem)
        input [INST_SZ-1 : 0]           i_read_data_2_E,            // Read Data 2 (from reg mem)
        input [INST_SZ-1 : 0]           i_alu_result_M,             // Previous ALU Result (for Forwarding)
        input [INST_SZ-1 : 0]           i_read_data_W,              // Read Data (for Forwarding, from data mem)
        input                           i_alu_src_MC,               // ALUSrc Control Line
        input                           i_reg_dst_MC,               // RegDst Control Line
        input                           i_jal_sel_MC,               // JalSel Control Line
        input [ALU_OP-1 : 0]            i_alu_op_MC,                // ALUOp Control Line
        input [FORW_ALU-1 : 0]          i_forward_a_FU,             // Forwarding A Control Line
        input [FORW_ALU-1 : 0]          i_forward_b_FU,             // Forwarding B Control Line
        input [INST_SZ-1 : 0]           i_instr_imm_D,              // Instruction Immediate (instr[15:0] sign-extended)
        input [4 : 0]                   i_instr_rt_D,               // Instruction RT (instr[20:16])
        input [4 : 0]                   i_instr_rd_D,               // Instruction RD (instr[15:11])

        // Outputs
        output [INST_SZ-1 : 0]          o_alu_result_E,             // ALU Result
        output [INST_SZ-1 : 0]          o_operand_b_E,              // Operand B (for Write Data)
        output [4 : 0]                  o_instr_rd_E                // Instruction RD (for Write Register)
    );

    //! Signal Declaration
    wire [INST_SZ-1 : 0]                alu_a;
    wire [INST_SZ-1 : 0]                alu_b;
    wire [ALU_SEL-1 : 0]                alu_sel;
    wire [4 : 0]                        o_reg_dst_mpx;

    //! Instantiations
    mpx_2to1 #(.N(5)) reg_dst_mpx
        (.input_a(i_instr_rt_D), .input_b(i_instr_rd_D),
        .i_select(i_reg_dst_MC),
        .o_output(o_reg_dst_mpx)); 

    mpx_2to1 #(.N(5)) jal_sel_mpx
        (.input_a(o_reg_dst_mpx), .input_b(5'h1F), // Reg 31
        .i_select(i_jal_sel_MC),
        .o_output(o_instr_rd_E));

    mpx_3to1 #(.N(INST_SZ)) forward_a_mpx
        (.input_a(i_read_data_1_E), .input_b(i_read_data_W), .input_c(i_alu_result_M),
        .i_select(i_forward_a_FU),
        .o_output(alu_a));

    // TODO SXL/SXLV MPX -> su salida reemplazaria a "i_read_data_2_E" en forward_b_mpx -> Creo que no hace falta xq le meti otra entrada a la alu directamente como un desgraciado
    
    mpx_3to1 #(.N(INST_SZ)) forward_b_mpx
        (.input_a(i_read_data_2_E), .input_b(i_read_data_W), .input_c(i_alu_result_M),
        .i_select(i_forward_b_FU),
        .o_output(o_operand_b_E));
    
    mpx_2to1 #(.N(INST_SZ)) alu_src_mpx
        (.input_a(o_operand_b_E), .input_b(i_instr_imm_D),
        .i_select(i_alu_src_MC),
        .o_output(alu_b));
    
    AluControl #(.ALU_OP(), .FUNCT()) alu_control 
        (.i_instr_funct_E(i_instr_imm_D[5:0]),
        .i_alu_op_MC(i_alu_op_MC),
        .o_alu_sel_AC(alu_sel));

    alu #(.N(INST_SZ), .NSel(ALU_SEL)) alu
        (.i_alu_A(alu_a), .i_alu_B(alu_b), .i_shamt(i_instr_imm_D[10:6]),
        .i_alu_Op(alu_sel), .i_alu_op_MC(i_alu_op_MC),
        .o_alu_Result(o_alu_result_E));   

endmodule