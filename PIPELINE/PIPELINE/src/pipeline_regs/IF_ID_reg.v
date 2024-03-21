/**

**/

module IF_ID_reg
    #(
        // Parameters
        parameter INST_SZ = 32
    )
    (
        // Inputs
        input wire                      i_clk,                      // Clock
        input wire                      i_reset,                    // Reset
        input wire                      i_enable,                   // Write Control Line
        input wire [INST_SZ-1 : 0]      i_instruction,              // Instruction Fetched
        input wire [INST_SZ-1 : 0]      i_npc,                      // NPC
        input wire [INST_SZ-1 : 0]      i_bds,                      // Branch Delay Slot
        // Outputs
        output wire [INST_SZ-1 : 0]     o_instruction,              // Instruction Fetched
        output wire [INST_SZ-1 : 0]     o_npc,                      // NPC
        output wire [INST_SZ-1 : 0]     o_bds                       // Branch Delay Slot
    );

    //! Signal Definition
    reg [INST_SZ-1 : 0]      instruction;
    reg [INST_SZ-1 : 0]      npc;              
    reg [INST_SZ-1 : 0]      bds;

    // Body
    always @(posedge i_clk) 
    begin
        if(i_reset)
        begin
            instruction <= 0; 
            npc <= 0;
            bds <= 0; 
        end
        else if(i_enable)
        begin
            instruction <= i_instruction;
            npc <= i_npc;
            bds <= i_bds;
        end
        // Else, stall the register
    end

    //! Assignments
    assign o_instruction = instruction;
    assign o_npc = npc;
    assign o_bds = bds;

endmodule