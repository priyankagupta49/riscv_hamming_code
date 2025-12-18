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

endmodule
