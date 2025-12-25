`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 10:08:15
// Design Name: 
// Module Name: pipo
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


module pipo(
    input clk,
    input rst_n,
    input l_en,
    input s_in_sr,
    input [3:0] p_in,
    output [3:0] p_out
    );
    
    reg [3:0] q_reg;
    assign p_out = q_reg;
    always @ (posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            q_reg <= 4'b0000;
        end else begin 
            if (l_en == 1'b1) begin 
                q_reg <= p_in;
            end else begin 
                q_reg <= {s_in_sr, q_reg[3:1]} ;
            end
        end
    end                    
    
endmodule
