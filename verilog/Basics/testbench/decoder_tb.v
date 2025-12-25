`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.10.2025 22:30:00
// Design Name: 
// Module Name: decoder_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for 3-to-8 Decoder
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module decoder_tb;
    // Inputs
    reg [2:0] S;        // 3-bit input for 3-to-8 decoder
    reg Enable;
    
    // Outputs
    wire [7:0] O;       // 8-bit output
    
    // Instantiate the Unit Under Test (UUT)
    decoder uut (
        .S(S), 
        .Enable(Enable), 
        .O(O)
    );
    
    // Test variables
    integer i;
    
    initial begin
        // Initialize Inputs
        S = 3'b000;
        Enable = 1'b0;
        
        // Wait for initialization
        #100;
        
        // Test 1: Enable = 0 (decoder disabled)
        // All outputs should be 0 regardless of input
        Enable = 1'b0;
        for (i = 0; i < 8; i = i + 1) begin
            S = i;
            #20;
        end
        
        #50;
        
        // Test 2: Enable = 1 (decoder enabled)
        // Test all 8 valid input combinations
        Enable = 1'b1;
        
        S = 3'b000; #20;  // Expected O = 00000001
        S = 3'b001; #20;  // Expected O = 00000010
        S = 3'b010; #20;  // Expected O = 00000100
        S = 3'b011; #20;  // Expected O = 00001000
        S = 3'b100; #20;  // Expected O = 00010000
        S = 3'b101; #20;  // Expected O = 00100000
        S = 3'b110; #20;  // Expected O = 01000000
        S = 3'b111; #20;  // Expected O = 10000000
        
        #50;
        
        // Test 3: Toggle Enable during operation
        S = 3'b010;
        Enable = 1'b1; #20;
        Enable = 1'b0; #20;
        Enable = 1'b1; #20;
        Enable = 1'b0; #20;
        
        #50;
        
        // Test 4: Random switching
        Enable = 1'b1;
        S = 3'b101; #20;
        S = 3'b010; #20;
        S = 3'b111; #20;
        S = 3'b000; #20;
        S = 3'b110; #20;
        S = 3'b011; #20;
        
        #100;
        
        $finish;
    end
      
endmodule