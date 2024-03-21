`timescale 1ns/10ps

module comparator_tb();
    // Parameters
    localparam T = 10;      // Clock Period [ns]
    localparam INST_SZ = 32;

    // Declarations
    reg i_clk;
    reg [INST_SZ-1 : 0] i_read_data_1_D;
    reg [INST_SZ-1 : 0] i_read_data_2_D;
    wire o_comparison;

    // Instantiate the Comparator Module
    comparator #(.INST_SZ(INST_SZ)) comp_inst
        (
        .i_read_data_1(i_read_data_1_D),
        .i_read_data_2(i_read_data_2_D),
        .o_comparison(o_comparison)
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
        i_read_data_1_D = {INST_SZ{1'b0}};
        i_read_data_2_D = {INST_SZ{1'b0}};

        // Test Case 1: When i_read_data_1 and i_read_data_2 are equal
        i_read_data_1_D = 32'hABCDEF01;
        i_read_data_2_D = 32'hABCDEF01;
        #20;

        // Test Case 2: When i_read_data_1 and i_read_data_2 are not equal
        i_read_data_1_D = 32'hABCDEF01;
        i_read_data_2_D = 32'h12345678;
        #20;

        $stop;
    end

    // Display
    always @(posedge i_clk)
    begin
        $display("Time: %t", $time);
        $display("Inputs:");
        $display("i_read_data_1 = %h", i_read_data_1_D);
        $display("i_read_data_2 = %h", i_read_data_2_D);
        $display("Output:");
        $display("o_comparison = %b", o_comparison);
    end

endmodule
