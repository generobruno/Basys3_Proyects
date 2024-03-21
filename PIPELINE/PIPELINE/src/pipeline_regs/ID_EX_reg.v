/**

**/

module ID_EX_reg
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
        input wire                      i_alu_src,                  // ALUSrc Control Line
        input wire [2 : 0]              i_alu_op,                   // ALUOp Control Line
        input wire                      i_reg_dst,                  // RegDst Control Line
        input wire                      i_jal_sel,                  // JALSel Control Line //TODO Agregar SXL/SXLV Control line
        input wire                      i_mem_read,                 // MemRead Control Line
        input wire                      i_mem_write,                // MemWrite Control Line
        input wire [2 : 0]              i_bhw,                      // Memory Size Control Line
        input wire                      i_reg_write,                // RegWrite Control Line
        input wire                      i_mem_to_reg,               // MemToReg Control Line
        input wire                      i_bds_sel,                  // BDSSel Control Line
        input wire [INST_SZ-1 : 0]      i_bds,                      // Branch Delay Slot
        input wire [INST_SZ-1 : 0]      i_read_data_1,              // Read Data 1
        input wire [INST_SZ-1 : 0]      i_read_data_2,              // Read Data 2
        input wire [INST_SZ-1 : 0]      i_instr_imm,                // Instruction Immediate (instr[15:0] extended with sign)
        input wire [4 : 0]              i_instr_rt,                 // Instruction rt (instr[20:16])
        input wire [4 : 0]              i_instr_rd,                 // Instruction rd (instr[15:11])
        input wire [4 : 0]              i_instr_rs,                 // Instruction rs (instr[25:21])
        // Outputs  
        output wire                     o_halt,                     // Halt Control Line
        output wire                     o_alu_src,                  // ALUSrc Control Line
        output wire [2 : 0]             o_alu_op,                   // ALUOp Control Line
        output wire                     o_reg_dst,                  // RegDst Control Line
        output wire                     o_jal_sel,                  // JALSel Control Line //TODO Agregar SXL/SXLV Control line
        output wire                     o_mem_read,                 // MemRead Control Line
        output wire                     o_mem_write,                // MemWrite Control Line
        output wire [2 : 0]             o_bhw,                      // Memory Size Control Line
        output wire                     o_reg_write,                // RegWrite Control Line
        output wire                     o_mem_to_reg,               // MemToReg Control Line
        output wire                     o_bds_sel,                  // BDSSel Control Line
        output wire [INST_SZ-1 : 0]     o_bds,                      // Branch Delay Slot
        output wire [INST_SZ-1 : 0]     o_read_data_1,              // Read Data 1
        output wire [INST_SZ-1 : 0]     o_read_data_2,              // Read Data 2
        output wire [INST_SZ-1 : 0]     o_instr_imm,                // Instruction Immediate (instr[15:0] extended with sign)
        output wire [4 : 0]             o_instr_rt,                 // Instruction rt (instr[20:16])
        output wire [4 : 0]             o_instr_rd,                 // Instruction rd (instr[15:11])
        output wire [4 : 0]             o_instr_rs                  // Instruction rs (instr[25:21])
    );

    //! Signal Definition
    reg                     halt;
    reg                     alu_src;                  
    reg [2 : 0]             alu_op;                   
    reg                     reg_dst;                  
    reg                     jal_sel;                   //TODO Agregar SXL/SXLV Control line               
    reg                     mem_read;                 
    reg                     mem_write;
    reg [2 : 0]             bhw;                
    reg                     reg_write;                
    reg                     mem_to_reg;               
    reg                     bds_sel;
    reg [INST_SZ-1 : 0]     bds;               
    reg [INST_SZ-1 : 0]     read_data_1;              
    reg [INST_SZ-1 : 0]     read_data_2;              
    reg [INST_SZ-1 : 0]     instr_imm;               
    reg [4 : 0]             instr_rt;                 
    reg [4 : 0]             instr_rd;                 
    reg [4 : 0]             instr_rs;                 

    // Body
    always @(posedge i_clk) 
    begin
        if(i_reset)
        begin
            halt           <=       0;
            alu_src        <=       0;
            alu_op         <=       0;
            reg_dst        <=       0;
            jal_sel        <=       0;        //TODO Agregar SXL/SXLV Control line          
            mem_read       <=       0;
            mem_write      <=       0;
            bhw            <=       0;
            reg_write      <=       0;
            mem_to_reg     <=       0;
            bds_sel        <=       0;
            bds            <=       0; 
            read_data_1    <=       0;
            read_data_2    <=       0;
            instr_imm      <=       0;
            instr_rt       <=       0;
            instr_rd       <=       0;                 
            instr_rs       <=       0;
        end
        else if(i_enable)
        begin
            halt           <=       i_halt;
            alu_src        <=       i_alu_src;
            alu_op         <=       i_alu_op;
            reg_dst        <=       i_reg_dst;
            jal_sel        <=       i_jal_sel;        //TODO Agregar SXL/SXLV Control line          
            mem_read       <=       i_mem_read;
            mem_write      <=       i_mem_write;
            bhw            <=       i_bhw;
            reg_write      <=       i_reg_write;
            mem_to_reg     <=       i_mem_to_reg;
            bds_sel        <=       i_bds_sel;
            bds            <=       i_bds;
            read_data_1    <=       i_read_data_1;
            read_data_2    <=       i_read_data_2;
            instr_imm      <=       i_instr_imm;
            instr_rt       <=       i_instr_rt;
            instr_rd       <=       i_instr_rd;                 
            instr_rs       <=       i_instr_rs;

        end
        // Else, stall the register
    end

    //! Assignments
    assign o_alu_src        =       alu_src;
    assign o_alu_op         =       alu_op;
    assign o_reg_dst        =       reg_dst;
    assign o_jal_sel        =       jal_sel;                  
    assign o_mem_read       =       mem_read;
    assign o_mem_write      =       mem_write;
    assign o_bhw            =       bhw;
    assign o_reg_write      =       reg_write;
    assign o_mem_to_reg     =       mem_to_reg;
    assign o_bds_sel        =       bds_sel;
    assign o_bds            =       bds;
    assign o_read_data_1    =       read_data_1;
    assign o_read_data_2    =       read_data_2;
    assign o_instr_imm      =       instr_imm;
    assign o_instr_rt       =       instr_rt;
    assign o_instr_rd       =       instr_rd;                 
    assign o_instr_rs       =       instr_rs; 
    assign o_halt           =       halt;                

endmodule