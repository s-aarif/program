`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.09.2025 12:52:05
// Design Name: 
// Module Name: mux
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


module mux(
    input [3:0] I,
    input [1:0] S,
    output Y
    );
    
    assign Y = I[S];
    assign Y = (S == 2'b00) ? I[0] :
                      (S == 2'b01) ? I[1] :
                      (S == 2'b10) ? I[2] :
                      I[3] ;
endmodule

//module dmux (
//    input Data_in,
//    input [1:0] S,
//    input Enable,
//    output [0:3] O
//);

//    assign O[0] = (Enable && (S == 2'b00)) ? Data_in : 1'b0;
//    assign O[1] = (Enable && (S == 2'b01)) ? Data_in : 1'b0;
//    assign O[2] = (Enable && (S == 2'b10)) ? Data_in : 1'b0;
//    assign O[3] = (Enable && (S == 2'b11)) ? Data_in : 1'b0;


//endmodule
