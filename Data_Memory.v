module Data_Memory(
    input clk, rst, WE,
    input [31:0] A, WD,
    output reg [31:0] RD,
    output s_err, d_err
);
    reg [38:0] mem [1023:0]; // 39-bit internal storage
    wire [38:0] encoded_wd;
    wire [31:0] corrected_rd;

    hamming_ecc_unit ecc_unit (
        .data_in(WD),
        .code_in(mem[A[11:2]]),
        .code_out(encoded_wd),
        .data_out(corrected_rd),
        .s_err(s_err),
        .d_err(d_err)
    );

    always @(posedge clk) begin
        if (WE)
            mem[A[11:2]] <= encoded_wd;
    end

    always @(*) begin
        if (!rst) RD = 32'd0;
        else RD = corrected_rd;
    end
endmodule