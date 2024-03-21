/**

**/

module MEM_WB_reg
    #(
        // Parameters
        parameter INST_SZ = 32
    )
    (
        // Inputs
        input wire                      i_clk,                      // Clock
        input wire                      i_reset,                    // Reset
        input wire                      i_enable,                   // Write Control Line
        input wire                      i_halt,                     // Halt Control Line
        input wire                      i_reg_write,                // RegWrite Control Line
        input wire                      i_mem_to_reg,               // MemToReg Control Line
        input wire                      i_bds_sel,                  // BDSSel Control Line
        input wire [INST_SZ-1 : 0]      i_read_data,                // Read Data
        input wire [INST_SZ-1 : 0]      i_alu_result,               // ALU Result
        input wire [4 : 0]              i_write_register,           // Write Register
        input wire [INST_SZ-1 : 0]      i_bds,                      // BDS
        // Outputs
        output wire                     o_halt,                     // Halt Control Line
        output wire                     o_reg_write,                // RegWrite Control Line
        output wire                     o_mem_to_reg,               // MemToReg Control Line
        output wire                     o_bds_sel,                  // BDSSel Control Line
        output wire [INST_SZ-1 : 0]     o_read_data,                // Read Data
        output wire [INST_SZ-1 : 0]     o_alu_result,               // ALU Result
        output wire [4 : 0]             o_write_register,           // Write Register
        output wire [INST_SZ-1 : 0]     o_bds                       // BDS
    );

    //! Signal Definition
    reg halt;
    reg reg_write;
    reg mem_to_reg;
    reg bds_sel;
    reg [INST_SZ-1 : 0] read_data;
    reg [INST_SZ-1 : 0] alu_result;
    reg [4 : 0]         write_register;
    reg [INST_SZ-1 : 0] bds;

    // Body
    always @(posedge i_clk) 
    begin
        if(i_reset)
        begin
            halt                <=      0;
            reg_write           <=      0;                
            mem_to_reg          <=      0;                
            bds_sel             <=      0;           
            read_data           <=      0;                
            alu_result          <=      0;                
            write_register      <=      0;                    
            bds                 <=      0;       

        end
        else if(i_enable)
        begin
            halt                <=      i_halt;
            reg_write           <=      i_reg_write;                
            mem_to_reg          <=      i_mem_to_reg;                
            bds_sel             <=      i_bds_sel;            
            read_data           <=      i_read_data;                
            alu_result          <=      i_alu_result;                
            write_register      <=      i_write_register;                    
            bds                 <=      i_bds; 

        end
        // Else, stall the register
    end

    //! Assignments
    assign o_halt               =       halt;
    assign o_reg_write          =       reg_write;     
    assign o_mem_to_reg         =       mem_to_reg;     
    assign o_bds_sel            =       bds_sel;     
    assign o_read_data          =       read_data;     
    assign o_alu_result         =       alu_result;     
    assign o_write_register     =       write_register;         
    assign o_bds                =       bds; 

endmodule