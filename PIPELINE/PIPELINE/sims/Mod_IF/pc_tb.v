`timescale 1ns/10ps

module pc_tb();
    // Parameters
    localparam T = 10;      // Clock Period [ns]
    localparam PC_SZ = 32;

    // Declarations
    reg i_clk;
    reg i_reset;
    reg i_stall_pc_HD;
    reg i_enable;
    reg [PC_SZ-1 : 0] i_pc;
    wire [PC_SZ-1 : 0] o_pc;
    integer i;

    // Instantiations
    pc #(.PC_SZ(PC_SZ)) prog_counter
        (.i_clk(i_clk), .i_reset(i_reset), .i_enable(!i_stall_pc_HD & i_enable),
        .i_pc(i_pc), 
        .o_pc(o_pc));

    // Clock Generation
    always
    begin
        #(T) i_clk = ~i_clk;
    end
    
    // Task
    initial 
    begin
        i_clk = 1'b0;
        i_enable = 1'b1;
        i_pc = {PC_SZ{1'b0}};
        i_stall_pc_HD = 1'b0;

        i_reset = 1'b1;
        #20;
        i_reset = 1'b0;

        for (i = 0; i < 10; i = i + 1) begin
            i_pc = i_pc + 4; // Increment by 4
            #(T*2);
        end

        i_stall_pc_HD = 1'b1;
        #20;

        $stop;
    end

    always @(posedge i_clk)
    begin
        $display("PC: %b \n", o_pc);
    end

endmodule