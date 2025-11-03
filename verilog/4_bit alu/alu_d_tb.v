`timescale 1ns / 1ps

module alu4_tb;
    reg [3:0] A, B;
    reg [2:0] ALU_Sel;
    wire [3:0] ALU_Out;
    wire Carry_Out;

    alu4 uut (.A(A), .B(B), .ALU_Sel(ALU_Sel), .ALU_Out(ALU_Out), .Carry_Out(Carry_Out));

    initial begin
        $monitor("A=%b B=%b Sel=%b -> Out=%b Carry=%b", A, B, ALU_Sel, ALU_Out, Carry_Out);
        
        A = 4'b0101; B = 4'b0011;

        ALU_Sel = 3'b000; #10; // Add
        ALU_Sel = 3'b001; #10; // Sub
        ALU_Sel = 3'b010; #10; // AND
        ALU_Sel = 3'b011; #10; // OR
        ALU_Sel = 3'b100; #10; // XOR
        ALU_Sel = 3'b101; #10; // Shift Left
        ALU_Sel = 3'b110; #10; // Shift Right
        ALU_Sel = 3'b111; #10; // Compare
        $finish;
    end
endmodule

