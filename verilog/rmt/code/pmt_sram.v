`timescale 1ns/1ps

module sram_pmt #(
    parameter DATA_WIDTH = 32,      // Width of data stored (Pw)
    parameter ADDR_WIDTH = 5,       // Address width (log2(DEPTH))
    parameter DEPTH = 32            // Number of entries (Pd)
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    // Write Interface (for entry installation)
    input  wire                      wr_en,
    input  wire [ADDR_WIDTH-1:0]     wr_addr,
    input  wire [DATA_WIDTH-1:0]     wr_data,
    
    // Read/Search Interface (for lookup)
    input  wire                      rd_en,
    input  wire [ADDR_WIDTH-1:0]     rd_addr,
    output reg  [DATA_WIDTH-1:0]     rd_data,
    output reg                       rd_valid,
    
    // Status
    output wire [DEPTH-1:0]          entry_valid  // Bitmap of valid entries
);

    // Memory array - using Block RAM
    reg [DATA_WIDTH-1:0] mem_array [0:DEPTH-1];
    
    // Valid bit array to track which entries are programmed
    reg [DEPTH-1:0] valid_bits;
    
    // Pipeline registers for read operation
    reg [DATA_WIDTH-1:0] rd_data_pipe;
    reg                  rd_valid_pipe;
    
    integer i;
    
    // ========================================================================
    // Write Operation
    // ========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_bits <= {DEPTH{1'b0}};
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem_array[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            if (wr_en) begin
                mem_array[wr_addr] <= wr_data;
                valid_bits[wr_addr] <= 1'b1;
            end
        end
    end
    
    // ========================================================================
    // Read Operation (Pipelined for timing)
    // ========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data_pipe  <= {DATA_WIDTH{1'b0}};
            rd_valid_pipe <= 1'b0;
        end else begin
            if (rd_en) begin
                rd_data_pipe  <= mem_array[rd_addr];
                rd_valid_pipe <= valid_bits[rd_addr];
            end else begin
                rd_data_pipe  <= {DATA_WIDTH{1'b0}};
                rd_valid_pipe <= 1'b0;
            end
        end
    end
    
    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data  <= {DATA_WIDTH{1'b0}};
            rd_valid <= 1'b0;
        end else begin
            rd_data  <= rd_data_pipe;
            rd_valid <= rd_valid_pipe;
        end
    end
    
    // Status output
    assign entry_valid = valid_bits;
    
    // ========================================================================
    // Synthesis Attributes for Block RAM inference
    // ========================================================================
    // synthesis attribute ram_style of mem_array is "block"
    // For Xilinx: (* ram_style = "block" *)

endmodule