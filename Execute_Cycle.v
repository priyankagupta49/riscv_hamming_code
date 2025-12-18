module execute_cycle(
    input clk, rst,
    input RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE,
    input [2:0] ALUControlE,
    input [31:0] RD1_E, RD2_E, Imm_Ext_E,
    input [4:0] RD_E,
    input [31:0] PCE, PCPlus4E,
    input [31:0] ResultW,
    input [1:0] ForwardA_E, ForwardB_E,
    input [31:0] ALU_ResultM_In, 

    output PCSrcE, RegWriteM, MemWriteM, ResultSrcM,
    output [4:0] RD_M,
    output [31:0] PCPlus4M, WriteDataM, ALU_ResultM,
    output [31:0] PCTargetE
);

    wire [31:0] Src_A, Src_B_interim, Src_B, ResultE;
    wire ZeroE; 
    wire unused_ov, unused_ca, unused_neg;

    // 1. Source A Mux (Forwarding)
    Mux_3_by_1 srca_mux (
        .a(RD1_E), 
        .b(ResultW), 
        .c(ALU_ResultM_In), 
        .s(ForwardA_E), 
        .d(Src_A)
    );

    // 2. Source B Interim Mux (Forwarding)
    Mux_3_by_1 srcb_mux (
        .a(RD2_E), 
        .b(ResultW), 
        .c(ALU_ResultM_In), 
        .s(ForwardB_E), 
        .d(Src_B_interim)
    );

    // 3. ALU Source B Mux (Immediate vs Register)
    Mux alu_src_mux (
        .a(Src_B_interim), 
        .b(Imm_Ext_E), 
        .s(ALUSrcE), 
        .c(Src_B)
    );

    // 4. ALU Instantiation
    ALU alu_inst (
        .A(Src_A),
        .B(Src_B),
        .ALUControl(ALUControlE),
        .Result(ResultE),
        .OverFlow(unused_ov),
        .Carry(unused_ca),
        .Zero(ZeroE),
        .Negative(unused_neg)
    );

    // 5. Branch Target Adder
    // Note: a and b must match the PC_Adder port names
    PC_Adder branch_adder (
        .a(PCE), 
        .b(Imm_Ext_E), 
        .c(PCTargetE)
    );

    // 6. EX/MEM Pipeline Registers
    reg RegWriteM_r, MemWriteM_r, ResultSrcM_r;
    reg [4:0] RD_M_r;
    reg [31:0] PCPlus4M_r, WriteDataM_r, ALU_ResultM_r;

    always @(posedge clk) begin
        if (rst == 1'b0) begin
            RegWriteM_r <= 1'b0; MemWriteM_r <= 1'b0; ResultSrcM_r <= 1'b0;
            RD_M_r <= 5'b0;
            PCPlus4M_r <= 32'b0; WriteDataM_r <= 32'b0; ALU_ResultM_r <= 32'b0;
        end else begin
            RegWriteM_r <= RegWriteE;
            MemWriteM_r <= MemWriteE;
            ResultSrcM_r <= ResultSrcE;
            RD_M_r <= RD_E;
            PCPlus4M_r <= PCPlus4E;
            WriteDataM_r <= Src_B_interim; // Forwarded RS2 value for store instructions
            ALU_ResultM_r <= ResultE;
        end
    end

    // Final Outputs
    assign PCSrcE = ZeroE & BranchE;
    assign RegWriteM = RegWriteM_r;
    assign MemWriteM = MemWriteM_r;
    assign ResultSrcM = ResultSrcM_r;
    assign RD_M = RD_M_r;
    assign PCPlus4M = PCPlus4M_r;
    assign WriteDataM = WriteDataM_r;
    assign ALU_ResultM = ALU_ResultM_r;

endmodule