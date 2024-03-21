`timescale 1ns/10ps

module IF_tb();
    // Parameters
    localparam T = 10;      // Clock Period [ns]
    localparam W = 5;
    localparam PC_SZ = 32;
    localparam INST_SZ = 32;

    // Declarations
    reg i_clk;
    reg i_reset;
    reg i_write;
    reg i_enable;
    reg stall_pc_HD;
    reg [INST_SZ-1 : 0] i_instruction;
    reg [INST_SZ-1 : 0] branch_addr_D;
    reg [INST_SZ-1 : 0] jump_addr_D;
    reg [INST_SZ-1 : 0] read_data_1;
    reg pc_src_D, jump_MC, jump_sel_MC, stall_pc_HD;

    wire [PC_SZ-1 : 0] npc, bds;
    wire [INST_SZ-1 : 0] instruction_F;

    integer i;
    reg [INST_SZ-1 : 0] inst_test;

    // Instantiations
    IF #(.INST_SZ(INST_SZ), .PC_SZ(PC_SZ), .MEM_SZ(W)) InstructionFetch
        (
        // Sync Signals
        .i_clk(i_clk), .i_reset(i_reset), .i_write(i_write), .i_enable(i_enable),
        // Inputs
        .i_instruction_F(i_instruction), .i_branch_addr_D(branch_addr_D), 
        .i_jump_addr_D(jump_addr_D), .i_rs_addr_D(read_data_1),
        // Input Control Lines 
        .i_pc_src_D(pc_src_D), .i_jump_D(jump_MC), .i_jump_sel_D(jump_sel_MC), .i_stall_pc_HD(!stall_pc_HD),
        // Outputs
        .o_npc_F(npc), .o_branch_delay_slot_F(bds), .o_instruction_F(instruction_F)
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
        i_enable = 1'b0;    
        i_instruction = {INST_SZ{1'b0}};
        inst_test =  {INST_SZ{1'b0}};
        stall_pc_HD = 1'b0;

        i_write = 1'b0;
        pc_src_D = 1'b0;
        jump_MC = 1'b0;
        jump_sel_MC = 1'b0;

        read_data_1 = 10; // To test JumpSel
        jump_addr_D = 20; // To test Jump
        branch_addr_D = 30; // To test PCSrc

        i_reset = 1'b1;
        #20;
        i_reset = 1'b0;

        // Test uploading insts (full mem)
        i_write = 1'b1;
        for (i = 0; i < 2**W; i = i + 1) begin
            i_instruction = inst_test;
            inst_test = inst_test + 1;
            #(T*2);
        end

        i_enable = 1'b1;
        i_write = 1'b0;

        #100;

        // Test Control Lines
        pc_src_D = 1'b1;
        #(T*2);
        pc_src_D = 1'b0;
        #(T*2);
        jump_MC = 1'b1;
        #(T*2);
        jump_MC = 1'b0;
        #(T*2);
        jump_sel_MC = 1'b1;
        #(T*2);
        jump_sel_MC = 1'b0;

        #100;

        // Test stall PC
        stall_pc_HD = 1'b1;
        #50;
        stall_pc_HD = 1'b0;

        #100;

        $stop;
    end

    always @(posedge i_clk)
    begin
        $display("\nTime: %t", $time);
        $display("Inputs:");
        $display("i_instruction   = %d", i_instruction);
        $display("i_branch_addr_D = %d", branch_addr_D);
        $display("i_jump_addr_D   = %d", jump_addr_D);
        $display("i_rs_addr_D     = %d", read_data_1);
        $display("i_pc_src_D      = %b", pc_src_D);
        $display("i_jump_D        = %b", jump_MC);
        $display("i_jump_sel_D    = %b", jump_sel_MC);
        $display("i_stall_pc_HD   = %b", stall_pc_HD);
        $display("Outputs:");
        $display("o_npc_F         = %d", npc);
        $display("o_branch_delay_slot_F = %d", bds);
        $display("o_instruction_F = %d\n", instruction_F);
    end

endmodule