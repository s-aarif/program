`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 09:30:42
// Design Name: 
// Module Name: siso
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


module siso(
    input clk,
    input rst_n,
    input s_in,
    output s_out
    );
    reg [3:0] q_reg;
    assign s_out = q_reg[0];
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            q_reg <= 4'b0000;
        end else begin 
            q_reg <= {s_in, q_reg [3:1]};
        end
    end             
    
endmodule
