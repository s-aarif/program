`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.10.2025 22:16:01
// Design Name: 
// Module Name: async_counter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module async_counter(
    input clk,
    input rst_n,
    output reg [3:0] q
    );
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin   
            q[0] <= 1'b0;
    end else begin
        q[0] <= ~q[0];
    end
end

always @(posedge q[0] or negedge rst_n) begin
        if (rst_n == 1'b0) begin    
            q[1] <= 1'b0;
    end else begin
        q[1] <= ~q[1];
    end
end

always @(posedge q[1] or negedge rst_n) begin
        if (rst_n == 1'b0) begin    
            q[2] <= 1'b0;
    end else begin
        q[2] <= ~q[2];
    end
end     

always @(posedge q[2] or negedge rst_n) begin
        if (rst_n == 1'b0) begin    
            q[3] <= 1'b0;
    end else begin
        q[3] <= ~q[3];
    end
end  

//always @(posedge q[3] or negedge rst_n) begin
//        if (rst_n == 1'b0) begin    
//            q[2] <= 1'b0;
//    end else begin
//        q[2] <= ~q[2];
//    end
//end        
    
endmodule
