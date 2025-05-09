module uart_tx (
    input wire clk,            // system clock
    input wire rst,            // active-high reset
    input wire tx_start,       // signal to start transmission
    input wire [7:0] tx_data,  // 8-bit data to transmit
    output reg tx,             // UART transmit line
    output reg tx_busy         // high when transmitting
);

    parameter CLK_PER_BIT = 10416; // e.g., for 9600 baud at 100MHz clk

    reg [13:0] clk_cnt = 0;
    reg [3:0] bit_index = 0;
    reg [9:0] tx_shift_reg = 10'b1111111111; // 1 start + 8 data + 1 stop

    reg sending = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx <= 1'b1; // idle state
            clk_cnt <= 0;
            bit_index <= 0;
            sending <= 0;
            tx_busy <= 0;
        end else begin
            if (tx_start && !sending) begin
                // load data into shift register
                tx_shift_reg <= {1'b1, tx_data, 1'b0}; // stop, data, start
                sending <= 1;
                tx_busy <= 1;
                clk_cnt <= 0;
                bit_index <= 0;
            end else if (sending) begin
                if (clk_cnt < CLK_PER_BIT - 1) begin
                    clk_cnt <= clk_cnt + 1;
                end else begin
                    clk_cnt <= 0;
                    tx <= tx_shift_reg[bit_index];
                    bit_index <= bit_index + 1;

                    if (bit_index == 9) begin
                        sending <= 0;
                        tx_busy <= 0;
                        tx <= 1'b1; // idle state
                    end
                end
            end
        end
    end
endmodule
