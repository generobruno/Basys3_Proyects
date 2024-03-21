/**

**/

module MainControlUnit
    #(
        // Parameters
        parameter OPCODE_SZ     =   6,
        parameter FUNCT_SZ      =   6
    )
    (
        // Inputs
        input [OPCODE_SZ-1 : 0]         i_instr_op_D,               // Instruction Op Code -> inst[31:26]
        input [FUNCT_SZ-1 : 0]          i_instr_funct_D,            // Instruction Function -> inst[5:0]
        // Output
        output [2 : 0]                  o_alu_op_MC,                // ALUOp Control Line
        output                          o_reg_dst_MC,               // RegDst Control Line
        output                          o_jal_sel_MC,               // JALSel Control Line
        output                          o_alu_src_MC,               // ALUSrc Control Line
        output                          o_branch_MC,                // Branch Control Line
        output                          o_equal_MC,                 // Equal Control Line
        output                          o_mem_read_MC,              // MemRead Control Line
        output                          o_mem_write_MC,             // MemWrite Control Line
        output [2 : 0]                  o_bhw_MC,                   // Memory Size Control Line
        output                          o_jump_MC,                  // Jump Control Line
        output                          o_jump_sel_MC,              // JumpSel Control Line
        output                          o_reg_write_MC,             // RegWrite Control Line
        output                          o_bds_sel_MC,               // BDSSel Control Line
        output                          o_mem_to_reg_MC,            // MemToReg Control Line
        output                          o_halt_MC                   // Halt Control Line
    );

    //! Local Parameters
    // OpCodes
    localparam SPECIAL  =       3'b000;         // SPECIAL OpCode:
    localparam BEQ      =       3'b100;         //      BEQ OpCode (000100)
    localparam BNE      =       3'b101;         //      BNE Opcode (000101)
    localparam J        =       3'b010;         //      J OpCode (000010)
    localparam JAL      =       3'b011;         //      JAL OpCode (000011)
    localparam R_TYPE   =       3'b000;         //      R-Type OpCode (000000)
    localparam LOAD     =       3'b100;         // Load Operations
    localparam STORE    =       3'b101;         // Store Operations
    localparam IMM      =       3'b001;         // Immediate Operations:
    localparam ADDI     =       3'b000;         //      Add Immediate
    localparam ANDI     =       3'b100;         //      AND Immediate
    localparam ORI      =       3'b101;         //      OR Immediate
    localparam XORI     =       3'b110;         //      XOR Immediate
    localparam LUI      =       3'b111;         //      Load Upper Immediate
    localparam SLTI     =       3'b010;         //      SLT Immediate

    // BHW Load-Store
    localparam BYTE       =       3'b000;         // Load-Store Byte
    localparam HALFWORD   =       3'b001;         // Load-Store HalfWord
    localparam WORD       =       3'b011;         // Load-Store Word
    localparam U_BYTE     =       3'b100;         // Load-Store Byte Unsigned
    localparam U_HALFWORD =       3'b101;         // Load-Store HalfWord Unsigned
    localparam U_WORD     =       3'b111;         // Load-Store Word Unsigned

    // ALU Operations Function Fields
    localparam ADDU =           6'b100001;      // Add Word Unsigned 
    localparam SUBU =           6'b100011;      // Subtract Word Unsigned
    localparam AND  =           6'b100100;      // Logical bitwise AND 
    localparam OR   =           6'b100101;      // Logical bitwise OR
    localparam XOR  =           6'b100110;      // Logical bitwise XOR
    localparam NOR  =           6'b100111;      // Logical bitwise NOR
    localparam SLT  =           6'b101010;      // Set on Less Than

    localparam SRA  =           6'b000011;      // Shift Word Right Arithmetic
    localparam SRL  =           6'b000010;      // Shift Word Right Logic
    localparam SLL  =           6'b000000;      // Shift Word Left Logic

    localparam SLLV =           6'b000100;      // Shift Word Left Logic Variable
    localparam SRLV =           6'b000110;      // Shift Word Right Logic Variable
    localparam SRAV =           6'b000111;      // Shift Word Right Arithmetic Variable

    localparam JR       =       6'b001000;      // Jump Register
    localparam JALR     =       6'b001001;      // Jump and Link Register

    localparam HALT     =       6'b111111;           // HALT Instruction

    //! Signal Declaration
    reg [2:0] alu_op;
    reg reg_dst;
    reg jal_sel;
    reg alu_src;
    reg branch;
    reg equal;
    reg mem_read;
    reg mem_write;
    reg [2:0] bhw;
    reg jump;
    reg jump_sel;
    reg reg_write;
    reg bds_sel;
    reg mem_to_reg;
    reg halt;

    // Body
    always @(*) 
    begin
        case(i_instr_op_D[5:3]) // bits 3 a 5
            SPECIAL: 
            begin
                case(i_instr_op_D[2:0])  // bits 0 a 3
                    R_TYPE: 
                    begin
                        case(i_instr_funct_D) // Function Field
                            ADDU, SUBU, AND, OR, XOR, NOR, SLT: // 3-Operand ALU Instructions
                            begin
                                reg_dst     =   1'b1;   
                                jal_sel     =   1'b0;
                                alu_src     =   1'b0;
                                alu_op      =   3'b010;
                                branch      =   1'b0;
                                equal       =   1'b0; // X
                                mem_read    =   1'b0;
                                mem_write   =   1'b0;
                                bhw         =   3'b011;
                                jump        =   1'b0;
                                jump_sel    =   1'b0; // X
                                reg_write   =   1'b1;
                                bds_sel     =   1'b0;
                                mem_to_reg  =   1'b0;
                                halt        =   1'b0;
                            end
                            SRA, SRL, SLL:      // Shift Instructions
                            begin
                                reg_dst     =   1'b1;   
                                jal_sel     =   1'b0;
                                alu_src     =   1'b0;
                                alu_op      =   3'b010;
                                branch      =   1'b0;
                                equal       =   1'b0; // X
                                mem_read    =   1'b0;
                                mem_write   =   1'b0;
                                bhw         =   3'b011;
                                jump        =   1'b0;
                                jump_sel    =   1'b0; // X
                                reg_write   =   1'b1;
                                bds_sel     =   1'b0;
                                mem_to_reg  =   1'b0;
                                halt        =   1'b0;

                            end
                            SRAV, SRLV, SLLV:   // Shift Variable Instructions
                            begin //TODO Agregar MPX en outputs, regs, aca y en los otros shift
                                reg_dst     =   1'b1;   
                                jal_sel     =   1'b0;
                                alu_src     =   1'b0;
                                alu_op      =   3'b010;
                                branch      =   1'b0;
                                equal       =   1'b0; // X
                                mem_read    =   1'b0;
                                mem_write   =   1'b0;
                                bhw         =   3'b011;
                                jump        =   1'b0;
                                jump_sel    =   1'b0; // X
                                reg_write   =   1'b1;
                                bds_sel     =   1'b0;
                                mem_to_reg  =   1'b0;
                                halt        =   1'b0;
                            end
                            JR:                 // Jump Register Instruction
                            begin
                                reg_dst     =   1'b0; // X
                                jal_sel     =   1'b0; // X
                                alu_src     =   1'b0; // X
                                alu_op      =   3'b000; // X
                                branch      =   1'b0; // X
                                equal       =   1'b0; // X
                                mem_read    =   1'b0; // X
                                mem_write   =   1'b0; // X
                                bhw         =   3'b011;
                                jump        =   1'b0; // X
                                jump_sel    =   1'b1;
                                reg_write   =   1'b0; // X
                                bds_sel     =   1'b0;
                                mem_to_reg  =   1'b0; // X
                                halt        =   1'b0;
                            end
                            JALR:               // Jump and Link Register Instruction
                            begin
                                reg_dst     =   1'b1;   
                                jal_sel     =   1'b0;
                                alu_src     =   1'b0;
                                alu_op      =   3'b000;
                                branch      =   1'b0;
                                equal       =   1'b0;
                                mem_read    =   1'b0;
                                mem_write   =   1'b0;
                                bhw         =   3'b011;
                                jump        =   1'b0;
                                jump_sel    =   1'b1;
                                reg_write   =   1'b1;
                                bds_sel     =   1'b1;
                                mem_to_reg  =   1'b0;
                                halt        =   1'b0;
                            end
                            HALT:
                            begin
                                reg_dst     =   1'b0; // X   
                                jal_sel     =   1'b0; // X
                                alu_src     =   1'b0; // X
                                alu_op      =   3'b000; // X
                                branch      =   1'b0; // X
                                equal       =   1'b0; // X
                                mem_read    =   1'b0; // X
                                mem_write   =   1'b0; // X
                                bhw         =   3'b011;
                                jump        =   1'b0; // X
                                jump_sel    =   1'b0; // X
                                reg_write   =   1'b0; // X
                                bds_sel     =   1'b0; // X
                                mem_to_reg  =   1'b0; // X
                                halt        =   1'b1;
                            end
                            default:
                            begin
                                reg_dst     =   1'b0;
                                jal_sel     =   1'b0;
                                alu_src     =   1'b0;
                                alu_op      =   3'b000;
                                branch      =   1'b0;
                                equal       =   1'b0;
                                mem_read    =   1'b0;
                                mem_write   =   1'b0;
                                bhw         =   3'b011;
                                jump        =   1'b0;
                                jump_sel    =   1'b0;
                                reg_write   =   1'b0;
                                bds_sel     =   1'b0;
                                mem_to_reg  =   1'b0;
                                halt        =   1'b0;
                            end
                        endcase
                    end
                    BEQ:                // Branch if Equal Instruction
                    begin
                        reg_dst     =   1'b0; //X   
                        jal_sel     =   1'b0;
                        alu_src     =   1'b0;
                        alu_op      =   3'b110;
                        branch      =   1'b1;
                        equal       =   1'b1;
                        mem_read    =   1'b0;
                        mem_write   =   1'b0;
                        bhw         =   3'b011;
                        jump        =   1'b0;
                        jump_sel    =   1'b0; //X
                        reg_write   =   1'b0;
                        bds_sel     =   1'b0;
                        mem_to_reg  =   1'b0; //X
                        halt        =   1'b0;
                    end
                    BNE:                // Branch if Not Equal Instruction
                    begin
                        reg_dst     =   1'b0; //X   
                        jal_sel     =   1'b0;
                        alu_src     =   1'b0;
                        alu_op      =   3'b110;
                        branch      =   1'b1;
                        equal       =   1'b0;
                        mem_read    =   1'b0;
                        mem_write   =   1'b0;
                        bhw         =   3'b011;
                        jump        =   1'b0;
                        jump_sel    =   1'b0; //X
                        reg_write   =   1'b0;
                        bds_sel     =   1'b0;
                        mem_to_reg  =   1'b0; //X
                        halt        =   1'b0;
                    end
                    J:                  // Jump Instruction
                    begin
                        reg_dst     =   1'b0; //X   
                        jal_sel     =   1'b0; //X
                        alu_src     =   1'b0; //X
                        alu_op      =   3'b000; //X
                        branch      =   1'b0; //X
                        equal       =   1'b0; //X
                        mem_read    =   1'b0; //X
                        mem_write   =   1'b0; //X
                        bhw         =   3'b011;
                        jump        =   1'b1;
                        jump_sel    =   1'b0;
                        reg_write   =   1'b0; //X
                        bds_sel     =   1'b0;
                        mem_to_reg  =   1'b0; //X
                        halt        =   1'b0;
                    end
                    JAL:                // Jump and Link Instruction
                    begin
                        reg_dst     =   1'b0; //X   
                        jal_sel     =   1'b1;
                        alu_src     =   1'b0; //X
                        alu_op      =   3'b000; //X
                        branch      =   1'b0; //X
                        equal       =   1'b0; //X
                        mem_read    =   1'b0; //X
                        mem_write   =   1'b0; //X
                        bhw         =   3'b011;
                        jump        =   1'b1;
                        jump_sel    =   1'b0;
                        reg_write   =   1'b1; //X
                        bds_sel     =   1'b1;
                        mem_to_reg  =   1'b0; //X
                        halt        =   1'b0;
                    end
                    default:
                    begin
                        reg_dst     =   1'b0;
                        jal_sel     =   1'b0;
                        alu_src     =   1'b0;
                        alu_op      =   3'b000;
                        branch      =   1'b0;
                        equal       =   1'b0;
                        mem_read    =   1'b0;
                        mem_write   =   1'b0;
                        bhw         =   3'b011;
                        jump        =   1'b0;
                        jump_sel    =   1'b0;
                        reg_write   =   1'b0;
                        bds_sel     =   1'b0;
                        mem_to_reg  =   1'b0;
                        halt        =   1'b0;
                    end
                endcase
            end
            LOAD:               // Load Instructions            
            begin
                reg_dst     =   1'b0;   
                jal_sel     =   1'b0;
                alu_src     =   1'b1;
                alu_op      =   3'b000;
                branch      =   1'b0;
                equal       =   1'b0; //X
                mem_read    =   1'b1;
                mem_write   =   1'b0;
                jump        =   1'b0;
                jump_sel    =   1'b0; //X
                reg_write   =   1'b1;
                bds_sel     =   1'b0;
                mem_to_reg  =   1'b1;        
                halt        =   1'b0; 
                case (i_instr_op_D[2:0]) // Bits 3 a 0
                    BYTE:
                    begin
                        bhw         =   3'b000;
                    end
                    HALFWORD:
                    begin
                        bhw         =   3'b001;
                    end
                    WORD:
                    begin
                        bhw         =   3'b011;
                    end 
                    U_BYTE:
                    begin
                        bhw         =   3'b100;
                    end
                    U_HALFWORD:
                    begin
                        bhw         =   3'b101;
                    end
                    U_WORD:
                    begin
                        bhw         =   3'b111;
                    end 
                    default:
                    begin
                        bhw         =   3'b011;
                    end 
                endcase   
            end
            STORE:              // Store Instructions
            begin
                reg_dst     =   1'b0;   
                jal_sel     =   1'b0;
                alu_src     =   1'b1;
                alu_op      =   3'b000;
                branch      =   1'b0;
                equal       =   1'b0; //X
                mem_read    =   1'b0;
                mem_write   =   1'b1;
                jump        =   1'b0;
                jump_sel    =   1'b0; //X
                reg_write   =   1'b0;
                bds_sel     =   1'b0;
                mem_to_reg  =   1'b0;        
                halt        =   1'b0;
                case (i_instr_op_D[2:0]) // Bits 3 a 0
                    BYTE:
                    begin
                        bhw         =   3'b000;
                    end
                    HALFWORD:
                    begin
                        bhw         =   3'b001;
                    end
                    WORD:
                    begin
                        bhw         =   3'b011;
                    end
                    default:
                    begin
                        bhw         =   3'b011;
                    end 
                endcase    
            end
            IMM:                // Immediate Instruction
            begin
                reg_dst     =   1'b0;   
                jal_sel     =   1'b0;
                alu_src     =   1'b1;
                branch      =   1'b0;
                equal       =   1'b0; //X
                mem_read    =   1'b0;
                mem_write   =   1'b0;
                bhw         =   3'b011;
                jump        =   1'b0;
                jump_sel    =   1'b0; //X
                reg_write   =   1'b1;
                bds_sel     =   1'b0;
                mem_to_reg  =   1'b0;
                halt        =   1'b0;
                case(i_instr_op_D[2:0])
                    ADDI:
                    begin
                        alu_op      =   3'b000;
                    end
                    ANDI:
                    begin
                        alu_op      =   3'b001;
                    end
                    ORI:
                    begin
                        alu_op      =   3'b011;
                    end
                    XORI:
                    begin
                        alu_op      =   3'b100;
                    end
                    LUI:
                    begin
                        alu_op      =   3'b101; 
                    end
                    SLTI:
                    begin
                        alu_op      =   3'b111;
                    end
                    default:
                    begin
                        alu_op      =   3'b000;
                    end
                endcase            
            end
            default:            // Default Op
            begin   
                reg_dst     =   1'b0;
                jal_sel     =   1'b0;
                alu_src     =   1'b0;
                alu_op      =   3'b000;
                branch      =   1'b0;
                equal       =   1'b0;
                mem_read    =   1'b0;
                mem_write   =   1'b0;
                bhw         =   3'b011;
                jump        =   1'b0;
                jump_sel    =   1'b0;
                reg_write   =   1'b0;
                bds_sel     =   1'b0;
                mem_to_reg  =   1'b0;
                halt        =   1'b0;
            end
        endcase    
    end

    //! Assignments
    assign o_alu_op_MC      = alu_op;     
    assign o_reg_dst_MC     = reg_dst;
    assign o_jal_sel_MC     = jal_sel;
    assign o_alu_src_MC     = alu_src;
    assign o_branch_MC      = branch;
    assign o_equal_MC       = equal;
    assign o_mem_read_MC    = mem_read;
    assign o_mem_write_MC   = mem_write;
    assign o_bhw_MC         = bhw;
    assign o_jump_MC        = jump;
    assign o_jump_sel_MC    = jump_sel;
    assign o_reg_write_MC   = reg_write;
    assign o_bds_sel_MC     = bds_sel;
    assign o_mem_to_reg_MC  = mem_to_reg; 
    assign o_halt_MC        = halt;

endmodule
