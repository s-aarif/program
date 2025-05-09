module tb_D_FF;
    reg D;
    reg clk;
    reg rst;
    wire Q;

    // Instantiate the D Flip-Flop
    D_FF uut (
        .D(D),
        .clk(clk),
        .rst(rst),
        .Q(Q)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        D = 0;
        #10 rst = 0;  // Deassert reset

        // Apply test vectors
        #10 D = 1;
        #10 D = 0;
        #10 D = 1;
        #10 rst = 1;  // Assert reset
        #10 rst = 0;
        #10 D = 1;
        #10 D = 0;

        // Finish simulation
        #20 $finish;
    end

    // Dump waveform data
    initial begin
        $dumpfile("D_FF_tb.vcd");
        $dumpvars(0, tb_D_FF);
    end

endmodule
