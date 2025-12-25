`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.10.2025 21:44:50
// Design Name: 
// Module Name: decoder
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


module decoder(
    input [2:0] S,
    input Enable,
    output reg [7:0] O
    );
    
    always @(*) begin 
        if (Enable == 1'b0) begin   
            O = 8'b00000000;
        end else begin 
            case (S) 
                3'b000 : O = 8'b00000001;
                3'b001 : O = 8'b00000010;
                3'b010 : O = 8'b00000100;
                3'b011 : O = 8'b00001000;
                3'b100 : O = 8'b00010000;
                3'b101 : O = 8'b00100000;
                3'b110 : O = 8'b01000000;
                3'b111 : O = 8'b10000000;
                default : O = 8'bxxxxxxxx;
            endcase
        end
    end
    
endmodule
