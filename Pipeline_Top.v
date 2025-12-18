`timescale 1ns / 1ns

module Pipeline_top(
    input clk,
    input rst, // Active Low Master Reset

    // IMEM write interface (from Instruction Loader)
    input           imem_we,
    input  [31:0]   imem_waddr,     // Explicit 32-bit to fix width mismatch
    input  [31:0]   imem_wdata,     // Explicit 32-bit to fix width mismatch
    input           loader_done_in, // Port added to fix named connection error

    // Result Output
    output [31:0]   ResultW_out,

    // ECC Error Reporting Ports
    output          imem_error,
    output          dmem_error,
    output          error_type_imem, // 0 for Single, 1 for Double
    output          error_type_dmem  // 0 for Single, 1 for Double
);

    // --- Internal Wire Declarations (Explicitly sized to 32-bit) ---
    wire PCSrcE, RegWriteW, RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE;
    wire RegWriteM, MemWriteM, ResultSrcM, ResultSrcW;
    wire [2:0] ALUControlE;
    wire [4:0] RD_E, RD_M, RDW, RS1_E, RS2_E;
    
    wire [31:0] PC_Next, PCTargetE, InstrD, PCD, PCPlus4D, ResultW;
    wire [31:0] RD1_E, RD2_E, Imm_Ext_E, PCE, PCPlus4E, PCPlus4M;
    wire [31:0] WriteDataM, ALU_ResultM, PCPlus4W, ALU_ResultW, ReadDataW;
    
    wire [1:0] ForwardAE, ForwardBE;

    // Internal ECC Error Wires from Stages
    wire s_err_i, d_err_i, s_err_d, d_err_d;

    // --- Global Outputs ---
    assign ResultW_out = ResultW;
    assign imem_error = s_err_i | d_err_i;
    assign dmem_error = s_err_d | d_err_d;
    assign error_type_imem = d_err_i; // High if double error
    assign error_type_dmem = d_err_d; // High if double error

    // --- 1. PC Control Mux ---
Mux PC_Selector (
    .a(PCPlus4D), 
    .b(PCTargetE), 
    .s(PCSrcE), 
    .c(PC_Next) 
);

    // --- 2. Fetch Stage (Includes ECC Instruction Memory) ---
    fetch_cycle fetch (
        .clk(clk), 
        .rst(rst), 
        .PC_Next_In(PC_Next), 
        .imem_we(imem_we), 
        .imem_waddr(imem_waddr), 
        .imem_wdata(imem_wdata),
        .loader_done_in(loader_done_in),
        .s_err(s_err_i), 
        .d_err(d_err_i),
        .InstrD(InstrD), 
        .PCPlus4D(PCPlus4D), 
        .PCD(PCD) 
    );

    // --- 3. Decode Stage ---
    decode_cycle decode (
        .clk(clk), 
        .rst(rst), 
        .InstrD(InstrD), 
        .PCD(PCD), 
        .PCPlus4D(PCPlus4D), 
        .RegWriteW(RegWriteW), 
        .RDW(RDW), 
        .ResultW(ResultW), 
        .RegWriteE(RegWriteE), 
        .ALUSrcE(ALUSrcE), 
        .MemWriteE(MemWriteE), 
        .ResultSrcE(ResultSrcE),
        .BranchE(BranchE), 
        .ALUControlE(ALUControlE), 
        .RD1_E(RD1_E), 
        .RD2_E(RD2_E), 
        .Imm_Ext_E(Imm_Ext_E), 
        .RD_E(RD_E), 
        .PCE(PCE), 
        .PCPlus4E(PCPlus4E),
        .RS1_E(RS1_E), 
        .RS2_E(RS2_E)
    );

    // --- 4. Execute Stage (Includes Forwarding and ALU) ---
    execute_cycle execute (
        .clk(clk), 
        .rst(rst), 
        .RegWriteE(RegWriteE), 
        .ALUSrcE(ALUSrcE), 
        .MemWriteE(MemWriteE), 
        .ResultSrcE(ResultSrcE), 
        .BranchE(BranchE), 
        .ALUControlE(ALUControlE), 
        .RD1_E(RD1_E), 
        .RD2_E(RD2_E), 
        .Imm_Ext_E(Imm_Ext_E), 
        .RD_E(RD_E), 
        .PCE(PCE), 
        .PCPlus4E(PCPlus4E), 
        .PCSrcE(PCSrcE), 
        .PCTargetE(PCTargetE), 
        .RegWriteM(RegWriteM), 
        .MemWriteM(MemWriteM), 
        .ResultSrcM(ResultSrcM), 
        .RD_M(RD_M), 
        .PCPlus4M(PCPlus4M), 
        .WriteDataM(WriteDataM), 
        .ALU_ResultM(ALU_ResultM), 
        .ResultW(ResultW), 
        .ForwardA_E(ForwardAE), 
        .ForwardB_E(ForwardBE),
        .ALU_ResultM_In(ALU_ResultM) // Connects forwarding from MEM stage
    );
    
    // --- 5. Memory Stage (Includes ECC Data Memory) ---
    memory_cycle memory (
        .clk(clk), 
        .rst(rst), 
        .RegWriteM(RegWriteM), 
        .MemWriteM(MemWriteM), 
        .ResultSrcM(ResultSrcM), 
        .RD_M(RD_M), 
        .PCPlus4M(PCPlus4M), 
        .WriteDataM(WriteDataM), 
        .ALU_ResultM(ALU_ResultM), 
        .RegWriteW(RegWriteW), 
        .ResultSrcW(ResultSrcW), 
        .RD_W(RDW), 
        .PCPlus4W(PCPlus4W), 
        .ALU_ResultW(ALU_ResultW), 
        .ReadDataW(ReadDataW),
        .s_err(s_err_d), 
        .d_err(d_err_d)
    );

    // --- 6. Write Back Stage ---
    writeback_cycle writeBack (
        .clk(clk), 
        .rst(rst), 
        .ResultSrcW(ResultSrcW), 
        .PCPlus4W(PCPlus4W), 
        .ALU_ResultW(ALU_ResultW), 
        .ReadDataW(ReadDataW), 
        .ResultW(ResultW)
    );

    // --- 7. Hazard Unit ---
    hazard_unit Forwarding_Block (
        .rst(rst), 
        .RegWriteM(RegWriteM), 
        .RegWriteW(RegWriteW), 
        .RD_M(RD_M), 
        .RD_W(RDW), 
        .Rs1_E(RS1_E), 
        .Rs2_E(RS2_E), 
        .ForwardAE(ForwardAE), 
        .ForwardBE(ForwardBE)
    );

endmodule