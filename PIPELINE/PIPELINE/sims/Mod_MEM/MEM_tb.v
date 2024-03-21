`timescale 1ns/10ps

module MEM_tb();
    // Parameters
    localparam T = 10;      // Clock Period [ns]
    localparam INST_SZ = 32;
    localparam MEM_SZ = 10;

    // Declarations
    reg i_clk;
    reg [INST_SZ-1 : 0]           alu_result;  
    reg [INST_SZ-1 : 0]           debug_addr;  
    reg [INST_SZ-1 : 0]           write_data;  
    reg                           mem_read;              
    reg                           mem_write; 
    reg [1 : 0]                   bhw;             

    wire [INST_SZ-1 : 0]          o_alu_result;
    wire [INST_SZ-1 : 0]          o_read_data;
    wire [INST_SZ-1 : 0]          o_debug_mem;

    integer i;

    // Instantiations
    MEM #(.INST_SZ(INST_SZ), .MEM_SZ(MEM_SZ)) MemoryAccess
        (
        // Sync Signals
        .i_clk(i_clk),
        // Inputs 
        .i_debug_addr(debug_addr), .i_alu_result_E(alu_result), .i_operand_b_E(write_data),
        // Input Control Lines 
        .i_mem_read_M(mem_read), .i_mem_write_M(mem_write), .i_bhw_M(bhw),
        // Outputs
        .o_alu_result_M(o_alu_result), 
        .o_read_data_M(o_read_data), .o_debug_mem(o_debug_mem)
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
        alu_result = {INST_SZ{1'b0}};
        write_data = {INST_SZ{1'b0}};
        mem_read = 1'b0;
        mem_write = 1'b0;

        // BHW Control Line
        bhw = 2'b11;

        // Test stores
        $display("\nTESTING STORES:");
        mem_write = 1'b1;
        for(i = 0; i < 10; i = i + 1)
        begin
            alu_result = i * 4; // Address
            write_data = i; // Data to store
            $display("Data stored: %d at %b", write_data, alu_result[MEM_SZ-1:0]);
            #(T*2);
        end
        mem_write = 1'b0;
        
        #(T*2);

        // Test loads
        $display("\nTESTING LOADS:");
        mem_read = 1'b1;
        for(i = 0; i < 10; i = i + 1)
        begin
            alu_result = i * 4; // Address
            #(T*2);
            if (o_read_data != i)
            begin
                $display("Incorrect Data: %d - (%b) address", o_read_data, i[MEM_SZ-1:0]);
            end 
            else
            begin
                $display("Data loaded: %d from %b", o_read_data, alu_result[MEM_SZ-1:0]);
                $display("DEBUG DATA: %d from %b", o_debug_mem, alu_result[MEM_SZ-1:0]);
            end
        end

        mem_read = 1'b0;

        $display("\nTESTING DEBUG DATA:");
        for(i = 0; i < 10; i = i + 1)
        begin
            debug_addr = i * 4; // Address
            #(T*2);
            if (o_debug_mem != i)
            begin
                $display("Incorrect Data: %d - (%b) address", o_debug_mem, i[MEM_SZ-1:0]);
                $stop;
            end 
            else
            begin
                $display("DEBUG DATA: %d from %b", o_debug_mem, debug_addr[MEM_SZ-1:0]);
            end
        end

        $display("TESTS PASSED!");

        $stop;
    end

endmodule
