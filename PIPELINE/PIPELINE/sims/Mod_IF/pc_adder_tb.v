`timescale 1ns/10ps

module pc_adder_tb();
    // Parameters
    localparam T = 10;      // Clock Period [ns]
    localparam PC_SZ = 32;

    // Declarations
    reg [PC_SZ-1 : 0] i_pc;
    wire [PC_SZ-1 : 0] o_npc;
    wire [PC_SZ-1 : 0] o_bds;
    integer i;

    // Instantiations
    pc_adder #(.PC_SZ(PC_SZ)) pc_adder
        (.i_pc(i_pc),
        .o_pc(o_npc), .o_bds(o_bds));
    
    // Task
    initial 
    begin
        i_pc = {PC_SZ{1'b0}};

        for (i = 0; i < 10; i = i + 1) begin
            i_pc = i_pc + 4; // Increment by 4
            #(T*2);
        end

        $stop;
    end

    always @(*)
    begin
        $display("PC: %d \n NPC: %d - BDS: %d \n", i_pc, o_npc, o_bds);
        #(T*2);
    end

endmodule