/*

*/

module uart_interface
    #(
        N       =   8,          // UART Data Lenght
        W       =   5,          // Number of address bits for Reg mem
        PC_SZ   =   32,         // Size of Program Counter
        INST_SZ =   32,         // Size of Instructions
        DATA_SZ =   32          // Size of Data
    )
    (
        // Sync Signals
        input wire i_clk,                           // Clock Signal
        input wire i_reset,                         // Reset Signal

        // PIPELINE ->  
        input wire i_halt,                          // Stop Pipeline Execution Signal
        input wire [DATA_SZ-1 : 0] i_reg_read,      // Data from register memory
        input wire [DATA_SZ-1 : 0] i_mem_read,      // Data from data memory
        input wire [PC_SZ-1 : 0] i_pc,              // Current Program Counter
        // UART ->  
        input wire [N-1 : 0] i_data,                // Data to be read
        input wire i_fifo_empty,                    // Rx FIFO Empry Signal
        input wire i_fifo_full,                     // Tx FIFO Full Signal

        // -> UART  
        output wire [N-1 : 0] o_tx_data,            // Data to be written
        output wire o_wr,                           // Write UART Signal
        output wire o_rd,                           // Read UART Signal
        // -> PIPELINE  
        output wire o_write_mem,                    // Write Instruction Memory Signal
        output wire o_enable,                       // Enable Pipeline Execution Signal
        output wire [INST_SZ-1 : 0] o_inst,         // Instruction to write
        output wire [W-1 : 0] o_addr,               // Register/Memory Debug Address

        /*Test Variables */ 
        output wire [7:0] o_prog_sz,        // //TODO Remover
        output wire [7:0] o_state           // // TODO REMOVER
        
    );
    
    //! Signal Declaration
    reg [2 : 0]             counter, counter_next;              // Auxiliar Counter (for bytes)
    reg [W-1 : 0]           reg_counter, reg_counter_next;      // Auxiliar Counter (for number mem/reg size)
    reg [INST_SZ-1 : 0]     inst_reg, inst_reg_next;            // Instruction Register
    reg [N-1 : 0]           to_tx_fifo, to_tx_fifo_next;        // To UART Tx Registers
    reg                     rd_reg, wr_reg;                     // Read and Write UART Registers
    reg                     write_mem_reg;                      // Write Instructions Register
    reg                     enable;                             // Enable Register
    reg [7 : 0]             mode_reg, mode_reg_next;            // State Register
    reg [7 : 0]             wait_mode_reg, wait_mode_reg_next;  // Next-State after Wait
    reg [7 : 0]             prog_size_reg, prog_size_reg_next;  // Program Size
    reg [7 : 0]             inst_n, inst_n_next;                // Number of instructions received
    reg [W-1 : 0]           addr_reg, addr_reg_next;            // Debug Address

    //! State Declaration
    localparam [7:0] 
        IDLE                =   8'b0000_0011,
        START               =   8'b0000_0111,
        LOAD_PROG_SIZE      =   8'b1111_1110,
        LOAD_PROG           =   8'b1111_1101,
        WRITE_INST          =   8'b1111_1111,
        DEBUG               =   8'b1111_1100,
        PREV_SEND           =   8'b0011_1001,
        SEND_STATE_REG      =   8'b1111_1011,
        SEND_STATE_MEM      =   8'b1111_1010,
        SEND_PC             =   8'b1111_1001,
        END_SEND            =   8'b1111_0010,
        END_DEBUG           =   8'b1111_1000,
        NEXT                =   8'b0000_0001,
        WAIT                =   8'b0000_0000,
        WAIT_SEND           =   8'b1000_0000,
        NO_DEBUG            =   8'b1111_0000,
        RESET               =   8'b0011_0000;

    //! Assignments
    assign o_tx_data    =   to_tx_fifo;     
    assign o_inst       =   inst_reg;       
    assign o_write_mem  =   write_mem_reg;  
    assign o_addr       =   addr_reg;       
    assign o_enable     =   enable;         
            
    assign o_rd         =   rd_reg;         
    assign o_wr         =   wr_reg;         

    assign o_prog_sz    =   prog_size_reg;  
    assign o_state      =   mode_reg;       
    
    //! FSMD States and Data Registers
    always @(posedge i_clk, posedge i_reset)
    begin
        if(i_reset)
        begin
            // States
            mode_reg        <=      IDLE;
            wait_mode_reg   <=      IDLE;
            // Control
            to_tx_fifo      <=      {N{1'b0}};
            counter         <=      {3{1'b0}};
            reg_counter     <=      {W{1'b0}};
            // Data
            inst_reg        <=      {32{1'b0}};
            prog_size_reg   <=      {8{1'b0}};
            inst_n          <=      {8{1'b0}};
            addr_reg        <=      {W{1'b0}};
        end
        else 
        begin
            // States
            mode_reg        <=      mode_reg_next;
            wait_mode_reg   <=      wait_mode_reg_next;
            // Control
            to_tx_fifo      <=      to_tx_fifo_next;
            counter         <=      counter_next;
            reg_counter     <=      reg_counter_next;
            // Data
            inst_reg        <=      inst_reg_next;
            prog_size_reg   <=      prog_size_reg_next;
            inst_n          <=      inst_n_next;
            addr_reg        <=      addr_reg_next;
        end
        
    end
    
    //! Next-State Logic
    always@(*)
    begin
        // Initial Assignments
        inst_reg_next       = inst_reg;
        counter_next        = counter;
        to_tx_fifo_next     = to_tx_fifo;
        mode_reg_next       = mode_reg;
        wait_mode_reg_next  = wait_mode_reg;
        prog_size_reg_next  = prog_size_reg;
        inst_n_next         = inst_n;
        addr_reg_next       = addr_reg;
        reg_counter_next    = reg_counter;

        case(mode_reg)
                        
            IDLE: //! Idle State
            begin
                if(!i_fifo_empty)
                    mode_reg_next = START;
            end
            
            START: //! Start Decoding Next State
            begin
                if(i_fifo_empty)
                begin
                    mode_reg_next = WAIT;
                    wait_mode_reg_next = START;
                end
                else 
                begin
                    mode_reg_next = i_data;
                end
            end
            
            LOAD_PROG_SIZE: //! Load Program Size
            begin
                if(i_fifo_empty)
                begin
                    mode_reg_next = WAIT;
                    wait_mode_reg_next = LOAD_PROG_SIZE; 
                end
                else 
                begin
                    prog_size_reg_next = i_data;
                    mode_reg_next = LOAD_PROG;
                end
            end
            
            LOAD_PROG: //! Load Program (Instruction by Instruction)
            begin
                if(i_fifo_empty)
                begin
                    mode_reg_next = WAIT;
                    wait_mode_reg_next = LOAD_PROG;
                end
                else 
                begin
                    inst_reg_next[8*(counter)+:8] = i_data;
                    counter_next = counter +1;
                    if(counter == 3)
                    begin
                        counter_next = 3'b000;
                        inst_n_next = inst_n + 1;
                        mode_reg_next = WRITE_INST;
                    end
                end
            end
            
            WRITE_INST: //! Write Single Instruction (Byte by Byte)
            begin
                if(inst_n == prog_size_reg)
                begin
                    mode_reg_next = START;
                    inst_n_next = 8'b00000000;
                end
                else 
                begin
                    mode_reg_next = LOAD_PROG;
                end
            end
            
            DEBUG:  //! Start Debug Session
            begin
                if(i_data == NEXT)
                begin
                    mode_reg_next = PREV_SEND;
                end
                else if(i_data == END_DEBUG)
                begin
                    mode_reg_next = RESET;
                end
            end
            
            NO_DEBUG: //! Run program to the end
            begin
                if(i_halt)
                begin
                    mode_reg_next = PREV_SEND;
                end        
            end
            
            PREV_SEND: //! Prepare for sending Data
            begin
                if(i_fifo_full)
                begin
                    mode_reg_next = WAIT_SEND;
                    wait_mode_reg_next = PREV_SEND;
                end
                else 
                begin
                    to_tx_fifo_next = i_reg_read[0+:8];
                    mode_reg_next = SEND_STATE_REG;
                    counter_next = counter + 1;
                end
            end
            
            SEND_STATE_REG: //! Send Registers to UART
            begin
                if(i_fifo_full)
                begin
                    mode_reg_next           = WAIT_SEND;
                    wait_mode_reg_next      = SEND_STATE_REG;
                end
                else 
                begin
                    if(reg_counter < 32)
                    begin
                        to_tx_fifo_next = i_reg_read[8*counter+:8];
                        counter_next = counter +1;
                        if(counter == 3)
                        begin
                            counter_next = 0;
                            addr_reg_next = reg_counter+1;
                            reg_counter_next = reg_counter+1;
                        end
                    end
                    else 
                    begin
                        reg_counter_next = 5'b00000;
                        mode_reg_next = SEND_STATE_MEM;
                    end
                end
            end
                
            SEND_STATE_MEM: //! Send Memory to UART
            begin
                if(i_fifo_full)
                begin
                    mode_reg_next = WAIT_SEND;
                    wait_mode_reg_next   = SEND_STATE_MEM;
                end
                else 
                begin
                    if(reg_counter < 32)
                    begin
                        to_tx_fifo_next = i_mem_read[8*counter+:8];
                        counter_next = counter +1;
                        if(counter == 3)
                        begin
                            counter_next = 0;
                            addr_reg_next = reg_counter+1;
                            reg_counter_next = reg_counter+1;
                        end
                    end
                    else 
                    begin
                        reg_counter_next = 5'b00000;
                        mode_reg_next = SEND_PC;
                    end
                end
            end
                
            SEND_PC: //! Send PC to UART
            begin
                if(i_fifo_full)
                begin
                    mode_reg_next = WAIT_SEND;
                    wait_mode_reg_next   = SEND_PC;
                end
                else 
                begin   
                    to_tx_fifo_next = i_pc[8*counter+:8];
                    counter_next = counter +1;
                    if(counter == 3)
                    begin
                        counter_next = 3'b000;
                        mode_reg_next = END_SEND;
                    end
                end 
            end

            END_SEND: //! End Send State
            begin
                if(i_halt)
                begin
                    mode_reg_next = RESET;        
                end
                else 
                begin
                    mode_reg_next = DEBUG;
                end    
            end

            WAIT: //! Wait State
            begin    
                if(!i_fifo_empty)
                    mode_reg_next = wait_mode_reg;
            end

            WAIT_SEND: //! Wait before send data
            begin
                if(!i_fifo_full)
                    mode_reg_next = wait_mode_reg;
            end

            RESET: //! Reset
            begin
                mode_reg_next = IDLE;        
            end

            default: 
            begin
                //TODO Poner cosas que se escriben en 0 (instructions, counter, address, etc)
            end

        endcase
        
    end

    //! Output Logic
    always @(*)
    begin
        case(mode_reg)
            IDLE: 
            begin
                rd_reg = 1'b0;
                wr_reg = 1'b0;
                write_mem_reg = 1'b0;
                enable = 1'b0;
            end
            
            START: 
            begin
                rd_reg = 1'b1;
                wr_reg = 1'b0;
                write_mem_reg = 1'b0;
                enable = 1'b0;
            end

            LOAD_PROG_SIZE: 
            begin
                rd_reg = 1'b1;
                wr_reg = 1'b0;
                write_mem_reg = 1'b0;
                enable = 1'b0;
            end

            LOAD_PROG: 
            begin
                rd_reg = 1'b1;
                wr_reg = 1'b0;
                write_mem_reg = 1'b0;
                enable = 1'b0;
            end

            WRITE_INST: 
            begin
                rd_reg = 1'b0;
                wr_reg = 1'b0;
                write_mem_reg = 1'b1;
                enable = 1'b0;
            end

            DEBUG: 
            begin
                rd_reg = 1'b1;
                wr_reg = 1'b0;
                write_mem_reg = 1'b0;
                enable = 1'b1;
            end

            NO_DEBUG: 
            begin
                rd_reg = 1'b0;
                wr_reg = 1'b0;
                write_mem_reg = 1'b0;
                enable = 1'b1;
            end

            PREV_SEND: 
            begin
               rd_reg = 1'b0;
               wr_reg = 1'b0;
               write_mem_reg = 1'b0;
               enable = 1'b0; 
            end

            SEND_STATE_REG: 
            begin
                rd_reg = 1'b0;
                wr_reg = 1'b1;
                write_mem_reg = 1'b0;
                enable = 1'b0;
            end

            SEND_STATE_MEM: 
            begin
                rd_reg = 1'b0;
                wr_reg = 1'b1;
                write_mem_reg = 1'b0;
                enable = 1'b0;
            end

            SEND_PC: 
            begin
                rd_reg = 1'b0;
                wr_reg = 1'b1;
                write_mem_reg = 1'b0;
                enable = 1'b0;
            end
            
            END_SEND: 
            begin
                rd_reg = 1'b0;
                wr_reg = 1'b1;
                write_mem_reg = 1'b0;
                enable = 1'b0;
            end

            WAIT: 
            begin
                rd_reg = 1'b0;
                wr_reg = 1'b0;
                write_mem_reg = 1'b0;
                enable = 1'b0;
            end

            WAIT_SEND: 
            begin
                rd_reg = 1'b0;
                wr_reg = 1'b0;
                write_mem_reg = 1'b0;
                enable = 1'b0;
            end

            default: 
            begin
                rd_reg = 1'b0;
                wr_reg = 1'b0;
                write_mem_reg = 1'b0;
                enable = 1'b0;
            end
        endcase
    end
    
endmodule