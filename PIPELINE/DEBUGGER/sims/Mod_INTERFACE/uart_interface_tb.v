`timescale 1ns / 1ps

module debbugger_test();

// Parameters
    localparam T = 10;              // Clock Period [ns]
    localparam CLKS_PER_BIT = 5208; // 50MHz / 19200 baud rate = 2604 Clocks per bit
    localparam BIT_PERIOD = 52083;  // CLKS_PER_BIT * T_NS = Bit period
    localparam TX_PERIOD = 520830;  // BIT_PERIOD * 10 = TX period
    localparam NUM_TESTS = 11;       // Number of tests

    // Declarations
    reg i_clk, i_reset, i_rd_uart, i_rx, i_wr_uart, tx_data, i_enable;
    reg [4:0] i_mem_addr; 
    reg [31:0] i_pc;
    wire o_tx_full, o_rx_empty, tx_to_rx, o_tx;
    wire[31:0] mem_data;
    reg [7:0] i_w_data;
    wire [7:0] o_r_data;
    wire [31: 0] o_inst;
    wire [31:0] mem_addr;
    wire [7:0] prog_sz;
    wire [7:0] state;
    wire [31:0] o_pc;
    reg [7:0] data_to_send; // Data to be sent
    reg [7:0] sent_data [NUM_TESTS-1:0]; // Data sent during each test
    wire mem_read;
    wire mem_write;
    integer received_data_mismatch;
    integer test_num;
    
    
    // Instantiate the ALU_UART_TOP
    debbugger_top#(
        .PC(32),
        .REG_ADDR(5),
        .INST_SZ(32)
    ) uart_comm (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_rx(tx_to_rx),
        .i_register_data(),
        .i_memory_data(mem_data),
        .i_pc(o_pc),
        .o_instruction(o_inst),
        .o_mem_w(mem_write),
        .o_mem_r(mem_read),
        .o_program_mem_addr(mem_addr),
        .o_addr_ID(),
        .o_addr_M(),
        .o_prog_sz(prog_sz),
        .o_state(state),
        .o_tx(o_tx)
    );

    pc #(
        .PC_SZ(32)
    ) pc (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_enable(i_enable),
        .i_pc(i_pc),
        .o_pc(o_pc)
    );

    
    instruction_mem #(
        .B(32),
        .W(5),
        .PC(32)
    ) inst_mem (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_write(mem_write),
        .i_addr(o_pc),
        .i_data(o_inst),
        .o_data(mem_data)
    );

    // Instantiate the UART module
    uart #(
        .DBIT(8),
        .SB_TICK(16),
        .DVSR(326),
        .FIFO_W(5)
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
            else if(i==2)
                data_to_send = 8'b00000011;
            else if(i==3)
                data_to_send = 8'b00000000;
            else if(i==4)
                data_to_send = 8'b00000000;
            else if(i==5)
                data_to_send = 8'b00000000;
            else if(i==6)
                data_to_send = 8'b00000101;
            else if(i==7)
                data_to_send = 8'b00000000;            
            else if(i==8)
                data_to_send = 8'b00000000;
            else if(i==9)
                data_to_send = 8'b00000000;
            else if(i==10)
                data_to_send = 8'b00111001;        
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
        i_enable = 1'b0;
        i_pc = 0;
        received_data_mismatch = 0;

        @(negedge i_reset); // Wait for reset to deassert

        //! Test: Send all data
        UART_SEND_BYTE();
        #(TX_PERIOD*(NUM_TESTS+5));
        
        
        // Test Case: Write random data into TX FIFO
        while ((o_rx_empty != 1) && (received_data_mismatch != 1)) begin
            for (test_num = 0; test_num < NUM_TESTS; test_num = test_num + 1) begin
                @(negedge i_clk);
                $display("Received bits: %b", o_r_data);

                // Compare received data with stored sent data
                if (o_r_data !== sent_data[test_num]) begin
                    $display("Data Mismatch! Received data does not match sent data.");
                    received_data_mismatch = 1;
                end

                i_rd_uart = 1'b1;   // Read FIFO
                @(negedge i_clk);   // Assert i_rd_signal for 1 clk cycle to remove word
                i_rd_uart = 1'b0;
                @(negedge i_clk);
            end
        end 
        
        i_mem_addr = 5'b0000;
        i_enable = 1'b1;
        for (test_num = 0; test_num < prog_sz; test_num = test_num + 1) begin
                @(negedge i_clk);
                $display("Instruction MEMMORY");
                $display("\%b: %b", test_num, mem_data);

                // Compare received data with stored sent data

                i_pc = test_num;   // Read FIFO
                #(1000);
           
            end
        
               

        if (received_data_mismatch == 0)
            $display("\nAll received data matches sent data. TX Test Passed!");
        else
            $display("\nFailed Receiving Data. Check UART FIFO_W Size.");

        // Stop simulation
        $stop;
    end

 
endmodule