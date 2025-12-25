`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.10.2025 21:42:04
// Design Name: 
// Module Name: dmux
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


module dmux (
    input Data_in,
    input [1:0] S,
    input Enable,
    output [0:3] O
);

    assign O[0] = (Enable && (S == 2'b00)) ? Data_in : 1'b0;
    assign O[1] = (Enable && (S == 2'b01)) ? Data_in : 1'b0;
    assign O[2] = (Enable && (S == 2'b10)) ? Data_in : 1'b0;
    assign O[3] = (Enable && (S == 2'b11)) ? Data_in : 1'b0;


endmodule
