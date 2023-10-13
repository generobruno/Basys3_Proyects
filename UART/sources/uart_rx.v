/**
    UART Receiver Module
**/

module uart_rx
    #(
        // Parameters
        parameter   DBIT        =       8,      // # Data bits
                    SB_TICK     =       16      // # Ticks for stop bits (1 stop bit -> 16 ticks)
    )
    (
        // Inputs
        input wire                      i_clk,              // Clock
        input wire                      i_reset,            // Reset
        input wire                      i_rx,               // Data received
        input wire                      i_s_tick,           // Enable tick from Baud-Rate generator
        // Outputs
        output reg                      o_rx_done_tick,     // Done Status Signal
        output wire [DBIT-1 : 0]        o_data              // Data processed
    );

    //! State Declaration
    localparam [1:0]
        idle    =   2'b00,                  // Waiting
        start   =   2'b01,                  // Processing Start bit
        data    =   2'b10,                  // Processing Data bits
        stop    =   2'b11;                  // Processing Stop bit/s

    //! Signal declaration
    reg [1:0]           state_reg, state_next;      // State registers
    reg [3:0]           s_reg, s_next;              // Number of sampling ticks
    reg [2:0]           n_reg, n_next;              // Number of Data bits received in data state
    reg [DBIT-1:0]      b_reg, b_next;              // Data bits shifted and reassembled

    //! FSMD States and data registers
    always @(posedge i_clk, posedge i_reset) 
    begin
        if (i_reset)        // Reset system 
            begin
                state_reg <= idle;
                s_reg <= 0;
                n_reg <= 0;
                b_reg <= 0;
            end
        else                // Next state assignments
            begin
                state_reg <= state_next;
                s_reg <= s_next;
                n_reg <= n_next;
                b_reg <= b_next;
            end
    end

    //! Next-State Logic
    always @(*) 
    begin
        // Initial assignments
        state_next = state_reg;
        o_rx_done_tick = 1'b0;
        s_next = s_reg;
        n_next = n_reg;
        b_next = b_reg;

        // Oversampling procedure (16 times the baud rate)
        case (state_reg)
            idle:       //! IDLE STATE
                begin
                    if (~i_rx)      // Received Start Bit
                        begin
                            state_next = start;     // Start receiveing
                            s_next = 0;             // Start counting sampling ticks
                        end
                end
            start:      //! START BIT STATE
                begin           
                    if (i_s_tick)               // Sampling tick received
                        if (s_reg == 7)             // Middle point of start bit
                            begin
                                state_next = data;      // Start processing data bits
                                s_next = 0;             // Reset sampling ticks counter
                                n_next = 0;             // Start counting data bits received
                            end
                        else                        // Otherwise...
                            begin
                                s_next = s_reg + 1;     // ... keep counting sampling ticks
                            end
                end
            data:       //! DATA BITS STATE
                begin
                    if (i_s_tick)           // Sampling tick received
                        if (s_reg == 15)            // Middle point of data bit
                            begin
                                s_next = 0;                         // Reset sampling tick counter
                                b_next = { i_rx, b_reg[7 : 1] };    // Retrieve and shift data value 
                                if (n_reg == (DBIT - 1))            // If we received all data bits...
                                    state_next = stop;                  // ... start counting stop bits
                                else                                // Otherwise...
                                    n_next = n_reg + 1;                 // ... keep counting data bits
                            end
                        else                // Otherwise...
                            s_next = s_reg + 1;     // ... keep counting sampling ticks
                end
            stop:       //! STOP BIT/S STATE
                begin
                    if (i_s_tick)           // Sampling tick received
                        if (s_reg == (SB_TICK - 1))     // If we received all stop bits
                            begin
                                state_next = idle;          // Stop receiveing
                                o_rx_done_tick = 1'b1;      // Assert done state
                            end
                        else                            // Otherwise...
                            s_next = s_reg + 1;             // ... keep counting sampling ticks
                end     
            default: state_next = idle;     // Default state: Idle
        endcase
    end

    //! Output Data
    assign o_data = b_reg;

endmodule

