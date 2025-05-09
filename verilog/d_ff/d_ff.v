module D_FF (
    input wire D,      // Data input
    input wire clk,    // Clock input
    input wire rst,    // Asynchronous reset
    output reg Q       // Output
);

    always @(posedge clk or posedge rst) begin
        if (rst) 
            Q <= 1'b0; // Reset Q to 0
        else 
            Q <= D;   // Assign D to Q on clock's rising edge
    end

endmodule

