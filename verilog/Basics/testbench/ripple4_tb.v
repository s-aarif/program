`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 12:30:00
// Design Name: 
// Module Name: ripple_carry_adder_4bit_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Simple Testbench for 4-bit Ripple Carry Adder
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ripple_carry_adder_4bit_tb;

    reg [3:0] a;
    reg [3:0] b;
    reg cin;
    
    wire [3:0] sum;
    wire cout;
    
    ripple_carry_adder_4bit uut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );
    
    initial begin
        // Test Case 1: 0 + 0 + 0
        a = 4'b0000;
        b = 4'b0000;
        cin = 1'b0;
        #10;
        
        a = 4'b0101;
        b = 4'b0011;
        cin = 1'b0;
        #10;
        
        a = 4'b1010;
        b = 4'b0111;
        cin = 1'b0;
        #10;
        
        a = 4'b1111;
        b = 4'b1111;
        cin = 1'b0;
        #10;
        
        a = 4'b0111;
        b = 4'b1000;
        cin = 1'b1;
        #10;
        
        a = 4'b1111;
        b = 4'b1111;
        cin = 1'b1;
        #10;
        
        a = 4'b0001;
        b = 4'b0001;
        cin = 1'b0;
        #10;    
           
        $finish;
    end

endmodule