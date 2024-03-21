`timescale 1ns/10ps

module WB_tb();
    // Parameters
    localparam T = 10;      // Clock Period [ns]
    localparam INST_SZ = 32;

    // Declarations
    reg [INST_SZ-1 : 0]           alu_result; 
    reg [INST_SZ-1 : 0]           read_data;
    reg [INST_SZ-1 : 0]           bds; 
    reg                           mem_to_reg;            
    reg                           bds_sel;             
    
    wire [INST_SZ-1 : 0]          o_write_data;

    reg [INST_SZ-1 : 0] seed;

    // Instantiations
    WB #(.INST_SZ(INST_SZ)) WriteBack
        (
        // Inputs 
        .i_alu_result_M(alu_result), .i_read_data_M(read_data),
        .i_branch_delay_slot_M(bds),
        // Input Control Lines 
        .i_mem_to_reg_W(mem_to_reg), .i_bds_sel_W(bds_sel),
        // Outputs
        .o_write_data_W(o_write_data)
        );

    // Task
    initial 
    begin
        seed = 12345;
        alu_result = $random(seed);
        read_data = $random(seed);
        bds = $random(seed);
        mem_to_reg = 1'b0;
        bds_sel = 1'b0;

        $display("TESTING WB");
        $display("alu_result: %b", alu_result);
        $display("read_data: %b", read_data);
        $display("bds: %b\n", bds);

        // R-Type and Imm Test
        mem_to_reg = 1'b0;
        bds_sel = 1'b0;

        if(o_write_data != alu_result)
        begin
            $display("ALU Result should be the ouput.");
            $display("Output: %d", o_write_data);
            $stop;
        end

        #10;

        // Load Test
        mem_to_reg = 1'b1;
        bds_sel = 1'b0;

        if(o_write_data != read_data)
        begin
            $display("Read Data should be the ouput.");
            $display("Output: %d", o_write_data);
            $stop;
        end

        #10;

        // JAL and JALR Test
        mem_to_reg = 1'b1;
        bds_sel = 1'b1;

        #10;

        if(o_write_data != bds)
        begin
            $display("Branch Delay Slot should be the ouput.");
            $display("Output: %b", o_write_data);
            $stop;
        end

        $display("ALL TESTS PASSED!");

        $stop;
    end

endmodule
