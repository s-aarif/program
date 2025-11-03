`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 21:24:09
// Design Name: 
// Module Name: encoder_p_tb
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


module encoder_p_tb;

    reg [7:0] I;
    wire [2:0] Y;
    wire V;

    encoder_p dut (
        .I(I),
        .Y(Y),
        .V(V)
    );

    initial begin
        $monitor("Time=%0t | I=%b | Y=%b, V=%b", $time, I, Y, V);
    end

    initial begin
        I = 8'b00000000;
        #10;

        I = 8'b10000000;
        #10;
        
        I = 8'b01000000;
        #10;
        
        I = 8'b00100000;
        #10;
        
        I = 8'b00010000;
        #10;
        
        I = 8'b00001000;
        #10;
        
        I = 8'b00000100;
        #10;
        
        I= 8'b00000010;
        #10;
        
        I= 8'b00000001;
        #10;
        
        I = 8'b11111111;
        #10;

        I = 8'b00000000;
        
        
    end

endmodule
