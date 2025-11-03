`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.10.2025 23:35:00
// Design Name: 
// Module Name: sync_counter_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for 4-bit Synchronous Counter
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module sync_counter_tb;
    reg clk;
    reg rst_n;
    reg en;
    
    wire [3:0] q;
    
    sync_counter uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .en(en), 
        .q(q)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  
    end
    
    initial begin
        rst_n = 1'b0;
        en = 1'b0;
        #20;
        
        rst_n = 1'b1;
        en = 1'b1;
        #200;  
        
        en = 1'b0;
        #50;
        
        en = 1'b1;
        #100;
        
        #50;
        rst_n = 1'b0;
        #20;
        
        rst_n = 1'b1;
        #200;
        
        rst_n = 1'b0;
        #10;
        rst_n = 1'b1;
        #170;  
        
        #300;
        
        #50;
        rst_n = 1'b0;
        #15;
        rst_n = 1'b1;
        #100;
        
        #50;
        $finish;
    end
    
    initial begin
        $monitor("Time=%0t ns | clk=%b | rst_n=%b | en=%b | q=%b (%0d)", 
                 $time, clk, rst_n, en, q, q);
    end
      
endmodule