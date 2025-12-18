module instr_loader (
    input           clk,
    input           rst,      // Active-Low Reset
    input  [7:0]    op1,      // Operand 1 (8-bit value)
    input  [7:0]    op2,      // Operand 2 (8-bit value)
    input  [2:0]    alu_op,   // ALU operation code selection
    output reg      imem_we,  // Instruction Memory Write Enable
    output reg [31:0] imem_addr, // Instruction Memory Write Address
    output reg [31:0] imem_wdata, // Instruction Memory Write Data (32-bit instruction)
    output reg      done      // Program loading completion flag
);

    reg [2:0] state;
    reg [31:0] alu_instr;

    localparam OPCODE_R = 7'b0110011; // R-Type ALU (Opcode for ADD, SUB, etc.)
    localparam OPCODE_I = 7'b0010011; // I-Type ADDI (Opcode for immediate arithmetic)

    // Register indices: r11 = r9 op r10
    wire [4:0] rs1 = 5'd9;
    wire [4:0] rs2 = 5'd10;
    wire [4:0] rd  = 5'd11;

    // --- CRITICAL FIX: Ensure 12-bit immediate field is correctly constructed ---
    // Pad the 8-bit operands with 4 leading zeros for the 12-bit immediate field (Imm[11:0]).
    wire [11:0] op1_imm = {4'b0, op1}; 
    wire [11:0] op2_imm = {4'b0, op2};

    // R-Type Instruction Generation (Combinational)
    // This logic creates the R-type instruction that runs last (r11 = r9 op r10)
    always @(*) begin
        case (alu_op)
            3'b000: alu_instr = {7'b0000000, rs2, rs1, 3'b000, rd, OPCODE_R}; // ADD (funct7=0, funct3=000)
            3'b001: alu_instr = {7'b0100000, rs2, rs1, 3'b000, rd, OPCODE_R}; // SUB (funct7=0x20, funct3=000)
            3'b010: alu_instr = {7'b0000000, rs2, rs1, 3'b111, rd, OPCODE_R}; // AND (funct7=0, funct3=111)
            3'b011: alu_instr = {7'b0000000, rs2, rs1, 3'b110, rd, OPCODE_R}; // OR  (funct7=0, funct3=110)
            3'b100: alu_instr = {7'b0000000, rs2, rs1, 3'b100, rd, OPCODE_R}; // XOR (funct7=0, funct3=100)
            3'b101: alu_instr = {7'b0000000, rs2, rs1, 3'b010, rd, OPCODE_R}; // SLT (funct7=0, funct3=010)
            // Note: Your case statement ends here, assuming 3'b101 is the final tested op.
            default: alu_instr = 32'h00000013; // Default to NOP (ADDI x0, x0, 0)
        endcase
    end

    // State Machine for Loading (Sequential)
    always @(posedge clk) begin
        if (!rst) begin // Active-Low Reset (rst=0)
            state <= 3'd0;
            imem_we <= 1'b0;
            done <= 1'b0;
            imem_addr <= 32'h0;
        end else begin // Running (rst=1)
            case (state)
                3'd0: begin
                    // 1. Load op1 into r9
                    imem_we     <= 1'b1;
                    imem_addr   <= 32'h0; // Address 0
                    // ADDI r9, x0, op1_imm
                    imem_wdata  <= {op1_imm, 5'h00, 3'b000, rs1, OPCODE_I}; 
                    state <= 3'd1;
                end
                3'd1: begin
                    // 2. Load op2 into r10
                    imem_addr   <= 32'h4; // Address 4
                    // ADDI r10, x0, op2_imm
                    imem_wdata  <= {op2_imm, 5'h00, 3'b000, rs2, OPCODE_I}; 
                    state <= 3'd2;
                end
                3'd2: begin
                    // 3. R-Type instruction: r11 = r9 op r10
                    imem_addr   <= 32'h8; // Address 8
                    imem_wdata  <= alu_instr;
                    state <= 3'd3;
                end
                3'd3: begin
                    // 4. JAL x0, 0 (Stop/loop instruction)
                    imem_addr   <= 32'hC; // Address 12
                    imem_wdata  <= 32'h0000006f; // JAL x0, 0
                    imem_we <= 1'b0; // Stop writing
                    done <= 1'b1; // Signal completion
                    // Stays in state 3'd3
                end
                default: begin
                    imem_we <= 1'b0;
                    done <= 1'b1;
                end
            endcase
        end
    end
endmodule