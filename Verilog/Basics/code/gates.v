`timescale 1ns/1ps

//and gate
module and_gate (
    input A,B,
    output Y
);
assign Y = A & B;

endmodule

//or gate
module or_gate (
    input A,B,
    output Y
);
assign Y= A | B;
endmodule

//xor gate
module xor_gate (
    input A,B,
    output Y
);
assign Y= A ^ B;
endmodule

//not gate
module not_gate (
    input A,
    output Y
);
assign Y= ~A;
endmodule 