module hamming_ecc_unit (
    input [31:0] data_in,
    input [38:0] code_in,
    output [38:0] code_out,
    output [31:0] data_out,
    output s_err, d_err
);
    // --- Encoding Logic ---
    wire [38:1] p_mapped;
    // Map 32 data bits to non-power-of-2 positions
    assign p_mapped[3] = data_in[0];   assign p_mapped[5] = data_in[1];
    assign p_mapped[6] = data_in[2];   assign p_mapped[7] = data_in[3];
    assign p_mapped[9] = data_in[4];   assign p_mapped[10] = data_in[5];
    assign p_mapped[11] = data_in[6];  assign p_mapped[12] = data_in[7];
    assign p_mapped[13] = data_in[8];  assign p_mapped[14] = data_in[9];
    assign p_mapped[15] = data_in[10]; assign p_mapped[17] = data_in[11];
    assign p_mapped[18] = data_in[12]; assign p_mapped[19] = data_in[13];
    assign p_mapped[20] = data_in[14]; assign p_mapped[21] = data_in[15];
    assign p_mapped[22] = data_in[16]; assign p_mapped[23] = data_in[17];
    assign p_mapped[24] = data_in[18]; assign p_mapped[25] = data_in[19];
    assign p_mapped[26] = data_in[20]; assign p_mapped[27] = data_in[21];
    assign p_mapped[28] = data_in[22]; assign p_mapped[29] = data_in[23];
    assign p_mapped[30] = data_in[24]; assign p_mapped[31] = data_in[25];
    assign p_mapped[33] = data_in[26]; assign p_mapped[34] = data_in[27];
    assign p_mapped[35] = data_in[28]; assign p_mapped[36] = data_in[29];
    assign p_mapped[37] = data_in[30]; assign p_mapped[38] = data_in[31];

    // Generate Parity Bits
    wire p1, p2, p4, p8, p16, p32, pG;
    assign p1  = p_mapped[3]^p_mapped[5]^p_mapped[7]^p_mapped[9]^p_mapped[11]^p_mapped[13]^p_mapped[15]^p_mapped[17]^p_mapped[19]^p_mapped[21]^p_mapped[23]^p_mapped[25]^p_mapped[27]^p_mapped[29]^p_mapped[31]^p_mapped[33]^p_mapped[35]^p_mapped[37];
    assign p2  = p_mapped[3]^p_mapped[6]^p_mapped[7]^p_mapped[10]^p_mapped[11]^p_mapped[14]^p_mapped[15]^p_mapped[18]^p_mapped[19]^p_mapped[22]^p_mapped[23]^p_mapped[26]^p_mapped[27]^p_mapped[30]^p_mapped[31]^p_mapped[34]^p_mapped[35]^p_mapped[38];
    assign p4  = p_mapped[5]^p_mapped[6]^p_mapped[7]^p_mapped[12]^p_mapped[13]^p_mapped[14]^p_mapped[15]^p_mapped[20]^p_mapped[21]^p_mapped[22]^p_mapped[23]^p_mapped[28]^p_mapped[29]^p_mapped[30]^p_mapped[31]^p_mapped[36]^p_mapped[37]^p_mapped[38];
    assign p8  = p_mapped[9]^p_mapped[10]^p_mapped[11]^p_mapped[12]^p_mapped[13]^p_mapped[14]^p_mapped[15]^p_mapped[24]^p_mapped[25]^p_mapped[26]^p_mapped[27]^p_mapped[28]^p_mapped[29]^p_mapped[30]^p_mapped[31];
    assign p16 = p_mapped[17]^p_mapped[18]^p_mapped[19]^p_mapped[20]^p_mapped[21]^p_mapped[22]^p_mapped[23]^p_mapped[24]^p_mapped[25]^p_mapped[26]^p_mapped[27]^p_mapped[28]^p_mapped[29]^p_mapped[30]^p_mapped[31];
    assign p32 = p_mapped[33]^p_mapped[34]^p_mapped[35]^p_mapped[36]^p_mapped[37]^p_mapped[38];
    
    assign pG = ^p_mapped ^ p1 ^ p2 ^ p4 ^ p8 ^ p16 ^ p32;
    assign code_out = {pG, p32, p16, p8, p4, p2, p1, data_in}; // Simplified storage for memory

    // --- Decoding Logic ---
    wire [5:0] syn;
    assign syn[0] = code_in[32] ^ code_in[0]^code_in[1]^code_in[3]^code_in[4]^code_in[6]^code_in[8]^code_in[10]^code_in[11]^code_in[13]^code_in[15]^code_in[17]^code_in[19]^code_in[21]^code_in[23]^code_in[25]^code_in[26]^code_in[28]^code_in[30];
    assign syn[1] = code_in[33] ^ code_in[0]^code_in[2]^code_in[3]^code_in[5]^code_in[6]^code_in[9]^code_in[10]^code_in[12]^code_in[13]^code_in[16]^code_in[17]^code_in[20]^code_in[21]^code_in[24]^code_in[25]^code_in[27]^code_in[28]^code_in[31];
    assign syn[2] = code_in[34] ^ code_in[1]^code_in[2]^code_in[3]^code_in[7]^code_in[8]^code_in[9]^code_in[10]^code_in[14]^code_in[15]^code_in[16]^code_in[17]^code_in[22]^code_in[23]^code_in[24]^code_in[25]^code_in[29]^code_in[30]^code_in[31];
    assign syn[3] = code_in[35] ^ code_in[4]^code_in[5]^code_in[6]^code_in[7]^code_in[8]^code_in[9]^code_in[10]^code_in[18]^code_in[19]^code_in[20]^code_in[21]^code_in[22]^code_in[23]^code_in[24]^code_in[25];
    assign syn[4] = code_in[36] ^ code_in[11]^code_in[12]^code_in[13]^code_in[14]^code_in[15]^code_in[16]^code_in[17]^code_in[18]^code_in[19]^code_in[20]^code_in[21]^code_in[22]^code_in[23]^code_in[24]^code_in[25];
    assign syn[5] = code_in[37] ^ code_in[26]^code_in[27]^code_in[28]^code_in[29]^code_in[30]^code_in[31];
    
    wire syn_G = ^code_in;
    assign s_err = (syn != 0) && (syn_G != 0);
    assign d_err = (syn != 0) && (syn_G == 0);

    assign data_out = (s_err && syn <= 32) ? (code_in[31:0] ^ (32'b1 << (syn-1))) : code_in[31:0];
endmodule