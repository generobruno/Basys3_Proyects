module uart_alu_top
    #(
        // Parameters
        parameter       DATA_BITS   =       8,      // Data Bits Size
                        OPCODE_BITS =       6,      // Operation Code Size
                        SB_TICK     =       16,     // # Ticks for stop bits (16/24/32 for 1/1.5/2 bits)
                        DVSR        =       326,    // Baud Rate divisor ( Clock/(BaudRate*16) )
                        FIFO_W      =       2,      // # Address bits of FIFO ( # Words in FIFO = 2^FIFO_W )
                        SAVE_COUNT  =       3       // # Data to save in the Interface
    )
    (
        // Inputs
        input wire i_clk,                   // Clock
        input wire i_reset,                 // Reset
        input wire i_rx,                    // UART Rx
        // Outputs
        output wire o_tx                    // UART Tx
    );

    //! Signal Declaration
    wire rx_empty;                                  // Receiver FIFO Empty Signal
    wire tx_full;                                   // Transmitter FIFO Full Signal
    wire [DATA_BITS-1 :0]       r_data;             // UART Receiver Input
    wire [DATA_BITS-1 :0]       result_data;        // ALU Result Register
    wire [DATA_BITS-1 :0]       w_data;             // UART Data Transmitted
    wire wr_uart;                                   // Receiver FIFO Input Read Signal
    wire rd_uart;                                   // Transmitter FIFO Input Write Signal
    wire [DATA_BITS-1 :0]       op_a;               // ALU Operand A
    wire [DATA_BITS-1 :0]       op_b;               // ALU Operand B
    wire [OPCODE_BITS-1 :0]     op_code;            // ALU Operation Code
    wire                        tx_done_tick;       // Transmission Done Signal

    //! Instantiations
    // UART Module
    uart_top #(
        // Parameters
        .DBIT(DATA_BITS),
        .SB_TICK(SB_TICK),
        .DVSR(DVSR),
        .FIFO_W(FIFO_W)
    ) uart_unit (
        // Inputs
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_rd_uart(rd_uart),
        .i_wr_uart(wr_uart),
        .i_rx(i_rx),
        .i_w_data(w_data),
        // Outputs
        .o_tx_full(tx_full),
        .o_rx_empty(rx_empty),
        .o_tx(o_tx),
        .o_tx_done_tick(tx_done_tick),
        .o_r_data(r_data)
    );

    // ALU Module
    alu #(
        // Parameters
        .N(DATA_BITS),  
        .NSel(OPCODE_BITS)  
    ) alu_unit (
        // Inputs
        .i_alu_A(op_a),
        .i_alu_B(op_b),
        .i_alu_Op(op_code),
        // Outputs
        .o_alu_Result(result_data)
    );

    // UART-ALU Interface Module
    uart_alu_interface #(
        // Parameters
        .DATA_WIDTH(DATA_BITS),
        .SAVE_COUNT(SAVE_COUNT),
        .OP_SZ(DATA_BITS),
        .OPCODE_SZ(OPCODE_BITS)
    ) uart_alu_interface_unit (
        // Inputs
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_rx_empty(rx_empty),
        .i_tx_full(tx_full),
        .i_r_data(r_data),
        .i_result_data(result_data),
        .i_tx_done_tick(tx_done_tick),
        // Outputs
        .o_w_data(w_data),
        .o_wr_uart(wr_uart),
        .o_rd_uart(rd_uart),
        .o_op_a(op_a),
        .o_op_b(op_b),
        .o_op_code(op_code)
    );

endmodule
