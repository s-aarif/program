`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2025 10:19:06
// Design Name: 
// Module Name: full_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module full_tb;
    reg A, B, Cin;
    wire Sum, Carry;
    
    full uut ( .A(A), .B(B), .Cin(Cin), .Sum(Sum), .Carry(Carry)
    );
    
    initial begin 
        A=1'b0; B=1'b0; Cin=1'b0; #10;        
        A=1'b0; B=1'b0; Cin=1'b1; #10;
        A=1'b0; B=1'b1; Cin=1'b0; #10;
        A=1'b0; B=1'b1; Cin=1'b1; #10;
        A=1'b1; B=1'b0; Cin=1'b0; #10;
        A=1'b1; B=1'b0; Cin=1'b1; #10;
        A=1'b1; B=1'b1; Cin=1'b0; #10;
        A=1'b1; B=1'b1; Cin=1'b1; #10;
       
        $display ("The output was verified successfully");
        $finish;
    

    end
endmodule
