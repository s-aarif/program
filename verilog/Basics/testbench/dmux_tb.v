`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.10.2025 21:43:02
// Design Name: 
// Module Name: dmux_tb
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


module dmux_tb;

    reg Data_in;
    reg [1:0] S;
    reg Enable;
    wire [0:3] O;

    dmux dut (
        .Data_in(Data_in),
        .S(S),
        .Enable(Enable),
        .O(O)
    );

    initial begin
        $monitor("Time=%0t | Enable=%b, Data_in=%b, S=%b | O=%b", $time, Enable, Data_in, S, O);
        
        Enable = 1'b1;
        Data_in = 1'b1; 
        
        S = 2'b00; 
        #10; 
        
        S = 2'b01;
        #10;
        
        S = 2'b10;
        #10;
        
        S = 2'b11;
        #10;
        
        Data_in = 1'b0;
        
        S = 2'b00;
        #10;
        
        S = 2'b01;
        #10;
        
        Enable = 1'b0;
        Data_in = 1'b1; 
        
        S = 2'b00;
        #10;
        
        S = 2'b11;
        #10;
        
        $finish;
    end

endmodule

