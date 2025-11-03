`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.10.2025 22:54:09
// Design Name: 
// Module Name: gate_final
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


module gate_final(
    input A,
    input B,
    output [3:0] Y
    );
    
    and_gate uut_and (.A(A), .B(B),.Y(Y[0]) );
    or_gate uut_or (.A(A), .B(B),.Y(Y[1]) );
    xor_gate uut_xor (.A(A), .B(B),.Y(Y[2]) );
    not_gate uut_not (.A(A), .Y(Y[3]) );
    
endmodule
