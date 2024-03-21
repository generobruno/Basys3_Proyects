/*

*/

module debbugger_top
    #(
        parameter   N       =   8,          // UART Data Lenght
                    W       =   5,          // Number of address bits for Reg mem
                    PC_SZ   =   32,         // Size of Program Counter
                    INST_SZ =   32,         // Size of Instructions
                    DATA_SZ =   32,         // Size of Data
                    SB_TICK =   16,         // # Ticks for stop bits (16/24/32 for 1/1.5/2 bits)
                    DVSR    =   326,        // Baud Rate divisor ( Clock/(BaudRate*16) )
                    FIFO_W  =   5           // # Address bits of FIFO ( # Words in FIFO = 2^FIFO_W )
    )
    (
        // Sync Signales
        input wire                          i_clk,
        input wire                          i_reset,
        //  Inputs
        input wire                          i_rx,
        input wire      [DATA_SZ-1 : 0]     i_register_data,
        input wire      [DATA_SZ-1 : 0]     i_memory_data,
        input wire      [PC_SZ-1 : 0]       i_pc,
        input wire                          i_halt,
        //  Outputs
        output wire                         o_tx,
        output wire     [INST_SZ-1 : 0]     o_instruction,
        output wire                         o_mem_w,
        output wire                         o_enable,
        output wire     [W-1 : 0]           o_addr,

        output wire     [7 : 0]             o_prog_sz,
        output wire     [7 : 0]             o_state   
    );

    //! Signal Declaration
    wire [N-1 : 0] r_data_data;
    wire rx_empty_fifo_empty;
    wire tx_full_fifo_full;
    wire [N-1 : 0] tx_data_w_data;
    wire rd_rd_uart;
    wire wr_wr_uart;

    //! Instantiations
    uart #(
        .DBIT(N),
        .SB_TICK(SB_TICK),
        .DVSR(DVSR),
        .FIFO_W(FIFO_W)
    ) uart_unit (
        // Sync Signals
        .i_clk(i_clk),
        .i_reset(i_reset),
        // Inputs
        .i_rd_uart(rd_rd_uart),
        .i_wr_uart(wr_wr_uart),
        .i_rx(i_rx),
        .i_w_data(tx_data_w_data),
        // Outputs
        .o_tx_full(tx_full_fifo_full),
        .o_rx_empty(rx_empty_fifo_empty),
        .o_tx(o_tx),
        .o_r_data(r_data_data)
    );

    uart_interface #(
        .N(N),     
        .W(W),
        .PC_SZ(PC_SZ),   
        .INST_SZ(INST_SZ),
        .DATA_SZ(DATA_SZ) 
    ) debugger (
        // Sync Signals
        .i_clk(i_clk),
        .i_reset(i_reset),
        // PIPELINE ->
        .i_halt(i_halt),
        .i_reg_read(i_register_data),
        .i_mem_read(i_memory_data),
        .i_pc(i_pc),
        // UART ->
        .i_data(r_data_data),
        .i_fifo_empty(rx_empty_fifo_empty),
        .i_fifo_full(tx_full_fifo_full),
        // -> UART
        .o_tx_data(tx_data_w_data),
        .o_wr(wr_wr_uart),
        .o_rd(rd_rd_uart),
        // -> PIPELINE
        .o_write_mem(o_mem_w),
        .o_enable(o_enable),
        .o_inst(o_instruction),
        .o_addr(o_addr),

        .o_prog_sz(o_prog_sz),
        .o_state(o_state)
    );


endmodule