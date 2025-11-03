`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.10.2025 23:30:07
// Design Name: 
// Module Name: sync_counter
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


module sync_counter(
    input clk,
    input rst_n,
    input en,
    output reg [3:0] q
    );
    always @ (posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            q <= 4'b0000;
        end else begin 
            q <= q+1'b1;
        end
    end
    
endmodule
