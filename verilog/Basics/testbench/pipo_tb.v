`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 10:45:00
// Design Name: 
// Module Name: pipo_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for 4-bit PIPO Shift Register
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module pipo_tb;
    reg clk;
    reg rst_n;
    reg l_en;
    reg s_in_sr;
    reg [3:0] p_in;
    
    wire [3:0] p_out;
    
    pipo uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .l_en(l_en), 
        .s_in_sr(s_in_sr), 
        .p_in(p_in), 
        .p_out(p_out)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst_n = 1'b0;
        l_en = 1'b0;
        s_in_sr = 1'b0;
        p_in = 4'b0000;
        
        #20;
        
        rst_n = 1'b1;
        #10;
        
        $display("\n========== Test 1: Parallel Load 1010 ==========");
        l_en = 1'b1;
        p_in = 4'b1010;
        #10;
        $display("Loaded p_in=%b | p_out=%b", p_in, p_out);
        
        $display("\n========== Test 2: Parallel Load 1111 ==========");
        p_in = 4'b1111;
        #10;
        $display("Loaded p_in=%b | p_out=%b", p_in, p_out);
        
        $display("\n========== Test 3: Parallel Load 0000 ==========");
        p_in = 4'b0000;
        #10;
        $display("Loaded p_in=%b | p_out=%b", p_in, p_out);
        
        $display("\n========== Test 4: Serial Shift Mode ==========");
        p_in = 4'b1100;
        l_en = 1'b1;
        #10;
        $display("Initial load: p_in=%b | p_out=%b", p_in, p_out);
        
        l_en = 1'b0; 
        s_in_sr = 1'b1;
        #10; $display("Shift 1: s_in=%b | p_out=%b", s_in_sr, p_out);
        
        s_in_sr = 1'b0;
        #10; $display("Shift 2: s_in=%b | p_out=%b", s_in_sr, p_out);
        
        s_in_sr = 1'b1;
        #10; $display("Shift 3: s_in=%b | p_out=%b", s_in_sr, p_out);
        
        s_in_sr = 1'b0;
        #10; $display("Shift 4: s_in=%b | p_out=%b", s_in_sr, p_out);
        
        $display("\n========== Test 5: Shift in 1010 serially ==========");
        rst_n = 1'b0; #10; rst_n = 1'b1; #10;
        l_en = 1'b0;
        
        s_in_sr = 1'b1; #10; $display("Clock 1: s_in=%b | p_out=%b", s_in_sr, p_out);
        s_in_sr = 1'b0; #10; $display("Clock 2: s_in=%b | p_out=%b", s_in_sr, p_out);
        s_in_sr = 1'b1; #10; $display("Clock 3: s_in=%b | p_out=%b", s_in_sr, p_out);
        s_in_sr = 1'b0; #10; $display("Clock 4: s_in=%b | p_out=%b", s_in_sr, p_out);
        
        $display("\n========== Test 6: Load then shift ==========");
        l_en = 1'b1;
        p_in = 4'b0011;
        #10;
        $display("Loaded: p_in=%b | p_out=%b", p_in, p_out);
        
        l_en = 1'b0;
        s_in_sr = 1'b1;
        #10; $display("After shift 1: p_out=%b", p_out);
        #10; $display("After shift 2: p_out=%b", p_out);
        
        $display("\n========== Test 7: Reset during operation ==========");
        l_en = 1'b1;
        p_in = 4'b1111;
        #10;
        $display("Before reset: p_out=%b", p_out);
        
        rst_n = 1'b0;
        #20;
        $display("After reset: p_out=%b (Expected: 0000)", p_out);
        rst_n = 1'b1;
        #10;
        
        $display("\n========== Test 8: Toggle between modes ==========");
        l_en = 1'b1;
        p_in = 4'b1010;
        #10;
        $display("Parallel load: p_out=%b", p_out);
        
        l_en = 1'b0;
        s_in_sr = 1'b0;
        #10;
        $display("Shift mode: p_out=%b", p_out);
        
        l_en = 1'b1;
        p_in = 4'b0101;
        #10;
        $display("Back to parallel: p_out=%b", p_out);
        
        $display("\n========== Test 9: Continuous serial shift ==========");
        l_en = 1'b0;
        s_in_sr = 1'b1;
        #10; $display("Shift: p_out=%b", p_out);
        s_in_sr = 1'b1;
        #10; $display("Shift: p_out=%b", p_out);
        s_in_sr = 1'b1;
        #10; $display("Shift: p_out=%b", p_out);
        s_in_sr = 1'b1;
        #10; $display("Shift: p_out=%b", p_out);
        
        $display("\n========== Test 10: Various patterns ==========");
        l_en = 1'b1;
        p_in = 4'b1100; #10; $display("Load %b → p_out=%b", p_in, p_out);
        p_in = 4'b0011; #10; $display("Load %b → p_out=%b", p_in, p_out);
        p_in = 4'b1001; #10; $display("Load %b → p_out=%b", p_in, p_out);
        p_in = 4'b0110; #10; $display("Load %b → p_out=%b", p_in, p_out);
        
        #50;
        $finish;
    end
    
    initial begin
        $monitor("Time=%0t | clk=%b | rst_n=%b | l_en=%b | s_in_sr=%b | p_in=%b | p_out=%b", 
                 $time, clk, rst_n, l_en, s_in_sr, p_in, p_out);
    end
      
endmodule