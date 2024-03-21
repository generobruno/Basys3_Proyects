`timescale 1ns/10ps

module ID_tb();
    // Parameters
    localparam T = 10;      // Clock Period [ns]
    localparam REG_SZ = 5;
    localparam REGS = 32;
    localparam INST_SZ = 32;
    localparam FORW_EQ = 1;
    localparam OPCODE_SZ = 6;
    localparam FUNCT_SZ = 6;

    // Declarations
    reg i_clk;
    reg i_reset;
    reg [INST_SZ-1 : 0] i_instruction;
    reg [INST_SZ-1 : 0] i_npc;
    reg forward_eq_a;
    reg forward_eq_b;
    reg [INST_SZ-1 : 0] alu_result;            
    reg reg_write;
    reg branch;
    reg equal;
    reg [REG_SZ-1 : 0] write_register;
    reg [INST_SZ-1 : 0] write_data;

    wire [INST_SZ-1 : 0] jump_addr_D;
    wire [INST_SZ-1 : 0] branch_addr_D;
    wire [INST_SZ-1 : 0] read_data_1;            
    wire [INST_SZ-1 : 0] read_data_2;            
    wire pc_src_D;                 
    wire [INST_SZ-1 : 0] instr_imm_D;              
    wire [4 : 0] instr_rs_D;
    wire [4 : 0] instr_rt_D;
    wire [4 : 0] instr_rd_D;

    integer i;

    // Operation parameters
    localparam SLL      = 32'b000000_00000_00000_00000_00000_000000;
    localparam ADDU     = 32'b000000_00001_00010_00011_00000_100001;
    localparam LW       = 32'b100011_00001_00010_0000000000000000;
    localparam SW       = 32'b101011_00001_00010_0000000000000000;
    localparam ADDI     = 32'b001000_00001_00010_0000000000000000;
    localparam BEQ      = 32'b000100_00001_00010_0000000000000000;
    localparam BNE      = 32'b000101_00001_00010_0000000000000000;
    localparam J        = 32'b000010_00000000000000000000111000;
    localparam JAL      = 32'b000011_00000000000000000000000000;
    localparam JR       = 32'b000000_00001_000000000000000_001000;
    localparam JALR     = 32'b000000_00001_00000_00000_001001;

    // Instantiations
    ID #(.INST_SZ(INST_SZ), .REG_SZ(REG_SZ), .FORW_EQ(FORW_EQ)) InstructionDecode
        (
        // Sync Signals
        .i_clk(i_clk), .i_reset(i_reset),
        // Inputs
        .i_instruction_D(i_instruction), .i_npc_D(i_npc),
        // Input Control Lines
        .i_forward_eq_a_FU(forward_eq_a), .i_forward_eq_b_FU(forward_eq_b), 
        .i_alu_result_M(alu_result), .i_branch_MC(branch), 
        .i_equal_MC(equal), .i_reg_write_W(reg_write), 
        .i_write_register_D(write_register), .i_write_data_D(write_data),
        // Outputs
        .o_jump_addr_D(jump_addr_D), .o_branch_addr_D(branch_addr_D), 
        .o_read_data_1_D(read_data_1), .o_read_data_2_D(read_data_2),   
        .o_pc_src_D(pc_src_D), .o_instr_imm_D(instr_imm_D), 
        .o_instr_rs_D(instr_rs_D), .o_instr_rt_D(instr_rt_D), 
        .o_instr_rd_D(instr_rd_D)
        );

    // Clock Generation
    always
    begin
        #(T) i_clk = ~i_clk;
    end
    
    // Task
    initial 
    begin
        i_clk = 1'b0;
        i_npc = {INST_SZ{1'b0}};
        i_instruction = {INST_SZ{1'b0}};
        write_data = {INST_SZ{1'b0}};
        alu_result = {INST_SZ{1'b0}};
        write_register = {REG_SZ{1'b0}};
        reg_write = 1'b0;
        forward_eq_a = 1'b0;
        forward_eq_b = 1'b0;

        i_reset = 1'b1;
        #20;
        i_reset = 1'b0;

        // Load Registers
        reg_write = 1'b1;
        for (i = 0; i < REGS; i = i + 1)
        begin
            write_register = i; 
            write_data = i;
            #(T*2); 
        end  
        reg_write = 1'b0;

        #50;

        //                  Test Instructions
        /* Shift Instrucion
        */
        i_instruction = SLL;
        #10;
        /* 3-Operand ALU Instrucion
        */
        i_instruction = ADDU;
        #10;
        /* Normal CPU Load Instrucion
        */
        i_instruction = LW;
        #10;    
        /* Normal CPU Store Instrucion
        */
        i_instruction = SW;
        #10;    
        /* ALU with imm Instrucion
        */
        i_instruction = ADDI;
        #10;    
        /* BEQ Instrucion
        */
        i_instruction = BEQ;
        #10;    
        /* BNE Instrucion
        */
        i_instruction = BNE;
        #10;    
        /* J Instrucion
        */
        i_npc = 32'h30;
        i_instruction = J;
        #10;
        $stop;
        /* JAL Instrucion
        */
        i_instruction = JAL;
        #10;
        /* JR Instrucions
        */
        i_instruction = JR;
        #10;
        /* JALR Instrucion
        */
        i_instruction = JALR;
        
        #100;

        $stop;
    end

always @(posedge i_clk)
begin
    $display("\nTime: %t", $time);
    $display("Inputs:");
    $display("i_instruction_D = %h", i_instruction);
    $display("i_npc_D = %h", i_npc);
    $display("i_forward_eq_a_FU = %h", forward_eq_a);
    $display("i_forward_eq_b_FU = %h", forward_eq_b);
    $display("i_alu_result_M = %h", alu_result);
    $display("i_branch_MC = %h", branch);
    $display("i_equal_MC = %h", equal);
    $display("i_reg_write_W = %h", reg_write);
    $display("i_write_register_D = %h", write_register);
    $display("i_write_data_D = %h", write_data);

    $display("Outputs:");
    $display("o_jump_addr_D = %h", jump_addr_D);
    $display("o_branch_addr_D = %h", branch_addr_D);
    $display("o_read_data_1_D = %h", read_data_1);
    $display("o_read_data_2_D = %h", read_data_2);
    $display("o_pc_src_D = %h", pc_src_D);
    $display("o_instr_imm_D = %h", instr_imm_D);
    $display("o_instr_rs_D = %h", instr_rs_D);
    $display("o_instr_rt_D = %h", instr_rt_D);
    $display("o_instr_rd_D = %h\n", instr_rd_D);
end



endmodule