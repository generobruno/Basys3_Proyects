/**

**/

module pipeline
    #(
        // Parameters
        parameter INST_SZ       =   32,
        parameter PC_SZ         =   32,
        parameter OPCODE_SZ     =   6,
        parameter FUNCT_SZ      =   6,
        parameter REG_SZ        =   5,
        parameter MEM_SZ        =   10,
        parameter FORW_EQ       =   1,
        parameter FORW_ALU      =   2,
        parameter ALU_OP        =   3,
        parameter ALU_SEL       =   6,
        parameter FUNCT         =   6
    )
    (
        // Inputs
        input                           i_clk,                      // Clock
        input                           i_reset,                    // Reset
        input                           i_write,                    // Write Memory Control Line
        input                           i_enable,                   // Enable Execution
        input [INST_SZ-1 : 0]           i_instruction,              // Saved Instruction
        input [REG_SZ-1 : 0]            i_debug_addr,               // Debug Memory Address
        // Outputs
        output [PC_SZ-1 : 0]            o_pc,                       // Output PC
        output [INST_SZ-1 : 0]          o_mem,                      // Output Memory
        output [INST_SZ-1 : 0]          o_reg,                      // Output Register
        output                          o_halt                      // Halt Control Line
    );

    //! Instantiations
    /**
                                INSTUCTION FETCH
    **/
    wire [INST_SZ-1 : 0] npc_F;
    wire [INST_SZ-1 : 0] branch_delay_slot_F;
    wire [INST_SZ-1 : 0] instruction_F;
    wire [INST_SZ-1 : 0] jump_addr_D;
    wire [INST_SZ-1 : 0] branch_addr_D;
    wire [INST_SZ-1 : 0] read_data_1;
    wire [INST_SZ-1 : 0] read_data_2;

    IF #(.INST_SZ(INST_SZ), .PC_SZ(PC_SZ), .MEM_SZ(MEM_SZ)) InstructionFetch
        (
        // Sync Signals
        .i_clk(i_clk), .i_reset(i_reset), .i_write(i_write), .i_enable(i_enable),
        // Inputs
        .i_instruction_F(i_instruction), .i_branch_addr_D(branch_addr_D), 
        .i_jump_addr_D(jump_addr_D), .i_rs_addr_D(read_data_1),
        // Input Control Lines 
        .i_pc_src_D(pc_src_D), .i_jump_D(jump_MC), .i_jump_sel_D(jump_sel_MC), .i_stall_pc_HD(!stall_pc_HD),
        // Outputs
        .o_pc(o_pc), .o_npc_F(npc_F), .o_branch_delay_slot_F(branch_delay_slot_F), .o_instruction_F(instruction_F)
        );

    /**
                                IF/ID REGISTER
    **/
    wire [INST_SZ-1 : 0] instruction_IF_ID;
    wire [INST_SZ-1 : 0] npc_IF_ID;
    wire [INST_SZ-1 : 0] bds_IF_ID;

    IF_ID_reg #(.INST_SZ(INST_SZ)) IF_ID
        (
        // Sync Signals
        .i_clk(i_clk), .i_reset(i_reset | pc_src_D | jump_MC | jump_sel_MC ), .i_enable(!stall_if_id_HD & i_enable),
        // Inputs
        .i_instruction(instruction_F), .i_npc(npc_F), .i_bds(branch_delay_slot_F),
        // Outputs
        .o_instruction(instruction_IF_ID), .o_npc(npc_IF_ID), .o_bds(bds_IF_ID)
        );

    /**
                                INSTRUCTION DECODE
    **/
    wire [INST_SZ-1 : 0]          instr_imm_D;  
    wire [INST_SZ-1 : 0]          alu_result_EX_MEM;  
    wire [INST_SZ-1 : 0]          alu_result_M;   
    wire [INST_SZ-1 : 0]          write_data_W;
    wire [REG_SZ-1 : 0]           instr_rs_D;                
    wire [REG_SZ-1 : 0]           instr_rt_D;                
    wire [REG_SZ-1 : 0]           instr_rd_D;
    wire [REG_SZ-1 : 0]           write_register_MEM_WB;
    wire [ALU_OP-1 : 0]           alu_op_MC;
    wire [2 : 0]                  bhw_MC;
    wire                          halt_MC;


    ID #(.INST_SZ(INST_SZ), .REG_SZ(REG_SZ), .FORW_EQ(FORW_EQ)) InstructionDecode
        (
        // Sync Signals
        .i_clk(i_clk), .i_reset(i_reset),
        // Inputs
        .i_instruction_D(instruction_IF_ID), .i_npc_D(npc_IF_ID), .i_debug_addr(i_debug_addr),
        // Input Control Lines
        .i_forward_eq_a_FU(forward_eq_a_FU), .i_forward_eq_b_FU(forward_eq_b_FU), 
        .i_alu_result_M(alu_result_EX_MEM), .i_branch_MC(branch_MC), 
        .i_equal_MC(equal_MC), .i_reg_write_W(reg_write_MEM_WB), 
        .i_write_register_D(write_register_MEM_WB), .i_write_data_D(write_data_W),
        // Outputs
        .o_jump_addr_D(jump_addr_D), .o_branch_addr_D(branch_addr_D), 
        .o_read_data_1_D(read_data_1), .o_read_data_2_D(read_data_2),   
        .o_pc_src_D(pc_src_D), .o_instr_imm_D(instr_imm_D), 
        .o_instr_rs_D(instr_rs_D), .o_instr_rt_D(instr_rt_D), 
        .o_instr_rd_D(instr_rd_D), .o_reg(o_reg),
        // Output Control Lines
        .o_alu_op_MC(alu_op_MC),
        .o_reg_dst_MC(reg_dst_MC),
        .o_jal_sel_MC(jal_sel_MC),
        .o_alu_src_MC(alu_src_MC),
        .o_branch_MC(branch_MC),
        .o_equal_MC(equal_MC),
        .o_mem_read_MC(mem_read_MC),
        .o_mem_write_MC(mem_write_MC),
        .o_bhw_MC(bhw_MC),
        .o_jump_MC(jump_MC),
        .o_jump_sel_MC(jump_sel_MC),
        .o_reg_write_MC(reg_write_MC),
        .o_bds_sel_MC(bds_sel_MC),
        .o_mem_to_reg_MC(mem_to_reg_MC),
        .o_halt_MC(halt_MC)
        );

    /**
                                ID/EX REGISTER
    **/
    wire [INST_SZ-1 : 0]     bds_ID_EX;   
    wire [INST_SZ-1 : 0]     read_data_1_ID_EX;   
    wire [INST_SZ-1 : 0]     read_data_2_ID_EX;   
    wire [INST_SZ-1 : 0]     instr_imm_ID_EX;                
    wire [REG_SZ-1 : 0]      instr_rt_ID_EX;                 
    wire [REG_SZ-1 : 0]      instr_rd_ID_EX;                 
    wire [REG_SZ-1 : 0]      instr_rs_ID_EX;
    wire [ALU_OP-1 : 0]      alu_op_ID_EX;
    wire                     halt_ID_EX; 
    wire                     alu_src_ID_EX;      
    wire                     reg_dst_ID_EX;   
    wire                     jal_sel_ID_EX;    //TODO Agregar SXL/SXLV Control line 
    wire                     mem_read_ID_EX;  
    wire                     mem_write_ID_EX;
    wire [2 : 0]             bhw_ID_EX; 
    wire                     reg_write_ID_EX; 
    wire                     mem_to_reg_ID_EX;    
    wire                     bds_sel_ID_EX;
    wire                     flush_id_ex_HD;

    ID_EX_reg #(.INST_SZ(INST_SZ)) ID_EX
        (
        // Sync Signals
        .i_clk(i_clk), .i_reset(i_reset | flush_id_ex_HD), .i_enable(i_enable),
        // Input Control Lines //TODO Agregar SXL/SXLV Control Line
        .i_alu_src(alu_src_MC), .i_alu_op(alu_op_MC), .i_reg_dst(reg_dst_MC), .i_halt(halt_MC),
        .i_jal_sel(jal_sel_MC), .i_mem_read(mem_read_MC), .i_mem_write(mem_write_MC), .i_bhw(bhw_MC),
        .i_reg_write(reg_write_MC), .i_mem_to_reg(mem_to_reg_MC), .i_bds_sel(bds_sel_MC),
        // Inputs
        .i_bds(bds_IF_ID), .i_read_data_1(read_data_1), 
        .i_read_data_2(read_data_2), .i_instr_imm(instr_imm_D), 
        .i_instr_rt(instr_rt_D), .i_instr_rd(instr_rd_D), .i_instr_rs(instr_rs_D),
        // Output Control Lines //TODO Agregar SXL/SXLV Control Line
        .o_alu_src(alu_src_ID_EX), .o_alu_op(alu_op_ID_EX), .o_reg_dst(reg_dst_ID_EX), .o_halt(halt_ID_EX), 
        .o_jal_sel(jal_sel_ID_EX), .o_mem_read(mem_read_ID_EX), .o_mem_write(mem_write_ID_EX), .o_bhw(bhw_ID_EX),
        .o_reg_write(reg_write_ID_EX), .o_mem_to_reg(mem_to_reg_ID_EX), .o_bds_sel(bds_sel_ID_EX),
        // Outputs
        .o_read_data_1(read_data_1_ID_EX), .o_read_data_2(read_data_2_ID_EX), 
        .o_bds(bds_ID_EX), .o_instr_imm(instr_imm_ID_EX), 
        .o_instr_rt(instr_rt_ID_EX), .o_instr_rd(instr_rd_ID_EX), 
        .o_instr_rs(instr_rs_ID_EX)
        );


    /**
                                EXECUTE INSTUCTION
    **/
    wire [INST_SZ-1 : 0]          alu_result_E;
    wire [INST_SZ-1 : 0]          write_data_E;              
    wire [FORW_ALU-1 : 0]         forward_a_FU;
    wire [FORW_ALU-1 : 0]         forward_b_FU;             
    wire [REG_SZ-1 : 0]           write_register_E;

    EX #(.INST_SZ(INST_SZ), .ALU_OP(ALU_OP), .FORW_ALU(FORW_ALU), .ALU_SEL(ALU_SEL)) ExecuteInstruction
        (
        // Inputs 
        .i_read_data_1_E(read_data_1_ID_EX), .i_read_data_2_E(read_data_2_ID_EX),
        .i_alu_result_M(alu_result_EX_MEM), .i_read_data_W(write_data_W),
        .i_instr_imm_D(instr_imm_ID_EX), .i_instr_rt_D(instr_rt_ID_EX), 
        .i_instr_rd_D(instr_rd_ID_EX),
        // Input Control Lines //TODO Agregar SXL/SXLV Control Line
        .i_alu_src_MC(alu_src_ID_EX), .i_reg_dst_MC(reg_dst_ID_EX), .i_jal_sel_MC(jal_sel_ID_EX),
        .i_alu_op_MC(alu_op_ID_EX), .i_forward_a_FU(forward_a_FU), .i_forward_b_FU(forward_b_FU),
        // Outputs 
        .o_alu_result_E(alu_result_E), .o_operand_b_E(write_data_E),
        .o_instr_rd_E(write_register_E)
        );

    /**
                                EX/MEM REGISTER
    **/
    wire [INST_SZ-1 : 0]     write_data_EX_MEM;     
    wire [INST_SZ-1 : 0]     bds_EX_MEM;
    wire [REG_SZ-1 : 0]      write_register_EX_MEM;             
    wire                     mem_write_EX_MEM;
    wire [2 : 0]             bhw_EX_MEM;               
    wire                     reg_write_EX_MEM;               
    wire                     mem_to_reg_EX_MEM;              
    wire                     bds_sel_EX_MEM;   
    wire                     halt_EX_MEM;               

    EX_MEM_reg #(.INST_SZ(INST_SZ)) EX_MEM
        (
        // Sync Signals
        .i_clk(i_clk), .i_reset(i_reset), .i_enable(i_enable),
        // Input Control Lines 
        .i_mem_write(mem_write_ID_EX), .i_reg_write(reg_write_ID_EX), 
        .i_mem_to_reg(mem_to_reg_ID_EX), .i_bds_sel(bds_sel_ID_EX), 
        .i_halt(halt_ID_EX), .i_bhw(bhw_ID_EX),
        // Inputs
        .i_alu_result(alu_result_E), .i_write_data(write_data_E),
        .i_write_register(write_register_E), .i_bds(bds_ID_EX),
        // Output Control Lines 
        .o_mem_write(mem_write_EX_MEM), .o_reg_write(reg_write_EX_MEM), 
        .o_mem_to_reg(mem_to_reg_EX_MEM), .o_bds_sel(bds_sel_EX_MEM), 
        .o_halt(halt_EX_MEM), .o_bhw(bhw_EX_MEM),
        // Outputs
        .o_alu_result(alu_result_EX_MEM), .o_write_data(write_data_EX_MEM),
        .o_write_register(write_register_EX_MEM), .o_bds(bds_EX_MEM)
        );

    /**
                                MEMORY ACCESS
    **/
    wire [INST_SZ-1 : 0]          read_data_M;              

    MEM #(.INST_SZ(INST_SZ)) MemoryAccess
        (
        // Sync Signals
        .i_clk(i_clk),
        // Inputs 
        .i_alu_result_E(alu_result_EX_MEM), .i_operand_b_E(write_data_EX_MEM),
        .i_debug_addr(i_debug_addr),
        // Input Control Lines 
        .i_mem_write_M(mem_write_EX_MEM), .i_bhw_M(bhw_EX_MEM),
        // Outputs
        .o_alu_result_M(alu_result_M), .o_read_data_M(read_data_M), .o_debug_mem(o_mem)
        );

    /**
                                MEM/WB REGISTER
    **/               
    wire [INST_SZ-1 : 0]     read_data_MEM_WB;    
    wire [INST_SZ-1 : 0]     alu_result_MEM_WB;
    wire [INST_SZ-1 : 0]     bds_MEM_WB; 
    wire                     mem_to_reg_MEM_WB;               
    wire                     bds_sel_MEM_WB; 

    MEM_WB_reg #(.INST_SZ(INST_SZ)) MEM_WB
        (
        // Sync Signals
        .i_clk(i_clk), .i_reset(i_reset), .i_enable(i_enable),
        // Input Control Lines 
        .i_reg_write(reg_write_EX_MEM), .i_mem_to_reg(mem_to_reg_EX_MEM), 
        .i_bds_sel(bds_sel_EX_MEM), .i_halt(halt_EX_MEM),
        // Inputs
        .i_read_data(read_data_M), .i_alu_result(alu_result_M),
        .i_write_register(write_register_EX_MEM), .i_bds(bds_EX_MEM),
        // Output Control Lines 
        .o_reg_write(reg_write_MEM_WB), .o_mem_to_reg(mem_to_reg_MEM_WB), 
        .o_bds_sel(bds_sel_MEM_WB), .o_halt(o_halt),
        // Outputs
        .o_read_data(read_data_MEM_WB), .o_alu_result(alu_result_MEM_WB),
        .o_write_register(write_register_MEM_WB), .o_bds(bds_MEM_WB)
        );

    /**
                                WRITE BACK
    **/
    WB #(.INST_SZ(INST_SZ)) WriteBack
        (
        // Inputs 
        .i_alu_result_M(alu_result_MEM_WB), .i_read_data_M(read_data_MEM_WB),
        .i_branch_delay_slot_M(bds_MEM_WB),
        // Input Control Lines 
        .i_mem_to_reg_W(mem_to_reg_MEM_WB), .i_bds_sel_W(bds_sel_MEM_WB),
        // Outputs
        .o_write_data_W(write_data_W)
        );

    /**
                                CONTROL UNITS
    **/

    //  Hazard Detection Unit
    HazardDetectionUnit #(.INPUT_SZ(REG_SZ)) HazardDetectionUnit
        (
            // Input Control Lines 
            .i_mem_to_reg_M(mem_to_reg_EX_MEM),             
            .i_mem_read_E(mem_read_ID_EX),               
            .i_reg_write_E(reg_write_ID_EX),              
            .i_branch_D(branch_MC),  
            // Inputs               
            .i_instr_rs_D(instr_rs_D),    
            .i_instr_rt_D(instr_rt_D), 
            .i_instr_rt_E(instr_rt_ID_EX), 
            .i_instr_rd_E(instr_rd_ID_EX),
            .i_instr_rd_M(write_register_EX_MEM),
            // Output Control Lines
            .o_stall_pc_HD(stall_pc_HD),              
            .o_stall_if_id_HD(stall_if_id_HD),            
            .o_flush_id_ex_HD(flush_id_ex_HD)             
        );

    //  Forwarding Unit
    ForwardingUnit #(.FORW_EQ(FORW_EQ), .FORW_ALU(FORW_ALU)) ForwardingUnit
        (
            // Inputs
            .i_instr_rs_D(instr_rs_D),
            .i_instr_rt_D(instr_rt_D),
            .i_instr_rt_E(instr_rt_ID_EX),
            .i_instr_rs_E(instr_rs_ID_EX),
            .i_instr_rd_M(write_register_EX_MEM),
            .i_instr_rd_W(write_register_MEM_WB),
            .i_reg_write_M(reg_write_EX_MEM),
            .i_reg_write_W(reg_write_MEM_WB),
            // Output Control Lines
            .o_forward_eq_a_FU(forward_eq_a_FU),
            .o_forward_eq_b_FU(forward_eq_b_FU),
            .o_forward_a_FU(forward_a_FU),
            .o_forward_b_FU(forward_b_FU)
        );

endmodule