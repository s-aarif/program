`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2025 09:20:00
// Design Name: 
// Module Name: mag_comp_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for 4-bit Magnitude Comparator
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module mag_comp_tb;
    reg [3:0] A;
    reg [3:0] B;
    
    wire A_gt_b;
    wire A_lt_b;
    wire A_eq_b;
    
    integer i, j;
    
    mag_comp uut (
        .A(A), 
        .B(B), 
        .A_gt_b(A_gt_b), 
        .A_lt_b(A_lt_b), 
        .A_eq_b(A_eq_b)
    );
    
    initial begin
        A = 4'b0000;
        B = 4'b0000;
        
        #10;
        
        $display("\n========== Test 1: A = B (Equal) ==========");
        A = 4'b0000; B = 4'b0000; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        A = 4'b0101; B = 4'b0101; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        A = 4'b1111; B = 4'b1111; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        // Test 2: A > B (Greater than cases)
        $display("\n========== Test 2: A > B (Greater) ==========");
        A = 4'b0010; B = 4'b0001; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        A = 4'b1000; B = 4'b0100; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        A = 4'b1111; B = 4'b0000; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        A = 4'b1010; B = 4'b0101; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        // Test 3: A < B (Less than cases)
        $display("\n========== Test 3: A < B (Less Than) ==========");
        A = 4'b0001; B = 4'b0010; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        A = 4'b0100; B = 4'b1000; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        A = 4'b0000; B = 4'b1111; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        A = 4'b0101; B = 4'b1010; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        // Test 4: Edge cases
        $display("\n========== Test 4: Edge Cases ==========");
        A = 4'b0000; B = 4'b0001; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        A = 4'b1110; B = 4'b1111; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        // Test 5: Random test cases
        $display("\n========== Test 5: Random Cases ==========");
        A = 4'b0011; B = 4'b0111; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        A = 4'b1100; B = 4'b0011; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        A = 4'b0110; B = 4'b0110; #10;
        $display("A=%b(%0d), B=%b(%0d) | A>B=%b, A<B=%b, A=B=%b", A, A, B, B, A_gt_b, A_lt_b, A_eq_b);
        
        #50;
        $finish;
    end
      
endmodule