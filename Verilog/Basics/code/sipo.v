`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 09:42:32
// Design Name: 
// Module Name: sipo
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


module sipo(
    input clk,
    input rst_n,
    input s_in,
    output [3:0] p_out
    );
    
    reg [3:0] q_reg ;
    assign p_out = q_reg ;
    always @ (posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            q_reg <= 4'b0000;
        end else begin 
            q_reg <= {s_in, q_reg [3:1]} ;
        end
    end           
endmodule
