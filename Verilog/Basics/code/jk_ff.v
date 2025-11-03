`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.10.2025 22:21:22
// Design Name: 
// Module Name: jk_ff
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


module jk_ff(
    input clk,
    input rst_n,
    input j,k ,
    output reg q,
    output reg q_n
    );
    
    always @(posedge clk or negedge rst_n)
        if (rst_n==1'b0) begin
            q<= 1'b0;
            q_n <= 1'b1;
        end else if (clk) begin
            case ({j,k}) 
                2'b00 : begin
                end  
                2'b01 : begin 
                    q<= 1'b0;
                    q_n <= 1'b1;
                end
                2'b10 : begin 
                    q<= 1'b1;
                    q_n <= 1'b0;
                end
                2'b11 : begin 
                    q<= ~q;
                    q_n <= q;
                end
                default : begin 
                    q <= 1'bx;
                    q_n <= 1'bx;
                end
            endcase
        end                           
            
endmodule
