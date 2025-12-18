`timescale 1ns / 1ps
module hazard_unit(
    input rst,
    input RegWriteM, RegWriteW,
    input [4:0] RD_M, RD_W, Rs1_E, Rs2_E,
    output [1:0] ForwardAE, ForwardBE
);
    // ForwardA logic
    assign ForwardAE = (rst == 1'b0) ? 2'b00 :
        ((RegWriteM && (RD_M != 0) && (RD_M == Rs1_E))) ? 2'b10 :
        ((RegWriteW && (RD_W != 0) && (RD_W == Rs1_E))) ? 2'b01 : 2'b00;

    // ForwardB logic
    assign ForwardBE = (rst == 1'b0) ? 2'b00 :
        ((RegWriteM && (RD_M != 0) && (RD_M == Rs2_E))) ? 2'b10 :
        ((RegWriteW && (RD_W != 0) && (RD_W == Rs2_E))) ? 2'b01 : 2'b00;
endmodule