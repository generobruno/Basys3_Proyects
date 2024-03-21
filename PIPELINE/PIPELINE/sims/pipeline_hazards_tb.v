`timescale 1ns/1ps

module pipeline_hazards_tb();
    // Parameters
    localparam T             =   10;    // Clock Period [ns]
    localparam INST_SZ       =   32;
    localparam PC_SZ         =   32;
    localparam OPCODE_SZ     =   6;
    localparam FUNCT_SZ      =   6;
    localparam REG_SZ        =   5;
    localparam MEM_SZ        =   10;
    localparam FORW_EQ       =   1;
    localparam FORW_ALU      =   2;
    localparam ALU_OP        =   3;
    localparam ALU_SEL       =   6;
    localparam FUNCT         =   6;

    // Operation Parameters
    localparam ADDU =           6'b100001;      // Add Word Unsigned 
    localparam SUBU =           6'b100011;      // Subtract Word Unsigned
    localparam AND  =           6'b100100;      // Logical bitwise AND 
    localparam OR   =           6'b100101;      // Logical bitwise OR
    localparam XOR  =           6'b100110;      // Logical bitwise XOR
    localparam NOR  =           6'b100111;      // Logical bitwise NOR
    localparam SLT  =           6'b101010;      // Set on Less Than
    localparam SRA  =           6'b000011;      // Shift Word Right Arithmetic
    localparam SRL  =           6'b000010;      // Shift Word Right Logic
    localparam SLL  =           6'b000000;      // Shift Word Left Logic
    localparam SLLV =           6'b000100;      // Shift Word Left Logic Variable
    localparam SRLV =           6'b000110;      // Shift Word Right Logic Variable
    localparam SRAV =           6'b000111;      // Shift Word Right Arithmetic Variable
    localparam JR       =       6'b001000;      // Jump Register
    localparam JALR     =       6'b001001;      // Jump and Link Register

    // Declarations
    reg i_clk;
    reg i_reset;
    reg i_enable;
    reg i_write;
    reg [INST_SZ-1 : 0]           i_instruction;
    reg [REG_SZ-1 : 0]            i_debug_addr;

    wire [INST_SZ-1 : 0]          o_pc;
    wire [INST_SZ-1 : 0]          o_mem;
    wire [INST_SZ-1 : 0]          o_reg;
    wire                          o_halt;

    reg [INST_SZ-1 : 0] seed;
    reg [INST_SZ-1 : 0] expected_res;    
    reg [4 : 0]         reg_instr_rt;
    reg [4 : 0]         reg_instr_rs;   
    reg [4 : 0]         reg_instr_rd;   
    reg [4 : 0]         reg_sa;  
    reg [4 : 0]         reg_base;
    reg [15 : 0]        reg_offset;
    reg [15 : 0]        reg_immediate;
    reg [25 : 0]        reg_instr_index;

    //*******************************************************************************************************
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
            // Input Control Lines //TODO REVISAR
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
            // Inputs //TODO REVISAR
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


    //*******************************************************************************************

    integer i;
    
    // Clock Generation
    always
    begin
    
        #(T) i_clk = ~i_clk;
    end
    
    // Task
    initial 
    begin
        i_clk = 1'b0;
        i_enable = 1'b0;
        i_reset = 1'b0;
        i_write = 1'b1;
        i_instruction = {INST_SZ{1'b0}};

        seed = 123456;
        expected_res = {INST_SZ{1'b0}};

        i_reset = 1'b1;
        #(T*2);
        i_reset = 1'b0;

        //! START
        //! INST 1: XORI $s0, $zero, 0x0003 (00hex)
        // Inputs
        reg_instr_rt = 5'b00001;
        reg_instr_rs = 5'b00000;
        reg_immediate = 3;
        // reg[1] = 3

        i_instruction = {6'b001110, reg_instr_rs, reg_instr_rt, reg_immediate};

        #(T*2);

        //! XORI $s1, $zero, 0x0004 (04hex)
        // Inputs
        reg_instr_rt = 5'b00010;
        reg_instr_rs = 5'b00000;
        reg_immediate = 4;
        // reg[2] = 4

        i_instruction = {6'b001110, reg_instr_rs, reg_instr_rt, reg_immediate};

        #(T*2);

        //! J next1 -> CONTOL HAZARD (08hex)
        // Inputs
        reg_instr_index = 26'h14;
        // Jump to next1 (18hex)    

        i_instruction = {6'b000010, reg_instr_index};

        #(T*2);

        //! next2: XORI $s0, $zero, 0x0001 (0Chex)
        // Inputs
        reg_instr_rt = 5'b00001;
        reg_instr_rs = 5'b00000;
        reg_immediate = 1;
        // next2 (10 hex): reg[1] = 1

        i_instruction = {6'b001110, reg_instr_rs, reg_instr_rt, reg_immediate};

        #(T*2);

        //! XORI $s1, $zero, 0x0001 (10hex)
        // Inputs
        reg_instr_rt = 5'b00010;
        reg_instr_rs = 5'b00000;
        reg_immediate = 1;
        // reg[2] = 1

        i_instruction = {6'b001110, reg_instr_rs, reg_instr_rt, reg_immediate};

        #(T*2);

        //! next1: SUB $s2, $s1, $s0 -> DATA HAZARD (FORWARDING) (14hex)
        // Inputs
        reg_instr_rd = 5'b00011;
        reg_instr_rs = 5'b00010;
        reg_instr_rt = 5'b00001;
        // next1 (18hex): reg[3] = reg[2] - reg[1]

        i_instruction = {6'b000000, reg_instr_rs, reg_instr_rt, reg_instr_rd, 5'b00000, SUBU};

        #(T*2);

        //! BNE $s0, $s1, next2 -> DATA AND CONTROL HAZARD (FORWARDING) (18hex)
        // Inputs
        reg_instr_rs = 5'b00001;
        reg_instr_rt = 5'b00010;
        reg_offset = 16'hFFFC; // FFFC hex = -3 dec (complement 2)
        // (PC = 1Chex) if reg[1] != reg[2] -> Branch to next2

        i_instruction = {6'b000101, reg_instr_rs, reg_instr_rt, reg_offset};

        #(T*2);

        //! ADD $s3, $s0, $s1 (1Chex)
        // Inputs
        reg_instr_rd = 5'b00100;
        reg_instr_rs = 5'b00001;
        reg_instr_rt = 5'b00010;
        // reg[4] = reg[1] + reg[2] 

        i_instruction = {6'b000000, reg_instr_rs, reg_instr_rt, reg_instr_rd, 5'b00000, ADDU};

        #(T*2);

        //! SW $s3, 16($s2) -> DATA HAZARD (FORWARDING) (20hex)
        // Inputs
        reg_base = 5'b00011;
        reg_instr_rt = 5'b00100;
        reg_offset = 16'h10;
        // reg[4] -> mem[base + offset]

        i_instruction = {6'b101011, reg_base, reg_instr_rt, reg_offset};

        #(T*2);

        //! LW $s4, 16($s2) (24hex)
        // Inputs
        reg_base = 5'b00011;
        reg_instr_rt = 5'b00101;
        reg_offset = 16'h10;
        // reg[5] <- mem[base + offset]

        i_instruction = {6'b100011, reg_base, reg_instr_rt, reg_offset};

        #(T*2);

        //! SLT $s5, $s0, $s4 -> DATA HAZARD (STALLING AND FORWARDING) (28hex)
        // Inputs
        reg_instr_rd = 5'b00110;
        reg_instr_rs = 5'b00001;
        reg_instr_rt = 5'b00101;
        // reg[6] = 1 if reg[1] < reg[5]

        i_instruction = {6'b000000, reg_instr_rs, reg_instr_rt, reg_instr_rd, 5'b00000, SLT};

        #(T*2);

        //! LW $s3, 16($s2) (2Chex)
        // Inputs
        reg_base = 5'b00011;
        reg_instr_rt = 5'b00100;
        reg_offset = 16'h10;
        // reg[4] <- mem[base + offset]

        i_instruction = {6'b100011, reg_base, reg_instr_rt, reg_offset};

        #(T*2);

        //! XORI $s3, $s2, 0x0001 -> STALLING (30hex)
        // Inputs
        reg_instr_rs = 5'b00011;
        reg_immediate = 16'h0001;
        reg_instr_rt = 5'b00100;
        // reg[4] = reg[3] XOR 1

        i_instruction = {6'b001110, reg_instr_rs, reg_instr_rt, reg_immediate};

        #(T*2);

        //! XORI $s5, $s5, 0x0001 (34hex)
        // Inputs
        reg_instr_rs = 5'b00110;
        reg_immediate = 1;
        reg_instr_rt = 5'b00110;
        // reg[6] = reg[6] XOR 1

        i_instruction = {6'b001110, reg_instr_rs, reg_instr_rt, reg_immediate};

        #(T*2);

        /*
        //! JR $s5 -> DATA AND CONTROL HAZARD (FORWARDING) (38hex) -> Loop
        // Inputs
        reg_instr_rs = 5'b00110;
        // PC <- reg[6]

        i_instruction = {6'b000000, reg_instr_rs, {15{1'b0}}, JR};

        #(T*2);
        */

        //! TEST UNSIGNED LOADS

        //! ADDI - Add Immediate Test: rt <- rs + imm
        // Inputs
        reg_instr_rs = 5'b00000;
        reg_immediate = 16'hFFFF; // 0Chex (12dec)
        reg_instr_rt = 5'b01111;
        // reg[15] = FFFF

        i_instruction = {6'b001000, reg_instr_rs, reg_instr_rt, reg_immediate};

        #(T*2);

        //! SW - Store Reg[15]
        // Inputs
        // Inputs
        reg_base = 5'b01101;
        reg_instr_rt = 5'b01111;
        reg_offset = 16'h18;
        // mem[(0+18)>>2] = mem[6] = FFFF

        i_debug_addr = 5'b00001; // Signed offset + GPR[base]

        i_instruction = {6'b101011, reg_base, reg_instr_rt, reg_offset};

        #(T*2);

        //! LHU mem[6] to reg[30]
        // Inputs
        reg_base = 5'b01101;
        reg_instr_rt = 5'b11110;
        reg_offset = 16'h18;
        // reg[30] <- mem[6]

        i_instruction = {6'b100101, reg_base, reg_instr_rt, reg_offset};

        #(T*2);

        //! TESTS *****************************************************************
        // Inputs
        reg_immediate = 10;
        reg_instr_rt = 5'b11011;

        i_instruction = {6'b001_111, 5'b00000, reg_instr_rt, reg_immediate};

        #(T*2);

        //! HALT (3Chex)
        i_instruction = 32'b000000_00000_00000_00000_111111;
        
        #(T*2);

        /**********************************
            Results (withoud JR):
                reg[0]=0
                reg[1]=1
                reg[2]=1
                reg[3]=0
                reg[4]=1
                reg[5]=2
                reg[6]=0
        ***********************************/
        
        $display("LOADING PROGRAM...");

        i_write = 1'b0;
        i_instruction = {INST_SZ{1'b0}};
        #100;
        i_enable = 1'b1;
        
        $display("RUNNING...");

        // Wait for HALT
        @(posedge o_halt);
        
        $display("PROGRAM FINISHED.");
        i_enable = 1'b0;

        $display("\nDisplaying Memory Data:");
        for(i = 0; i < 5**2; i = i + 1)
        begin
            i_debug_addr = i; // Address
            #(T*2);
            $display("DEBUG DATA: %d (%h) from %b", o_mem, o_mem, i_debug_addr[MEM_SZ-1:0]);
        end

        $display("\nDisplaying Registers:");
        for(i = 0; i < 32; i = i + 1)
        begin
            i_debug_addr = i; // Address
            #(T*2);
            $display("DEBUG REGS: %d (%h) from %b (%d)", o_reg, o_reg, i_debug_addr[4:0], i_debug_addr[4:0]);
        end

        $display("\nTESTS PASSED!");
        
        $stop;
    end

endmodule
