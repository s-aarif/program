`timescale 1ns/1ps
//mentioning timescale for the set unit 

module gates_tb ;
    reg A;
    reg B;
    wire [3:0] Y;
    
    gate_final uut (
         .A(A), .B(B), .Y(Y)
    );
    
    //defininng uut in it all gates 
//    and_gate uut_and (.A(A), .B(B),.Y(Y[0]) );
//    or_gate uut_or (.A(A), .B(B),.Y(Y[1]) );
//    xor_gate uut_xor (.A(A), .B(B),.Y(Y[2]) );
//    not_gate uut_not (.A(A), .Y(Y[3]) );
    
 //Always before stimulus the vcd file should be dumped for t=0   
initial begin
    $dumpfile ("gates_tb_v.vcd");
    $dumpvars (0,gates_tb);
    $display ("Time | A | B | Y ");
    $monitor("%4d | d | d | d ", $time, A, B, Y );
end

initial begin
    A=1'b0; B=1'b0; #10;
    A=1'b0; B=1'b1; #10;
    A=1'b1; B=1'b0; #10;
    A=1'b1; B=1'b1; #10;
   
    $display ("The output was verified successfully");
    $finish;
    
end

endmodule
