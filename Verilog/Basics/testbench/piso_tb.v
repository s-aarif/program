`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 10:30:00
// Design Name: 
// Module Name: piso_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for 4-bit PISO Shift Register
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module piso_tb;
    reg clk;
    reg rst_n;
    reg load_en;
    reg [3:0] p_in;
    
    wire s_out;
    
    piso uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .load_en(load_en), 
        .p_in(p_in), 
        .s_out(s_out)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst_n = 1'b0;
        load_en = 1'b0;
        p_in = 4'b0000;
        
        #20;
        
        rst_n = 1'b1;
        #10;
        
        $display("\n========== Test 1: Load 1010 and shift out ==========");
        p_in = 4'b1010;
        load_en = 1'b1;
        #10;  
        $display("Loaded p_in=%b", p_in);
        
        load_en = 1'b0;  
        #10; $display("Clock 1: s_out=%b (LSB first)", s_out);
        #10; $display("Clock 2: s_out=%b", s_out);
        #10; $display("Clock 3: s_out=%b", s_out);
        #10; $display("Clock 4: s_out=%b (MSB)", s_out);
        #10; $display("Clock 5: s_out=%b (all shifted out)", s_out);
        
        
        $display("\n========== Test 2: Load 1111 and shift out ==========");
        p_in = 4'b1111;
        load_en = 1'b1;
        #10;
        $display("Loaded p_in=%b", p_in);
        
        load_en = 1'b0;
        #10; $display("Clock 1: s_out=%b", s_out);
        #10; $display("Clock 2: s_out=%b", s_out);
        #10; $display("Clock 3: s_out=%b", s_out);
        #10; $display("Clock 4: s_out=%b", s_out);
        
        
        $display("\n========== Test 3: Load 0000 and shift out ==========");
        p_in = 4'b0000;
        load_en = 1'b1;
        #10;
        $display("Loaded p_in=%b", p_in);
        
        load_en = 1'b0;
        #10; $display("Clock 1: s_out=%b", s_out);
        #10; $display("Clock 2: s_out=%b", s_out);
        #10; $display("Clock 3: s_out=%b", s_out);
        #10; $display("Clock 4: s_out=%b", s_out);
        
        $display("\n========== Test 4: Load 1100 and shift out ==========");
        p_in = 4'b1100;
        load_en = 1'b1;
        #10;
        $display("Loaded p_in=%b", p_in);
        
        load_en = 1'b0;
        #10; $display("Clock 1: s_out=%b", s_out);
        #10; $display("Clock 2: s_out=%b", s_out);
        #10; $display("Clock 3: s_out=%b", s_out);
        #10; $display("Clock 4: s_out=%b", s_out);
        
        $display("\n========== Test 5: Reset during shifting ==========");
        p_in = 4'b1010;
        load_en = 1'b1;
        #10;
        load_en = 1'b0;
        #10; $display("Before reset: s_out=%b", s_out);
        #10;
        rst_n = 1'b0;
        #20;
        $display("After reset: s_out=%b (Expected: 0)", s_out);
        rst_n = 1'b1;
        #10;
        
        $display("\n========== Test 6: Load new data while shifting ==========");
        p_in = 4'b1111;
        load_en = 1'b1;
        #10;
        load_en = 1'b0;
        #10; $display("Clock 1: s_out=%b", s_out);
        #10; $display("Clock 2: s_out=%b", s_out);
        
        p_in = 4'b0101;
        load_en = 1'b1;
        #10;
        $display("New data loaded: %b", p_in);
        
        load_en = 1'b0;
        #10; $display("Clock 1: s_out=%b", s_out);
        #10; $display("Clock 2: s_out=%b", s_out);
        #10; $display("Clock 3: s_out=%b", s_out);
        #10; $display("Clock 4: s_out=%b", s_out);
        
        $display("\n========== Test 7: Continuous load mode ==========");
        p_in = 4'b1010;
        load_en = 1'b1;
        #10; $display("s_out=%b (loading)", s_out);
        #10; $display("s_out=%b (loading)", s_out);
        #10; $display("s_out=%b (loading)", s_out);
        
        $display("\n========== Test 8: Multiple cycles ==========");
        p_in = 4'b0011;
        load_en = 1'b1;
        #10;
        load_en = 1'b0;
        #40;  
        
        p_in = 4'b1100;
        load_en = 1'b1;
        #10;
        load_en = 1'b0;
        #40;  
        
        #50;
        $finish;
    end
    
    initial begin
        $monitor("Time=%0t | clk=%b | rst_n=%b | load_en=%b | p_in=%b | s_out=%b", 
                 $time, clk, rst_n, load_en, p_in, s_out);
    end
      
endmodule