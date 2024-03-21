`timescale 1ns / 1ps

module pipeline_uart_test();

// Parameters
    localparam T = 10;              // Clock Period [ns] -> 1/T*10^-8 = 100MHz
    localparam CLKS_PER_BIT = 5208; // 100MHz / 19200 baud rate = 5208 Clocks per bit
    localparam BIT_PERIOD = 52083;  // CLKS_PER_BIT * T_NS = Bit period
    localparam TX_PERIOD = 520830;  // BIT_PERIOD * 10 = TX period
    localparam NUM_TESTS = 11;      // Number of tests
    localparam REGS_MEM = 32;
    localparam DVSR = 326;          // Baud Rate divisor ( Clock/(BaudRate*16) )

    // Declarations
    reg i_clk, i_reset;
    wire tx_to_rx, o_tx, halt, mem_w, enable;
    wire [REGS_MEM-1 : 0] regs, mem, pc;
    wire [31 : 0] inst;
    wire [4 : 0] debug_addr;
    wire [7 : 0] prog_sz, state;
    // UART declaration
    reg i_rd_uart, i_wr_uart; 
    wire o_tx_full, o_rx_empty;
    reg [7 : 0] i_w_data;
    wire [7:0] o_r_data;

    reg tx_data;
    reg [7:0] data_to_send; // Data to be sent
    reg [7:0] sent_data [NUM_TESTS-1:0]; // Data sent during each test
    integer test_num;
    
    // Instantiate the ALU_UART_TOP
    debbugger_top#(
        .N(8),       
        .W(5),      
        .PC_SZ(32),   
        .INST_SZ(32),
        .DATA_SZ(32),
        .SB_TICK(16), 
        .DVSR(DVSR),    
        .FIFO_W(10)
    ) uart_comm (
        // Inputs
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_rx(tx_to_rx),
        .i_register_data(regs),
        .i_memory_data(mem),
        .i_pc(pc),
        .i_halt(halt),
        // Outputs
        .o_tx(o_tx),
        .o_instruction(inst),
        .o_mem_w(mem_w),
        .o_enable(enable),
        .o_addr(debug_addr),
        .o_prog_sz(prog_sz),
        .o_state(state)
    );

    // Instantiate Pipeline
    pipeline #() Pipeline
        (
        // Inputs 
        .i_clk(i_clk), .i_reset(i_reset),
        .i_write(mem_w), .i_enable(enable),
        .i_instruction(inst),
        .i_debug_addr(debug_addr),
        // Outputs
        .o_pc(pc), .o_mem(mem),  .o_halt(halt), .o_reg(regs)
        );
    
    /*
    cpu #(
        // Parameters
        .FIFO_W(10)    
    ) cpu
    (
        // Inputs
        .i_clk(i_clk),                  // Clock
        .i_reset(i_reset),              // Reset
        .i_rx(tx_to_rx),                // UART Rx
        // Outputs
        .o_tx(o_tx),                    // UART Tx
        .o_prog_sz(prog_sz), 
        .o_state(state)  
    );
    */

    // Instantiate the UART module
    uart #(
        .DBIT(8),
        .SB_TICK(16),
        .DVSR(DVSR),
        .FIFO_W(10)
    ) uart (
        .i_clk(i_clk),                  // Clock
        .i_reset(i_reset),              // Reset
        .i_rd_uart(i_rd_uart),          // RX: Read RX FIFO Signal
        .i_wr_uart(i_wr_uart),                   //
        .i_rx(o_tx),                    // RX: RX input bit
        .i_w_data(i_w_data),                    //
        .o_tx_full(o_tx_full),          //
        .o_rx_empty(o_rx_empty),        // RX: RX FIFO Empty Signal
        .o_tx(tx_to_rx),                        //
        .o_r_data(o_r_data)             // RX: RX FIFO Data packed
    );

    // Clock Generation
    always
    begin
        i_clk = 1'b1;
        #(T/2);
        i_clk = 1'b0;
        #(T/2);
    end

    // Reset for the first half cycle
    initial 
    begin
        i_reset = 1'b1;
        #(T/2);
        i_reset = 1'b0;    
    end

    //! Task (automatic) UART_SEND_BYTE: Simulates TX FIFO being written
    task automatic UART_SEND_BYTE();
    integer i;
    begin
        for (i = 0; i < NUM_TESTS; i = i + 1) begin
            // Generate random data to be sent
            if (i == 0)
                data_to_send = 8'b11111110; // LOAD_PROG_SIZE
            else if(i==1)
                data_to_send = 8'b00000010; //PROG_SIZE
            else if(i==2) //! ADDI $ (00100000_00000010_00000000_00000010 -> PASAR INVERTIDO)
                data_to_send = 8'b0000_0010;
            else if(i==3)
                data_to_send = 8'b0000_0000;
            else if(i==4)
                data_to_send = 8'b0000_0010;
            else if(i==5)
                data_to_send = 8'b0010_0000;
            else if(i==6) //! HALT -> 000000_00000_00000_00000_111111
                data_to_send = 8'b00111111;
            else if(i==7)
                data_to_send = 8'b00000000;            
            else if(i==8)
                data_to_send = 8'b00000000;
            else if(i==9)
                data_to_send = 8'b00000000;
            else if(i==10) //! RUN (NO_DEBUG Code)
                data_to_send = 8'b1111_0000;        
            //data_to_send = $random;
            $display("Written bits: %b", data_to_send);
            sent_data[i] = data_to_send;
            i_w_data = data_to_send;
            tx_data = tx_to_rx;
            i_wr_uart = 1'b1;   // Write FIFO
            @(negedge i_clk);   // Assert i_wr_signal for 1 clk cycle to remove word
            i_wr_uart = 1'b0;
            @(negedge i_clk);
            
        end
    end
    endtask 

    // Test cases
    initial
    begin
        // Initialize testbench signals
        i_rd_uart = 1'b0;
        i_wr_uart = 1'b0;
        i_w_data = 0;

        @(negedge i_reset); // Wait for reset to deassert

        //! Test: Send all data
        UART_SEND_BYTE();

        @(posedge halt)
        //#(T*10);

        $display("Programm finished. Receiving Data...");        
        // Read UART
        repeat (66) begin
            @(negedge i_clk);
            #(T*5);
            i_rd_uart = 1'b1;   // Read FIFO           
            $display("Received bits: %b \t(addr: %b)", o_r_data, debug_addr);
            @(negedge i_clk);
            i_rd_uart = 1'b0;
        end

        /*
        //while ((o_rx_empty != 1)) 
        begin
            for (test_num = 0; test_num < 66; test_num = test_num + 1) 
            begin //TODO Ver porque no lee
                @(negedge i_clk);
                $display("Received bits: %b \t(addr: %b)", o_r_data, debug_addr);
                $display("Received bits: %b", o_tx);

                i_rd_uart = 1'b1;   // Read FIFO
                @(negedge i_clk);   // Assert i_rd_signal for 1 clk cycle to remove word
                i_rd_uart = 1'b0;
                @(negedge i_clk);
            end
        end 
        */

        // Stop simulation
        $stop;
    end

 
endmodule