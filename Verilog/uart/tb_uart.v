`timescale 1ns/1ps

module uart_tb;

    // Parameters
    parameter CLK_FREQ = 50000000;
    parameter BAUD_RATE = 115200;
    parameter DATA_BITS = 8;
    parameter STOP_BITS = 1;
    parameter CLK_PERIOD = 20; // 50MHz clock = 20ns period
    
    // Testbench signals
    reg clk;
    reg rst;
    
    // TX interface
    reg [DATA_BITS-1:0] tx_data;
    reg tx_start;
    wire tx_busy;
    wire tx;
    
    // RX interface
    wire [DATA_BITS-1:0] rx_data;
    wire rx_ready;
    reg rx_ack;
    
    // Test variables
    reg [DATA_BITS-1:0] test_data [0:255];
    reg [DATA_BITS-1:0] received_data [0:255];
    integer tx_count;
    integer rx_count;
    integer error_count;
    integer i;
    
    // Instantiate UART modules
    // UART 1 - Transmitter
    uart #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(DATA_BITS),
        .STOP_BITS(STOP_BITS)
    ) uart_tx (
        .clk(clk),
        .rst(rst),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy),
        .tx(tx),
        .rx_data(),
        .rx_ready(),
        .rx_ack(1'b0),
        .rx(1'b1)
    );
    
    // UART 2 - Receiver (connected to transmitter)
    uart #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_BITS(DATA_BITS),
        .STOP_BITS(STOP_BITS)
    ) uart_rx (
        .clk(clk),
        .rst(rst),
        .tx_data(8'h00),
        .tx_start(1'b0),
        .tx_busy(),
        .tx(),
        .rx_data(rx_data),
        .rx_ready(rx_ready),
        .rx_ack(rx_ack),
        .rx(tx)  // Connect TX to RX
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Main test sequence
    initial begin
        // Initialize signals
        rst = 1;
        tx_data = 0;
        tx_start = 0;
        rx_ack = 0;
        tx_count = 0;
        rx_count = 0;
        error_count = 0;
        
        // Initialize arrays
        for (i = 0; i < 256; i = i + 1) begin
            test_data[i] = 0;
            received_data[i] = 0;
        end
        
        // Create waveform dump
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);
        
        // Reset pulse
        #(CLK_PERIOD*10);
        rst = 0;
        #(CLK_PERIOD*10);
        
        $display("========================================");
        $display("Starting UART Testbench");
        $display("Clock Frequency: %0d Hz", CLK_FREQ);
        $display("Baud Rate: %0d", BAUD_RATE);
        $display("Data Bits: %0d", DATA_BITS);
        $display("Stop Bits: %0d", STOP_BITS);
        $display("========================================\n");
        
        // Test 1: Single byte transmission
        $display("Test 1: Single byte transmission");
        send_byte(8'hA5);
        #(CLK_PERIOD*5000);
        
        // Test 2: Multiple sequential bytes
        $display("\nTest 2: Sequential byte transmission");
        send_byte(8'h12);
        #(CLK_PERIOD*5000);
        send_byte(8'h34);
        #(CLK_PERIOD*5000);
        send_byte(8'h56);
        #(CLK_PERIOD*5000);
        send_byte(8'h78);
        #(CLK_PERIOD*5000);
        
        // Test 3: All zeros
        $display("\nTest 3: All zeros");
        send_byte(8'h00);
        #(CLK_PERIOD*5000);
        
        // Test 4: All ones
        $display("\nTest 4: All ones");
        send_byte(8'hFF);
        #(CLK_PERIOD*5000);
        
        // Test 5: Alternating pattern
        $display("\nTest 5: Alternating patterns");
        send_byte(8'hAA);
        #(CLK_PERIOD*5000);
        send_byte(8'h55);
        #(CLK_PERIOD*5000);
        
        // Test 6: Back-to-back transmission
        $display("\nTest 6: Back-to-back transmission");
        for (i = 0; i < 16; i = i + 1) begin
            send_byte(i[7:0]);
            #(CLK_PERIOD*5000);
        end
        
        // Test 7: Pattern test
        $display("\nTest 7: Pattern test");
        send_byte(8'hC3);
        #(CLK_PERIOD*5000);
        send_byte(8'h3C);
        #(CLK_PERIOD*5000);
        send_byte(8'hF0);
        #(CLK_PERIOD*5000);
        send_byte(8'h0F);
        #(CLK_PERIOD*5000);
        
        // Wait for final transmissions
        #(CLK_PERIOD*10000);
        
        check_results();
        
        print_results();
        
        $finish;
    end
    
    // Monitor received data
    always @(posedge clk) begin
        if (rx_ready && !rx_ack) begin
            received_data[rx_count] = rx_data;
            $display("[%0t] Received byte %0d: 0x%02h", $time, rx_count, rx_data);
            rx_count = rx_count + 1;
            rx_ack = 1'b1;
        end else begin
            rx_ack = 1'b0;
        end
    end
    
    // Task to send a byte
    task send_byte;
        input [DATA_BITS-1:0] data;
        begin
            // Store test data
            test_data[tx_count] = data;
            
            // Wait for TX to be ready
            wait(!tx_busy);
            
            @(posedge clk);
            tx_data = data;
            tx_start = 1'b1;
            $display("[%0t] Sending byte %0d: 0x%02h", $time, tx_count, data);
            
            @(posedge clk);
            tx_start = 1'b0;
            
            tx_count = tx_count + 1;
        end
    endtask
    
    // Task to check results
    task check_results;
        integer j;
        begin
            $display("\n========================================");
            $display("Checking Results...");
            $display("========================================");
            
            if (tx_count != rx_count) begin
                $display("ERROR: Mismatch in count!");
                $display("Transmitted: %0d, Received: %0d", tx_count, rx_count);
                error_count = error_count + (tx_count - rx_count);
            end else begin
                $display("Count match: %0d bytes", tx_count);
            end
            
            for (j = 0; j < tx_count; j = j + 1) begin
                if (test_data[j] !== received_data[j]) begin
                    $display("ERROR at index %0d: Expected 0x%02h, Got 0x%02h", 
                             j, test_data[j], received_data[j]);
                    error_count = error_count + 1;
                end else begin
                    $display("PASS at index %0d: 0x%02h", j, test_data[j]);
                end
            end
        end
    endtask
    
    // Task to print test results
    task print_results;
        begin
            $display("\n========================================");
            $display("Test Results Summary");
            $display("========================================");
            $display("Total bytes transmitted: %0d", tx_count);
            $display("Total bytes received: %0d", rx_count);
            $display("Errors detected: %0d", error_count);
            
            if (error_count == 0 && tx_count == rx_count) begin
                $display("\n*** ALL TESTS PASSED ***");
            end else begin
                $display("\n*** TESTS FAILED: %0d errors ***", error_count);
            end
            $display("========================================\n");
        end
    endtask
    
    // Timeout watchdog
    initial begin
        #50000000; // 50ms timeout
        $display("\n*** ERROR: Simulation timeout! ***");
        $finish;
    end
    
    // Monitor TX line for debugging
    always @(tx) begin
        $display("[%0t] TX line changed to: %b", $time, tx);
    end

endmodule