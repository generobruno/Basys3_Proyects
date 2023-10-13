/**
    A FIFO buffer is an "elastic" storage between 2 subsystems. It has 2 control signals, "i_wr" and "i_rd",
    for write and read operations. When i_wr is asserted, the input data is written into the buffer. The 
    read operation, when asserted, the first item of the FIFO (the head) is removed and the next item 
    becomes available.
    One way to implement a FIFO buffer is to add a control circuit to a register file. The registers in the
    register file are arranged as a circular queue with 2 pointers. The "write pointer" points to the head 
    of the queue, and the "read pointer" points to the tail of the queue. The pointer advances one position
    for each write or read operation.
    A FIFO buffer usually contains 2 status signals, "o_full" and "o_empty", to indicate that the FIFO is o_full
    (cannot be written) and o_empty (cannot be read), respectively. One of the 2 conditions occurs when the
    read pointer is equal to the write pointer.
    The most difficult design task of the controller is to derive a mechanism to distinguish the 2 conditions.
    One scheme is to use 2 FFs to keep track of the o_empty and o_full statuses. The FFs are set to 1 and 0 during
    system init and then modified in each clock cycle, according to the values of the "i_wr" and "i_rd" signals.
**/

module fifo
    #(
        // Parameters
        parameter   B       =       8,              // Number of bits in a word
                    W       =       4               // Number of address bits
    )
    (
        // Inputs
        input wire i_clk,                           // Clock
        input wire i_reset,                         // Reset
        input wire i_rd,                            // Read signal
        input wire i_wr,                            // Write signal
        input wire [B-1 : 0] i_w_data,              // Write Data
        // Outputs      
        output wire o_empty,                        // Empty signal
        output wire o_full,                         // Full signal
        output wire [B-1 : 0] o_r_data              // Read Data
    );

    // Signal Declaration
    reg [B-1 : 0] array_reg [2**W-1 : 0];               // Register Array
    reg [W-1 : 0] w_ptr_reg, w_ptr_next, w_ptr_succ;    // Write Pointers (head of queue)
    reg [W-1 : 0] r_ptr_reg, r_ptr_next, r_ptr_succ;    // Read Pointers (tail of queue)
    reg full_reg, empty_reg, full_next, empty_next;     // Empty and Full Status signals
    wire wr_en;                                         // Write enable signal

    //! Register File Write Operation
    always @(posedge i_clk) 
    begin
        if(wr_en)
            array_reg[w_ptr_reg] <= i_w_data;    
    end

    // Register File read Operation
    assign o_r_data = array_reg[r_ptr_reg];
    // Write enable only when FIFO is not o_full
    assign wr_en = i_wr & ~full_reg;

    //! FIFO CONTROL LOGIC
    //! Register for read and write pointers
    always @(posedge i_clk, posedge i_reset) 
    begin
        if(i_reset)             // Reset system
            begin
                w_ptr_reg <= 0;
                r_ptr_reg <= 0;
                full_reg <= 1'b0;
                empty_reg <= 1'b1;
            end
        else                    // Next state assignments
            begin
                w_ptr_reg <= w_ptr_next;
                r_ptr_reg <= r_ptr_next;
                full_reg <= full_next;
                empty_reg <= empty_next;
            end
    end

    //! Next-State Logic for read and write ops
    always @(*) 
    begin
        // Successive pointer values
        w_ptr_succ = w_ptr_reg + 1;
        r_ptr_succ = r_ptr_reg + 1;
        // DEFAULT: Keep old values
        w_ptr_next = w_ptr_reg;
        r_ptr_next = r_ptr_reg;
        full_next = full_reg;
        empty_next = empty_reg;

        case ({i_wr, i_rd})
            2'b01:  // READ
                begin
                    if (~empty_reg) // NOT EMPTY
                    begin
                        r_ptr_next = r_ptr_succ;
                        full_next = 1'b0;
                        if(r_ptr_succ == w_ptr_reg)
                            empty_next = 1'b1;
                    end
                end
            2'b10:  // WRITE
                begin
                    if (~full_reg) // NOT FULL
                    begin
                        w_ptr_next = w_ptr_succ;
                        empty_next = 1'b0;
                        if(w_ptr_succ==r_ptr_reg)
                            full_next = 1'b1;
                    end
                end
            2'b11:  // WRITE AND READ
                begin
                    w_ptr_next = w_ptr_succ;
                    r_ptr_next = r_ptr_succ;
                end
            default: // TODO Revisar
                begin
                    w_ptr_next = w_ptr_reg;
                    r_ptr_next = r_ptr_reg;
                    full_next = full_reg;
                    empty_next = empty_reg;
                end
        endcase    
    end

    //! Output Logic
    assign o_full = full_reg;
    assign o_empty = empty_reg;

endmodule