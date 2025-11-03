`timescale 1ns/1ps

module mux_tb;

    reg [3:0] I;
    reg [1:0] S;
    wire Y;

    mux dut (
        .I(I),
        .S(S),
        .Y(Y)
    );

    initial begin
        $monitor("Time=%0t | S=%b, I=%b | Y=%b", $time, S, I, Y);

       
        I = 4'b1011; 
        S = 2'b00;
        #10;

        S = 2'b00; 
        #10;

        S = 2'b01;
        #10;

        S = 2'b10;
        #10;
        
        S = 2'b11;
        #10;

        I = 4'b0101;
        
        S = 2'b00;
        #10;

        S = 2'b01;
        #10;

        S = 2'b10;
        #10;
        
        S = 2'b11;
        #10;

        $finish;
    end

endmodule
