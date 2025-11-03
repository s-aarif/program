`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.10.2025 23:00:00
// Design Name: 
// Module Name: async_counter_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for 4-bit Asynchronous Counter
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module async_counter_tb;
    reg clk;
    reg rst_n;
    
    wire [3:0] q;
    async_counter uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .q(q)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  
    end
    
    initial begin
        rst_n = 1'b0;  
        
        #20;
        
        rst_n = 1'b1;
        #200;  
        
        #50;
        rst_n = 1'b0;  
        #30;
        
        rst_n = 1'b1;
        #300;  
        
        rst_n = 1'b0;
        #15;
        rst_n = 1'b1;
        #100;
        
        #500;  
        
        #50;
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;
        #200;
        
        $finish;
    end
    
    initial begin
        $monitor("Time=%0t ns | clk=%b | rst_n=%b | Count q=%b (%0d)", 
                 $time, clk, rst_n, q, q);
    end
    
    always @(q) begin
        $display("Time=%0t ns | Counter value changed to: %b (Decimal: %0d)", 
                 $time, q, q);
    end
      
endmodule