`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.10.2025 22:15:00
// Design Name: 
// Module Name: d_ff_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for D Flip-Flop with Asynchronous Reset
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module d_ff_tb;
    reg CLK;
    reg RST_n;
    reg D;
    
    wire Q;
    wire Q_n;
    
    d_ff uut (
        .CLK(CLK), 
        .RST_n(RST_n), 
        .D(D), 
        .Q(Q), 
        .Q_n(Q_n)
    );
    
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;  
    end
    
    initial begin
        RST_n = 1'b1;
        D = 1'b0;
        

        #10;
        

        RST_n = 1'b0;
        #20;
        
        RST_n = 1'b1;
        #10;
        
        D = 1'b1;
        #10;  
        
        D = 1'b0;
        #10;
        
        D = 1'b1; #10;
        D = 1'b0; #10;
        D = 1'b1; #10;
        D = 1'b1; #10;
        D = 1'b0; #10;
        
        D = 1'b1;
        #30;  
        
        D = 1'b1;
        #5;
        RST_n = 1'b0;   
        #15;
        
        RST_n = 1'b1;
        #10;
        
        D = 1'b0; #10;
        D = 1'b1; #10;
        D = 1'b0; #10;
        D = 1'b1; #10;
        
        RST_n = 1'b0;
        #15;
        RST_n = 1'b1;
        #20;
        
        D = 1'b1;
        #8;
        D = 1'b0;  
        #10;
        
        D = 1'b1;
        #20;
        
        #50;
        $finish;
    end
    initial begin
        $monitor("Time=%0t | CLK=%b | RST_n=%b | D=%b | Q=%b | Q_n=%b", 
                 $time, CLK, RST_n, D, Q, Q_n);
    end
      
endmodule