`timescale 1ns / 1ps

// -----------------------------------------------------------------
// Full Adder Module - Logic is correct
// -----------------------------------------------------------------
module full_adder(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    // Sum = a XOR b XOR cin
    assign sum = a ^ b ^ cin;
    
    // Carry out = (a AND b) OR (b AND cin) OR (a AND cin)
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule

// -----------------------------------------------------------------
// 4-bit Ripple Carry Adder - Structure is correct
// -----------------------------------------------------------------
module ripple_carry_adder_4bit(
    input [3:0] a,       // 4-bit input A
    input [3:0] b,       // 4-bit input B
    input cin,           // Carry input
    output [3:0] sum,    // 4-bit sum output
    output cout          // Carry output
);

    // Internal carry wires connecting the full adders
    wire c1, c2, c3;
    
    // Bit 0 (LSB) - Full Adder 0
    full_adder FA0 (
        .a(a[0]),
        .b(b[0]),
        .cin(cin),
        .sum(sum[0]),
        .cout(c1)
    );
    
    // Bit 1 - Full Adder 1
    full_adder FA1 (
        .a(a[1]),
        .b(b[1]),
        .cin(c1),
        .sum(sum[1]),
        .cout(c2)
    );
    
    // Bit 2 - Full Adder 2
    full_adder FA2 (
        .a(a[2]),
        .b(b[2]),
        .cin(c2),
        .sum(sum[2]),
        .cout(c3)
    );
    
    // Bit 3 (MSB) - Full Adder 3
    full_adder FA3 (
        .a(a[3]),
        .b(b[3]),
        .cin(c3),
        .sum(sum[3]),
        .cout(cout)
    );
    
endmodule