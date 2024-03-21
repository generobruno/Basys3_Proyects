/*

*/

module cpu 
    #(
        // Parameters
        parameter   INST_SZ     =       32,     // Instruction Size
                    PC_SZ       =       32,     // Program Counter Size
                    DATA_SZ     =       32,     // Data Size
                    UART_SZ     =       8,      // UART Data Bits
                    W           =       5,      // Address Bits for Mem/Reg
                    SB_TICK     =       16,     // # Ticks for stop bits (16/24/32 for 1/1.5/2 bits)
                    DVSR        =       326,    // Baud Rate divisor ( Clock/(BaudRate*16) )
                    FIFO_W      =       2       // # Address bits of FIFO ( # Words in FIFO = 2^FIFO_W )
    )
    (
        // Inputs
        input wire  i_clk,              // Clock
        input wire  i_reset,            // Reset
        input wire  i_rx,               // UART Rx
        // Outputs
        output wire o_tx,               // UART Tx
        output wire     [7 : 0]             o_prog_sz, //TODO REMOVE
        output wire     [7 : 0]             o_state  //TODO REMOVE
    );

    //! Signal Declaration
    wire    clk;                            // Stable Clock
    wire    locked;                         // Locked Clock Signal
    wire    enable;                         // Enable Execution Control Line
    wire    write;                          // Wirte Instructions Control Line
    wire    halt;                           // Stop Execution Control Line
    wire [INST_SZ-1 : 0]    inst;           // Instructions to Load
    wire [W-1 : 0]          debug_addr;     // Debug Address for mem/reg
    wire [DATA_SZ-1 : 0]    mem, regs;      // Mem/Reg Debug Data
    wire [PC_SZ-1 : 0]      pc;             // Current Program Counter

    //! Instantiations
    // Pipeline
    pipeline #(
        // Parameters
        .INST_SZ(INST_SZ),      
        .PC_SZ(PC_SZ),           
        .REG_SZ(W),       
        .MEM_SZ(W)
        ) Pipeline
        (
        // Inputs 
        .i_clk(clk), .i_reset(i_reset),
        .i_write(write), .i_enable(enable & locked),
        .i_instruction(inst),
        .i_debug_addr(debug_addr),
        // Outputs
        .o_pc(pc), .o_mem(mem),  .o_halt(halt), .o_reg(regs)
        );

    // Debugger
    debbugger_top #(
        .N(UART_SZ),       
        .W(W),      
        .PC_SZ(PC_SZ),   
        .INST_SZ(INST_SZ),
        .DATA_SZ(DATA_SZ),
        .SB_TICK(SB_TICK), 
        .DVSR(DVSR),    
        .FIFO_W(FIFO_W)
    ) Debugger (
        // Inputs
        .i_clk(clk), .i_reset(i_reset),
        .i_rx(i_rx),
        .i_register_data(regs), .i_memory_data(mem), .i_pc(pc),
        .i_halt(halt),
        // Outputs
        .o_tx(o_tx),
        .o_instruction(inst),
        .o_mem_w(write), .o_enable(enable),
        .o_addr(debug_addr),
        .o_prog_sz(o_prog_sz), //TODO Remove
        .o_state(o_state)     //TODO Remove
    );

    // Clock
    clk_wiz ClockWizard (
        // Inputs
        .clk_in(i_clk),
        .reset(i_reset),
        // Outputs
        .locked(locked),
        .clk_out(clk)
    );
    
endmodule