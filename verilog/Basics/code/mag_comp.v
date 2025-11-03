`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 09:13:51
// Design Name: 
// Module Name: mag_comp
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


module mag_comp(
    input [3:0] A,
    input [3:0] B,
    output reg A_gt_b,
    output reg A_lt_b,
    output reg A_eq_b
    );
    
    always@(*) begin    
        A_gt_b = 1'b0;
        A_lt_b = 1'b0;
        A_eq_b = 1'b0;
        if (A > B) begin
            A_gt_b = 1'b1;
        end else if (A>B) begin
            A_lt_b = 1'b1;
        end else begin 
            A_eq_b = 1'b1;
        end
    end                 
    
endmodule
