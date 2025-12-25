`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2025 09:44:29
// Design Name: 
// Module Name: half_tb
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


module half_tb;
    reg A;
    reg B;
    wire Sum;
    wire Carry;
    half uut ( .A(A), .B(B), .Sum(Sum), .Carry(Carry)
    );
    
    initial begin
     A=1'b0; B=1'b0; #10;
    A=1'b0; B=1'b1; #10;
    A=1'b1; B=1'b0; #10;
    A=1'b1; B=1'b1; #10;
   
    $display ("The output was verified successfully");
    $finish;
    
end

endmodule
    
    
