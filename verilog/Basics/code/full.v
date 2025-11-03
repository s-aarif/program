`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2025 10:18:41
// Design Name: 
// Module Name: full
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


module full(
    input A,
    input B,
    input Cin,
    output Sum,
    output Carry
    );
    
    assign Sum = A ^ B ^ Cin;
    assign Carry = ((A & B) | (B & Cin) | (Cin & A));
    
endmodule
