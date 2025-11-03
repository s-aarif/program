`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 10:05:00
// Design Name: 
// Module Name: sipo_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for 4-bit SIPO Shift Register
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module sipo_tb;
    reg clk;
    reg rst_n;
    reg s_in;
    
    wire [3:0] p_out;
    
    sipo uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .s_in(s_in), 
        .p_out(p_out)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst_n = 1'b0;
        s_in = 1'b0;
        
        #20;
        
        rst_n = 1'b1;
        #10;
        
        $display("\n========== Test 1: Shift in 1010 ==========");
        s_in = 1'b1; #10; $display("Clock 1: s_in=%b | p_out=%b (%0d)", s_in, p_out, p_out);
        s_in = 1'b0; #10; $display("Clock 2: s_in=%b | p_out=%b (%0d)", s_in, p_out, p_out);
        s_in = 1'b1; #10; $display("Clock 3: s_in=%b | p_out=%b (%0d)", s_in, p_out, p_out);
        s_in = 1'b0; #10; $display("Clock 4: s_in=%b | p_out=%b (%0d)", s_in, p_out, p_out);
        $display("Final parallel output: %b (Expected: 1010 or 0101 depending on shift direction)", p_out);
        
        #20;
        
        $display("\n========== Test 2: Reset during operation ==========");
        s_in = 1'b1; #10;
        s_in = 1'b1; #10;
        $display("Before reset: p_out=%b", p_out);
        rst_n = 1'b0; #20;
        $display("After reset: p_out=%b (Expected: 0000)", p_out);
        rst_n = 1'b1; #10;
        
        $display("\n========== Test 3: Shift in 1111 ==========");
        s_in = 1'b1; #10; $display("Clock 1: s_in=%b | p_out=%b", s_in, p_out);
        s_in = 1'b1; #10; $display("Clock 2: s_in=%b | p_out=%b", s_in, p_out);
        s_in = 1'b1; #10; $display("Clock 3: s_in=%b | p_out=%b", s_in, p_out);
        s_in = 1'b1; #10; $display("Clock 4: s_in=%b | p_out=%b", s_in, p_out);
        $display("Final parallel output: %b (Expected: 1111)", p_out);
        
        #20;
        
        $display("\n========== Test 4: Shift in 0000 ==========");
        s_in = 1'b0; #10; $display("Clock 1: s_in=%b | p_out=%b", s_in, p_out);
        s_in = 1'b0; #10; $display("Clock 2: s_in=%b | p_out=%b", s_in, p_out);
        s_in = 1'b0; #10; $display("Clock 3: s_in=%b | p_out=%b", s_in, p_out);
        s_in = 1'b0; #10; $display("Clock 4: s_in=%b | p_out=%b", s_in, p_out);
        $display("Final parallel output: %b (Expected: 0000)", p_out);
        
        #20;
        
        $display("\n========== Test 5: Shift in 1100 ==========");
        rst_n = 1'b0; #10; rst_n = 1'b1; #10;
        s_in = 1'b1; #10; $display("Clock 1: s_in=%b | p_out=%b", s_in, p_out);
        s_in = 1'b1; #10; $display("Clock 2: s_in=%b | p_out=%b", s_in, p_out);
        s_in = 1'b0; #10; $display("Clock 3: s_in=%b | p_out=%b", s_in, p_out);
        s_in = 1'b0; #10; $display("Clock 4: s_in=%b | p_out=%b", s_in, p_out);
        $display("Final parallel output: %b", p_out);
        
        #20;
        
        $display("\n========== Test 6: Shift in 0101 ==========");
        rst_n = 1'b0; #10; rst_n = 1'b1; #10;
        s_in = 1'b0; #10; $display("Clock 1: s_in=%b | p_out=%b", s_in, p_out);
        s_in = 1'b1; #10; $display("Clock 2: s_in=%b | p_out=%b", s_in, p_out);
        s_in = 1'b0; #10; $display("Clock 3: s_in=%b | p_out=%b", s_in, p_out);
        s_in = 1'b1; #10; $display("Clock 4: s_in=%b | p_out=%b", s_in, p_out);
        $display("Final parallel output: %b", p_out);
        
        #20;
        
        $display("\n========== Test 7: Continuous shifting ==========");
        rst_n = 1'b0; #10; rst_n = 1'b1; #10;
        s_in = 1'b1; #10; $display("p_out=%b", p_out);
        s_in = 1'b0; #10; $display("p_out=%b", p_out);
        s_in = 1'b1; #10; $display("p_out=%b", p_out);
        s_in = 1'b1; #10; $display("p_out=%b", p_out);
        s_in = 1'b0; #10; $display("p_out=%b (old bit shifted out)", p_out);
        s_in = 1'b1; #10; $display("p_out=%b (old bit shifted out)", p_out);
        
        #50;
        $finish;
    end
    
    // Monitor for continuous observation
    initial begin
        $monitor("Time=%0t | clk=%b | rst_n=%b | s_in=%b | p_out=%b (%0d)", 
                 $time, clk, rst_n, s_in, p_out, p_out);
    end
      
endmodule