`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 09:35:00
// Design Name: 
// Module Name: siso_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for 4-bit SISO Shift Register
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module siso_tb;
    reg clk;
    reg rst_n;
    reg s_in;
    
    wire s_out;
    
    siso uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .s_in(s_in), 
        .s_out(s_out)
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
        s_in = 1'b1; #10; $display("Clock 1: s_in=%b | s_out=%b", s_in, s_out);
        s_in = 1'b0; #10; $display("Clock 2: s_in=%b | s_out=%b", s_in, s_out);
        s_in = 1'b1; #10; $display("Clock 3: s_in=%b | s_out=%b", s_in, s_out);
        s_in = 1'b0; #10; $display("Clock 4: s_in=%b | s_out=%b", s_in, s_out);
        
        $display("--- Data shifting out ---");
        s_in = 1'b0; #10; $display("Clock 5: s_in=%b | s_out=%b (1st bit out)", s_in, s_out);
        s_in = 1'b0; #10; $display("Clock 6: s_in=%b | s_out=%b (2nd bit out)", s_in, s_out);
        s_in = 1'b0; #10; $display("Clock 7: s_in=%b | s_out=%b (3rd bit out)", s_in, s_out);
        s_in = 1'b0; #10; $display("Clock 8: s_in=%b | s_out=%b (4th bit out)", s_in, s_out);
        
        $display("\n========== Test 2: Reset during operation ==========");
        s_in = 1'b1; #10;
        s_in = 1'b1; #10;
        rst_n = 1'b0; #20;  
        $display("After reset: s_out=%b (should be 0)", s_out);
        rst_n = 1'b1; #10;

        $display("\n========== Test 3: Shift in 1111 ==========");
        s_in = 1'b1; #10; $display("Clock 1: s_in=%b | s_out=%b", s_in, s_out);
        s_in = 1'b1; #10; $display("Clock 2: s_in=%b | s_out=%b", s_in, s_out);
        s_in = 1'b1; #10; $display("Clock 3: s_in=%b | s_out=%b", s_in, s_out);
        s_in = 1'b1; #10; $display("Clock 4: s_in=%b | s_out=%b", s_in, s_out);
        
        $display("--- Data shifting out ---");
        s_in = 1'b0; #10; $display("Clock 5: s_out=%b (expect 1)", s_out);
        s_in = 1'b0; #10; $display("Clock 6: s_out=%b (expect 1)", s_out);
        s_in = 1'b0; #10; $display("Clock 7: s_out=%b (expect 1)", s_out);
        s_in = 1'b0; #10; $display("Clock 8: s_out=%b (expect 1)", s_out);
        
        $display("\n========== Test 4: Shift in 0000 ==========");
        rst_n = 1'b0; #10;
        rst_n = 1'b1; #10;
        
        s_in = 1'b0; #10; $display("Clock 1: s_in=%b | s_out=%b", s_in, s_out);
        s_in = 1'b0; #10; $display("Clock 2: s_in=%b | s_out=%b", s_in, s_out);
        s_in = 1'b0; #10; $display("Clock 3: s_in=%b | s_out=%b", s_in, s_out);
        s_in = 1'b0; #10; $display("Clock 4: s_in=%b | s_out=%b", s_in, s_out);
        
        $display("\n========== Test 5: Continuous shifting ==========");
        s_in = 1'b1; #10;
        s_in = 1'b0; #10;
        s_in = 1'b1; #10;
        s_in = 1'b1; #10;
        s_in = 1'b0; #10;
        s_in = 1'b1; #10;
        s_in = 1'b0; #10;
        s_in = 1'b0; #10;
        
        #50;
        $finish;
    end
    
    // Monitor for continuous observation
    initial begin
        $monitor("Time=%0t | clk=%b | rst_n=%b | s_in=%b | s_out=%b", 
                 $time, clk, rst_n, s_in, s_out);
    end
      
endmodule