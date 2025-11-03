`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2025 09:27:38
// Design Name: 
// Module Name: half
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


module half(
    input A,
    input B,
    output Sum,
    output Carry
    );
    
    assign Sum = A ^ B ;
    assign Carry = (A & B);
endmodule


