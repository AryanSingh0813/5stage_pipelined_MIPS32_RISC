`timescale 1ns / 1ps
module pipe_MIPS32(
    input  clk1, clk2,
    output [31:0] pc_out,
    output reg [31:0] ALU_output
);

//-------------------------------------------
// Pipeline Registers
//-------------------------------------------
reg [31:0] PC, IF_ID_IR, IF_ID_NPC;
reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
reg [2:0]  ID_EX_type, EX_MEM_type, MEM_WB_type;
reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
reg        EX_MEM_cond; 
reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;

//-------------------------------------------
// Memory and Register File
//-------------------------------------------
reg [31:0] mem [0:511];   // instruction + data memory
reg [31:0] REG [0:31];     // register bank

//-------------------------------------------
// OP-CODE DEFINITIONS
//-------------------------------------------
parameter ADD   = 6'b000000, SUB   = 6'b000001, AND   = 6'b000010, OR    = 6'b000011, 
          SLT   = 6'b000100, MUL   = 6'b000101, HLT   = 6'b111111, LW    = 6'b001000,
          SW    = 6'b001001, ADDI  = 6'b001010, SUBI  = 6'b001011, SLTI  = 6'b001100,
          BNEQZ = 6'b001101, BEQZ  = 6'b001110;  

parameter RR_ALU = 3'b000, RM_ALU = 3'b001, LOAD = 3'b010, STORE = 3'b011,
          BRANCH = 3'b100, HALT  = 3'b101;

//-------------------------------------------
// Control Flags
//-------------------------------------------
reg HALTED;
reg TAKEN_BRANCH;

//-------------------------------------------
// Initialization (for simulation + FPGA init)
//-------------------------------------------
integer i;
initial begin
    PC = 0;
    HALTED = 0;
    TAKEN_BRANCH = 0;

    // Initialize memory and registers
    for (i = 0; i < 511; i = i + 1) mem[i] = 0;
    for (i = 0; i < 32; i = i + 1) REG[i] = 0;
end

//-------------------------------------------
// IF Stage
//-------------------------------------------
always @(posedge clk1) begin
    if (!HALTED) begin
        if (((EX_MEM_IR[31:26] == BEQZ ) && (EX_MEM_cond == 1)) || 
            ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0))) begin
            IF_ID_IR     <= mem[EX_MEM_ALUOut];
            TAKEN_BRANCH <= 1'b1;
            IF_ID_NPC    <= EX_MEM_ALUOut + 1;
            PC           <= EX_MEM_ALUOut + 1;
        end
        else begin
            IF_ID_IR     <= mem[PC];
            IF_ID_NPC    <= PC + 1;
            PC           <= PC + 1;
        end
    end
end

//-------------------------------------------
// ID Stage
//-------------------------------------------
always @(posedge clk2) begin
    if (!HALTED) begin
        ID_EX_A   <= (IF_ID_IR[25:21] == 5'b00000) ? 0 : REG[IF_ID_IR[25:21]];
        ID_EX_B   <= (IF_ID_IR[20:16] == 5'b00000) ? 0 : REG[IF_ID_IR[20:16]];
        ID_EX_NPC <= IF_ID_NPC;
        ID_EX_IR  <= IF_ID_IR;
        ID_EX_Imm <= {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]}; // sign extend

        case(IF_ID_IR[31:26])
            ADD, SUB, AND, OR, SLT, MUL : ID_EX_type <= RR_ALU;
            ADDI, SUBI, SLTI            : ID_EX_type <= RM_ALU;
            LW                          : ID_EX_type <= LOAD;
            SW                          : ID_EX_type <= STORE;
            BNEQZ, BEQZ                 : ID_EX_type <= BRANCH;
            HLT                         : ID_EX_type <= HALT;
            default                     : ID_EX_type <= HALT;
        endcase
    end
end

//-------------------------------------------
// EX Stage
//-------------------------------------------
always @(posedge clk1) begin
    if (!HALTED) begin
        EX_MEM_type <= ID_EX_type;
        EX_MEM_IR   <= ID_EX_IR;
        EX_MEM_B    <= ID_EX_B;  // default
        EX_MEM_cond <= 0;        // default

        case(ID_EX_type)
            RR_ALU: begin
                case(ID_EX_IR[31:26])
                    ADD : EX_MEM_ALUOut <= ID_EX_A + ID_EX_B;
                    SUB : EX_MEM_ALUOut <= ID_EX_A - ID_EX_B;
                    AND : EX_MEM_ALUOut <= ID_EX_A & ID_EX_B;
                    OR  : EX_MEM_ALUOut <= ID_EX_A | ID_EX_B;
                    SLT : EX_MEM_ALUOut <= (ID_EX_A < ID_EX_B);
                    MUL : EX_MEM_ALUOut <= ID_EX_A * ID_EX_B;
                    default: EX_MEM_ALUOut <= 32'h00000000;
                endcase
            end

            RM_ALU: begin
                case(ID_EX_IR[31:26])
                    ADDI : EX_MEM_ALUOut <= ID_EX_A + ID_EX_Imm;
                    SUBI : EX_MEM_ALUOut <= ID_EX_A - ID_EX_Imm;
                    SLTI : EX_MEM_ALUOut <= (ID_EX_A < ID_EX_Imm);
                    default: EX_MEM_ALUOut <= 32'h00000000;
                endcase
            end

            LOAD, STORE: begin
                EX_MEM_ALUOut <= ID_EX_A + ID_EX_Imm;
            end

            BRANCH: begin
                EX_MEM_ALUOut <= ID_EX_NPC + ID_EX_Imm;
                EX_MEM_cond   <= (ID_EX_A == 0);
            end

            default: EX_MEM_ALUOut <= 32'h00000000;
        endcase
    end
   // ALU_output <= EX_MEM_ALUOut;
end

always @(posedge clk2) begin
    ALU_output <= EX_MEM_ALUOut;
end

//-------------------------------------------
// MEM Stage
//-------------------------------------------
always @(posedge clk2) begin
    if (!HALTED) begin
        MEM_WB_type <= EX_MEM_type;
        MEM_WB_IR   <= EX_MEM_IR;
        case(EX_MEM_type)
            RR_ALU, RM_ALU: MEM_WB_ALUOut <= EX_MEM_ALUOut;
            LOAD          : MEM_WB_LMD   <= mem[EX_MEM_ALUOut];
            STORE         : if (!TAKEN_BRANCH) mem[EX_MEM_ALUOut] <= EX_MEM_B;
        endcase

        //ALU_output <= EX_MEM_ALUOut;
    end
end

//-------------------------------------------
// WB Stage
//-------------------------------------------
always @(posedge clk1) begin
    if (!TAKEN_BRANCH) begin
        case(MEM_WB_type)
//            RR_ALU: REG[MEM_WB_IR[15:11]] <= MEM_WB_ALUOut;
//            RM_ALU: REG[MEM_WB_IR[20:16]] <= MEM_WB_ALUOut;
//            LOAD  : REG[MEM_WB_IR[20:16]] <= MEM_WB_LMD;
//            HALT  : HALTED <= 1'b1;

            RR_ALU: if (MEM_WB_IR[15:11] != 5'b00000)  // Protect R0
                       REG[MEM_WB_IR[15:11]] <= MEM_WB_ALUOut;
            RM_ALU: if (MEM_WB_IR[20:16] != 5'b00000)  // Protect R0
                       REG[MEM_WB_IR[20:16]] <= MEM_WB_ALUOut;
            LOAD  : if (MEM_WB_IR[20:16] != 5'b00000)  // Protect R0
                       REG[MEM_WB_IR[20:16]] <= MEM_WB_LMD;
            HALT  : HALTED <= 1'b1;
 
        endcase
    end
    //REG[0] <=  32'h00000000;
end

assign pc_out = PC;

endmodule