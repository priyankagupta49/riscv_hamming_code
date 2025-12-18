`timescale 1ns / 1ps

module tb();
    reg clk = 0;
    reg rst = 0;
    reg [7:0] operand1, operand2;
    reg [2:0] opcode;

    // Internal wires for interconnection
    wire [31:0] imem_waddr, imem_wdata;
    wire imem_we;
    wire [31:0] result_w;
    
    // CRITICAL: Initialize wire source or ensure it's driven
    wire done_signal; 

    // Clock generation: 100MHz (10ns period)
    always #5 clk = ~clk; 

    // Instruction Loader: Drives the 'done_signal'
    instr_loader loader (
        .clk(clk), 
        .rst(rst), 
        .op1(operand1), 
        .op2(operand2), 
        .alu_op(opcode),
        .imem_we(imem_we), 
        .imem_addr(imem_waddr), 
        .imem_wdata(imem_wdata), 
        .done(done_signal) // SOURCE
    );

    // CPU Instance: Receives the 'done_signal'
    Pipeline_top dut (
        .clk(clk), 
        .rst(rst), 
        .imem_we(imem_we), 
        .imem_waddr(imem_waddr), 
        .imem_wdata(imem_wdata), 
        .loader_done_in(done_signal), // DESTINATION
        .ResultW_out(result_w)
    );

   initial begin
        rst = 0;
        operand1 = 8'd10; operand2 = 8'd3; opcode = 3'd0; 
        #100; 
        @(posedge clk);
        rst = 1; 

        // CRITICAL FIX: Inject error while the loader is still writing
        // or immediately after done_signal, before the CPU reaches the read stage.
        wait(done_signal === 1'b1);
        
        $display("Injecting DOUBLE-BIT error BEFORE CPU reads memory...");
        // Inject into the address where you expect a LOAD to happen
        dut.memory.dmem.mem[1][6] = ~dut.memory.dmem.mem[1][6]; 
        //dut.memory.dmem.mem[1][5] = ~dut.memory.dmem.mem[1][5];

        #500;
        // Monitor the error signals from your Pipeline_top
        if (dut.dmem_error && dut.error_type_dmem)
            $display("SUCCESS: Double-bit error detected!");
        else
            $display("FAILURE: Error not detected or result was already processed.");

        $display("Final Result: %d", result_w);
        $finish;
    end




//initial begin
//        // ... (Reset and Loader sequence) ...
//        wait(done_signal === 1'b1);
        
//        // Inject double-bit error into memory index 1
//        dut.memory.dmem.mem[1][6] = ~dut.memory.dmem.mem[1][6]; 
//        dut.memory.dmem.mem[1][5] = ~dut.memory.dmem.mem[1][5];

//        #500; // Wait for the 'LW' instruction to reach the Memory Stage
        
//        // Monitor the Error Flags
//        if (dut.dmem_error && dut.error_type_dmem) begin
//            $display("SUCCESS: Double-bit error detected in Data Memory!");
//            $display("Result is now corrupted as expected.");
//        end else begin
//            $display("FAILURE: Error not detected. Check if CPU is actually reading mem[1].");
//        end
        
//        $display("Final Result: %h", result_w);
//        $finish;
//    end



    for now forget about double error `timescale 1ns / 1ps

