/**

**/

module instruction_mem
    #(
        // Parameters
        parameter   B   =   32,     // Number of bits
        parameter   W   =   10,     // Number of address bits
        parameter   PC  =   32

    )
    (
        // Inputs
        input wire                      i_clk,                      // Clock
        input wire                      i_reset,                    // Reset
        input wire                      i_write,                    // Write Control Line
        input [PC-1 : 0]                i_addr,                     // Address (Program Counter)
        input [B-1 : 0]                 i_data,                     // Instructions to write
        // Outputs
        output [B-1 : 0]                o_data                      // Instructions to Read
    );

    //! Signal Declaration
    // Instruction memory
    reg [B-1 : 0]       array_reg [2**W-1 : 0];
    // Mask to select instruction. Default: 32 Instructions: (25-5-2) 00000000000000000000_1111111111_00
    reg [PC-1 : 0]      mask = {{(PC - W - 2){1'b0}} , {W{1'b1}} , 2'b00};
    // Write Pointers
    reg [W-1 : 0]       write_ptr, write_ptr_next, write_ptr_succ;

    // Body 
    // Write Instructions
    always @(posedge i_clk) 
    begin
        if(i_write)
            begin
                // Write Operation
                array_reg[write_ptr] <= i_data;
            end 
    end

    // Update Instruction Pointer
    always @(posedge i_clk)  
    begin
        if(i_reset)
        begin
            write_ptr <= 0;
        end
        else
        begin
            write_ptr <= write_ptr_next;
        end
    end

    always @(*) 
    begin
        write_ptr_succ = write_ptr + 1;
        write_ptr_next = write_ptr;

        if(i_write)
        begin
            write_ptr_next = write_ptr_succ;
        end    
    end

    initial
    begin
        write_ptr <= 0;
    end

    //! Assignments //TODO Ver como enmascarar i_addr para seleccionar la instr
    assign o_data = array_reg[(i_addr & mask) >> 2];

endmodule