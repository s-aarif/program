`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.10.2025 22:45:00
// Design Name: 
// Module Name: jk_ff_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for JK Flip-Flop with Asynchronous Reset
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module jk_ff_tb;
    reg clk;
    reg rst_n;
    reg j;
    reg k;
    
    wire q;
    wire q_n;
    
    jk_ff uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .j(j), 
        .k(k), 
        .q(q), 
        .q_n(q_n)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end
    
    initial begin
        rst_n = 1'b1;
        j = 1'b0;
        k = 1'b0;
        
        #10;
        
        rst_n = 1'b0;
        #20;
        
        rst_n = 1'b1;
        #10;
        
        j = 1'b0;
        k = 1'b0;
        #20;
        
        j = 1'b1;
        k = 1'b0;
        #10;
        
        j = 1'b0;
        k = 1'b0;
        #10;
        
        j = 1'b0;
        k = 1'b1;
        #10;
        
        j = 1'b1;
        k = 1'b0;
        #10;
        
        j = 1'b1;
        k = 1'b1;
        #10;
        
        j = 1'b1;
        k = 1'b1;
        #10;
        
        j = 1'b1;
        k = 1'b1;
        #10;  
        #10; 
        #10;  
        #10; 
        
        j = 1'b1;
        k = 1'b0;
        #5;
        rst_n = 1'b0;  
        #15;
        
        rst_n = 1'b1;
        #10;
        
        j = 1'b0; k = 1'b0; #10;
        
        j = 1'b0; k = 1'b1; #10;
        
        j = 1'b1; k = 1'b0; #10;
        
        j = 1'b1; k = 1'b1; #10;
        
        j = 1'b0; k = 1'b0; #10;
        j = 1'b1; k = 1'b0; #10;
        j = 1'b0; k = 1'b1; #10;
        j = 1'b1; k = 1'b1; #10;
        j = 1'b0; k = 1'b0; #10;
        
        j = 1'b0;
        k = 1'b0;
        #40;  
        
        j = 1'b1;
        k = 1'b1;
        #50;  
        
        rst_n = 1'b0;
        #15;
        rst_n = 1'b1;
        #20;
        
        #50;
        $finish;
    end
    
    initial begin
        $monitor("Time=%0t | clk=%b | rst_n=%b | j=%b | k=%b | q=%b | q_n=%b", 
                 $time, clk, rst_n, j, k, q, q_n);
    end
      
endmodule