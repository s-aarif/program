`timescale 1ns / 1ps

module tb_decoder3to8;

    reg [2:0] a;
    wire [7:0] y;

    // Instantiate the decoder
    decoder3to8 uut (
        .a(a),
        .y(y)
    );

    initial begin
        // Create dump file for GTKWave
        $dumpfile("decoder3to8.vcd");
        $dumpvars(0, tb_decoder3to8);

        // Apply all input combinations
        a = 3'b000; #10;
        a = 3'b001; #10;
        a = 3'b010; #10;
        a = 3'b011; #10;
        a = 3'b100; #10;
        a = 3'b101; #10;
        a = 3'b110; #10;
        a = 3'b111; #10;

        $finish;
    end

endmodule

