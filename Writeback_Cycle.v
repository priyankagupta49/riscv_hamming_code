module writeback_cycle(
    input clk, // Added
    input rst, // Added
    input ResultSrcW,           
    input [31:0] PCPlus4W,
    input [31:0] ALU_ResultW,
    input [31:0] ReadDataW,
    output [31:0] ResultW
);

Mux result_mux (    
    .a(ALU_ResultW),
    .b(ReadDataW),
    .s(ResultSrcW),
    .c(ResultW)
);

endmodule