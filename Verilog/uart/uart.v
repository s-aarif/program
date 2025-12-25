module uart #(
    parameter CLK_FREQ = 50000000,  // System clock frequency in Hz
    parameter BAUD_RATE = 9600,     // Baud rate
    parameter DATA_BITS = 8,        // Number of data bits (5-9)
    parameter STOP_BITS = 1         // Number of stop bits (1 or 2)
)(
    input wire clk,
    input wire rst,
    
    // Transmitter interface
    input wire [DATA_BITS-1:0] tx_data,
    input wire tx_start,
    output reg tx_busy,
    output reg tx,
    
    // Receiver interface
    output reg [DATA_BITS-1:0] rx_data,
    output reg rx_ready,
    input wire rx_ack,
    input wire rx
);

    // Calculate clock divider for baud rate
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    
    // Transmitter states
    localparam TX_IDLE  = 3'd0;
    localparam TX_START = 3'd1;
    localparam TX_DATA  = 3'd2;
    localparam TX_STOP  = 3'd3;
    
    // Receiver states
    localparam RX_IDLE  = 3'd0;
    localparam RX_START = 3'd1;
    localparam RX_DATA  = 3'd2;
    localparam RX_STOP  = 3'd3;
    
    // Transmitter registers
    reg [2:0] tx_state;
    reg [$clog2(CLKS_PER_BIT)-1:0] tx_clk_count;
    reg [$clog2(DATA_BITS)-1:0] tx_bit_count;
    reg [DATA_BITS-1:0] tx_shift_reg;
    
    // Receiver registers
    reg [2:0] rx_state;
    reg [$clog2(CLKS_PER_BIT)-1:0] rx_clk_count;
    reg [$clog2(DATA_BITS)-1:0] rx_bit_count;
    reg [DATA_BITS-1:0] rx_shift_reg;
    reg rx_sync1, rx_sync2;  // For metastability
    
    // UART Transmitter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_state <= TX_IDLE;
            tx <= 1'b1;
            tx_busy <= 1'b0;
            tx_clk_count <= 0;
            tx_bit_count <= 0;
            tx_shift_reg <= 0;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    tx <= 1'b1;
                    tx_busy <= 1'b0;
                    tx_clk_count <= 0;
                    tx_bit_count <= 0;
                    
                    if (tx_start) begin
                        tx_shift_reg <= tx_data;
                        tx_state <= TX_START;
                        tx_busy <= 1'b1;
                    end
                end
                
                TX_START: begin
                    tx <= 1'b0;  // Start bit
                    
                    if (tx_clk_count < CLKS_PER_BIT - 1) begin
                        tx_clk_count <= tx_clk_count + 1;
                    end else begin
                        tx_clk_count <= 0;
                        tx_state <= TX_DATA;
                    end
                end
                
                TX_DATA: begin
                    tx <= tx_shift_reg[0];
                    
                    if (tx_clk_count < CLKS_PER_BIT - 1) begin
                        tx_clk_count <= tx_clk_count + 1;
                    end else begin
                        tx_clk_count <= 0;
                        tx_shift_reg <= tx_shift_reg >> 1;
                        
                        if (tx_bit_count < DATA_BITS - 1) begin
                            tx_bit_count <= tx_bit_count + 1;
                        end else begin
                            tx_bit_count <= 0;
                            tx_state <= TX_STOP;
                        end
                    end
                end
                
                TX_STOP: begin
                    tx <= 1'b1;  // Stop bit
                    
                    if (tx_clk_count < CLKS_PER_BIT * STOP_BITS - 1) begin
                        tx_clk_count <= tx_clk_count + 1;
                    end else begin
                        tx_clk_count <= 0;
                        tx_state <= TX_IDLE;
                    end
                end
                
                default: tx_state <= TX_IDLE;
            endcase
        end
    end
    
    // UART Receiver
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_state <= RX_IDLE;
            rx_data <= 0;
            rx_ready <= 1'b0;
            rx_clk_count <= 0;
            rx_bit_count <= 0;
            rx_shift_reg <= 0;
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            // Synchronize rx input to avoid metastability
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
            
            case (rx_state)
                RX_IDLE: begin
                    rx_clk_count <= 0;
                    rx_bit_count <= 0;
                    
                    if (rx_ack) begin
                        rx_ready <= 1'b0;
                    end
                    
                    // Detect start bit (falling edge)
                    if (rx_sync2 == 1'b0) begin
                        rx_state <= RX_START;
                    end
                end
                
                RX_START: begin
                    // Sample in the middle of the bit
                    if (rx_clk_count < (CLKS_PER_BIT / 2) - 1) begin
                        rx_clk_count <= rx_clk_count + 1;
                    end else begin
                        if (rx_sync2 == 1'b0) begin
                            rx_clk_count <= 0;
                            rx_state <= RX_DATA;
                        end else begin
                            rx_state <= RX_IDLE;  // False start bit
                        end
                    end
                end
                
                RX_DATA: begin
                    if (rx_clk_count < CLKS_PER_BIT - 1) begin
                        rx_clk_count <= rx_clk_count + 1;
                    end else begin
                        rx_clk_count <= 0;
                        rx_shift_reg[rx_bit_count] <= rx_sync2;
                        
                        if (rx_bit_count < DATA_BITS - 1) begin
                            rx_bit_count <= rx_bit_count + 1;
                        end else begin
                            rx_bit_count <= 0;
                            rx_state <= RX_STOP;
                        end
                    end
                end
                
                RX_STOP: begin
                    if (rx_clk_count < CLKS_PER_BIT - 1) begin
                        rx_clk_count <= rx_clk_count + 1;
                    end else begin
                        rx_clk_count <= 0;
                        rx_data <= rx_shift_reg;
                        rx_ready <= 1'b1;
                        rx_state <= RX_IDLE;
                    end
                end
                
                default: rx_state <= RX_IDLE;
            endcase
        end
    end

endmodule