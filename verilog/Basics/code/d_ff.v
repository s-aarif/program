`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.10.2025 22:09:17
// Design Name: 
// Module Name: d_ff
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


module d_ff(
    input CLK,
    input RST_n,
    input D,
    output reg Q,
    output reg Q_n
    );
    
    always @(posedge CLK or negedge RST_n) begin
        if (RST_n == 1'b0) begin
            Q <=1'b0;
            Q_n <= 1'b1;
        end else if (CLK) begin
            Q <= D;
            Q_n <= ~D;
        end
    end            
    
endmodule
