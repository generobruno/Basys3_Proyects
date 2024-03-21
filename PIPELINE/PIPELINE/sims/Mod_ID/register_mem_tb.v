`timescale 1ns/10ps

module register_mem_tb();
    // Parameters
    localparam T = 10;      // Clock Period [ns]
    localparam W = 5;
    localparam INST_SZ = 32;

    // Declarations
    reg i_clk;
    reg i_reset;
    reg i_reg_write;
    reg [INST_SZ-1 : 0] i_instruction_D;
    reg [INST_SZ-1 : 0] i_write_data_D;
    reg [W-1 : 0] i_write_register_D;

    wire [INST_SZ-1 : 0] read_data_1, read_data_2;

    integer i;
    reg [4:0] reg_num_rs;
    reg [4:0] reg_num_rt;

    // Instantiations
    register_mem #(.B(INST_SZ), .W(W)) register_mem
        (.i_clk(i_clk), .i_reset(i_reset),
        .i_reg_write_MC(i_reg_write),
        .i_read_reg_1(i_instruction_D[25 : 21]), .i_read_reg_2(i_instruction_D[20 : 16]),
        .i_write_register(i_write_register_D), .i_write_data(i_write_data_D),
        .o_read_data_1(read_data_1), .o_read_data_2(read_data_2));

    // Clock Generation
    always
    begin
        #(T) i_clk = ~i_clk;
    end
    
    // Task
    initial 
    begin
        i_clk = 1'b0;
        i_reg_write = 1'b0;
        i_instruction_D = {INST_SZ{1'b0}};
        i_write_data_D = {INST_SZ{1'b0}};
        i_write_register_D = {W{1'b0}};
        reg_num_rs = {W{1'b0}};
        reg_num_rt = {W{1'b0}};

        i_reset = 1'b1;
        #(T*2);
        i_reset = 1'b0;

        // Write Registers Test
        $display("\nWrite Registers Test\n");
        i_reg_write = 1'b1; 
        for (i = 0; i < 32; i = i + 1) 
        begin
            i_write_register_D = i; 
            i_write_data_D = i;
            #(T*2); 
        end
        i_write_register_D = {W{1'b0}}; 
        i_write_data_D = {INST_SZ{1'b0}};
        i_reg_write = 1'b0; // Disable write

        // Read Registers Test
        $display("\nRead Registers Test\n");
        for (i = 0; i < 32; i = i +1)
        begin
            reg_num_rs = i;
            reg_num_rt = i*2;
            i_instruction_D = {5'b0, reg_num_rt, reg_num_rs, 16'b0};
            #(T*2);
        end

        #100; 
        
        $stop;
    end

    always @(posedge i_clk)
    begin
        $display("Time: %t", $time);
        $display("Inputs:");
        $display("i_instruction   = %b", i_instruction_D);
        $display("inst rs   = %d", i_instruction_D[25:21]);
        $display("inst rt   = %d",i_instruction_D[20:16]);
        $display("i_write_data   = %d", i_write_data_D);
        $display("i_write_register   = %d", i_write_register_D);
        $display("Outputs:");
        $display("o_read_data_1 = %d", read_data_1);
        $display("o_read_data_2 = %d", read_data_2);
    end

endmodule