module tb();
    reg clk = 0;
    reg rst = 0;
    reg [7:0] operand1, operand2;
    reg [2:0] opcode;

    // Internal wires for interconnection
    wire [31:0] imem_waddr, imem_wdata;
    wire imem_we;
    wire [31:0] result_w;
    
    // CRITICAL: Initialize wire source or ensure it's driven
    wire done_signal; 

    // Clock generation: 100MHz (10ns period)
    always #5 clk = ~clk; 

    // Instruction Loader: Drives the 'done_signal'
    instr_loader loader (
        .clk(clk), 
        .rst(rst), 
        .op1(operand1), 
        .op2(operand2), 
        .alu_op(opcode),
        .imem_we(imem_we), 
        .imem_addr(imem_waddr), 
        .imem_wdata(imem_wdata), 
        .done(done_signal) // SOURCE
    );

    // CPU Instance: Receives the 'done_signal'
    Pipeline_top dut (
        .clk(clk), 
        .rst(rst), 
        .imem_we(imem_we), 
        .imem_waddr(imem_waddr), 
        .imem_wdata(imem_wdata), 
        .loader_done_in(done_signal), // DESTINATION
        .ResultW_out(result_w)
    );

    initial begin
      
        rst = 0;
        operand1 = 8'd10; 
        operand2 = 8'd3; 
        opcode = 3'd0; 
        #100; 
        @(posedge clk);
        rst = 1; 
        $display("Reset released. Loader is writing to memory"); 
        wait(done_signal === 1'b1); 
        $display("Loader finished (done_signal = 1). CPU starting fetch at PC=0.");
        #500;      
        $display("Injecting single-bit error in Data Memory");      
        if (done_signal) begin
             dut.memory.dmem.mem[1][6] = ~dut.memory.dmem.mem[1][6]; //manual error generation by flipping bi
        end
        #500;
        $display("Final Result (Expected 13): %d", result_w);
        #50
        $finish;
    end
endmodule    in this tb add load and store instructions  such that  use of data memory occurs and show the original data corrupted data and final data




    `timescale 1ns / 1ps

module tb();
    reg clk = 0;
    reg rst = 0;
    reg [7:0] operand1, operand2;
    reg [2:0] opcode;

    wire [31:0] imem_waddr, imem_wdata;
    wire imem_we;
    wire [31:0] result_w;
    wire done_signal; 

    always #5 clk = ~clk; 

    instr_loader loader (
        .clk(clk), .rst(rst), .op1(operand1), .op2(operand2), .alu_op(opcode),
        .imem_we(imem_we), .imem_addr(imem_waddr), .imem_wdata(imem_wdata), 
        .done(done_signal)
    );

    Pipeline_top dut (
        .clk(clk), .rst(rst), .imem_we(imem_we), .imem_waddr(imem_waddr), 
        .imem_wdata(imem_wdata), .loader_done_in(done_signal), 
        .ResultW_out(result_w)
    );

    initial begin
        // 1. Initialization
        rst = 0;
        operand1 = 8'd10; operand2 = 8'd3; opcode = 3'd0; // Expect 13
        #20; 
        
        // 2. Release Reset
        @(posedge clk);
        rst = 1; 
        $display("--- Test Start ---");
        $display("Reset released. Loader writing SW/LW sequence.");

        // 3. Wait for Loader
        wait(done_signal === 1'b1);
        $display("Loader finished. CPU starting execution.");

        // 4. Wait for Store Word (SW) to complete
        // We wait for the value (13) to be written to Data Memory Address 4 (mem[1])
        repeat(5) @(posedge clk); 
        
        $display("Original Data in mem[1]: %h", dut.memory.dmem.mem[1][31:0]);

        // 5. Inject SINGLE-BIT Error
        // Flip bit 6 of the encoded word in memory index 1
        $display("Injecting single-bit error at mem[1] bit [6]...");
        dut.memory.dmem.mem[1][3] = ~dut.memory.dmem.mem[1][3];
        
        $display("Corrupted Data (Raw Memory): %h", dut.memory.dmem.mem[1][31:0]);

        // 6. Wait for Load Word (LW) to process the error
        // LW will read the corrupted data, syndrome will be non-zero, s_err will trigger.
        #20;

        // 7. Verification
        if (dut.dmem_error && !dut.error_type_dmem) begin
            $display("SUCCESS: Single-bit error detected and corrected!");
        end else if (dut.dmem_error && dut.error_type_dmem) begin
            $display("WARNING: Double-bit error detected instead of single!");
        end else begin
            $display("FAILURE: No error detected by Memory Stage.");
        end

        $display("Final Corrected Result (Register r12): %d", result_w);
        
        
        $finish;
    end
endmodule

endmodule

