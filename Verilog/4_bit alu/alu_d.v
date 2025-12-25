`timescale 1 ns/1 ps
module alu4 (
    input  [3:0] A,       
    input  [3:0] B,       
    input  [2:0] ALU_Sel, 
    output reg [3:0] ALU_Out, 
    output reg Carry_Out      
);

    reg [4:0] temp;

    always @(*) begin
        case (ALU_Sel)
            3'b000: begin // ADD
                temp = A + B;
                ALU_Out = temp[3:0];
                Carry_Out = temp[4];
            end

            3'b001: begin // SUBTRACT
                temp = A - B;
                ALU_Out = temp[3:0];
                Carry_Out = temp[4];
            end

            3'b010: begin // AND
                ALU_Out = A & B;
                Carry_Out = 0;
            end

            3'b011: begin // OR
                ALU_Out = A | B;
                Carry_Out = 0;
            end

            3'b100: begin // XOR
                ALU_Out = A ^ B;
                Carry_Out = 0;
            end

            3'b101: begin // Logical left shift A by 1
                ALU_Out = A << 1;
                Carry_Out = A[3];
            end

            3'b110: begin // Logical right shift A by 1
                ALU_Out = A >> 1;
                Carry_Out = A[0];
            end

            3'b111: begin // Compare A == B
                ALU_Out = (A == B) ? 4'b0001 : 4'b0000;
                Carry_Out = 0;
            end

            default: begin
                ALU_Out = 4'b0000;
                Carry_Out = 0;
            end
        endcase
    end
endmodule
