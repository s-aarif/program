`timescale 1ns / 1ps

module uart_tx_tb;

    // Inputs
    reg clk;
    reg rst;
    reg tx_start;
    reg [7:0] tx_data;

    // Outputs
    wire tx;
    wire tx_busy;

    // Clock period (for 100 MHz -> 10 ns)
    localparam CLK_PERIOD = 10;

    // Instantiate the UART TX module
    uart_tx #(
        .CLK_PER_BIT(10416)  // for 9600 baud at 100 MHz clock
    ) uut (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Stimulus
    initial begin
        // Dumping VCD file for GTKWave
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);

        // Initialize
        rst = 1;
        tx_start = 0;
        tx_data = 8'h00;

        // Apply reset
        #(CLK_PERIOD * 10);
        rst = 0;

        // Wait for a few cycles
        #(CLK_PERIOD * 50);

        // Send first byte (example: 0x55)
        tx_data = 8'h55;
        tx_start = 1;
        #(CLK_PERIOD);        // pulse tx_start for 1 clock
        tx_start = 0;

        // Wait for transmission to complete
        wait (tx_busy == 0);

        // Send another byte (example: 0xA3)
        #(CLK_PERIOD * 50000); // wait between transmissions
        tx_data = 8'hA3;
        tx_start = 1;
        #(CLK_PERIOD);
        tx_start = 0;

        // Wait again for completion
        wait (tx_busy == 0);

        // Finish simulation
        #(CLK_PERIOD * 1000);
        $finish;
    end

endmodule
