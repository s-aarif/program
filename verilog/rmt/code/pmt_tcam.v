`timescale 1 ns/1 ps
module tcam_pmt #(
    parameter DATA_WIDTH = 32,      // Width of search key (Pw)
    parameter ADDR_WIDTH = 5,       // Address width (log2(DEPTH))
    parameter DEPTH = 32            // Number of entries (Pd)
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    // Write Interface (for entry installation)
    input  wire                      wr_en,
    input  wire [ADDR_WIDTH-1:0]     wr_addr,
    input  wire [DATA_WIDTH-1:0]     wr_data,      // Data bits
    input  wire [DATA_WIDTH-1:0]     wr_mask,      // Mask bits (1=care, 0=don't care)
    
    // Search Interface (for lookup)
    input  wire                      search_en,
    input  wire [DATA_WIDTH-1:0]     search_key,
    output reg  [DEPTH-1:0]          matchlines,   // One-hot match result
    output reg                       match_found,
    output reg  [ADDR_WIDTH-1:0]     match_addr,   // Highest priority match address
    
    // Status
    output wire [DEPTH-1:0]          entry_valid   // Bitmap of valid entries
);

    // ========================================================================
    // TCAM Storage Arrays
    // ========================================================================
    // Data array: stores the pattern to match
    reg [DATA_WIDTH-1:0] tcam_data [0:DEPTH-1];
    
    // Mask array: 1 = care bit, 0 = don't care
    reg [DATA_WIDTH-1:0] tcam_mask [0:DEPTH-1];
    
    // Valid bit array
    reg [DEPTH-1:0] valid_bits;
    
    // Match computation wires
    wire [DEPTH-1:0] match_vector;
    
    integer i, j;
    
    // ========================================================================
    // Write Operation
    // ========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_bits <= {DEPTH{1'b0}};
            for (i = 0; i < DEPTH; i = i + 1) begin
                tcam_data[i] <= {DATA_WIDTH{1'b0}};
                tcam_mask[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            if (wr_en) begin
                tcam_data[wr_addr] <= wr_data;
                tcam_mask[wr_addr] <= wr_mask;
                valid_bits[wr_addr] <= 1'b1;
            end
        end
    end
    
    // ========================================================================
    // TCAM Match Logic
    // Each entry compares search_key against stored pattern with mask
    // Match occurs when: (search_key[i] == tcam_data[i]) OR (tcam_mask[i] == 0)
    // ========================================================================
    genvar k;
    generate
        for (k = 0; k < DEPTH; k = k + 1) begin : gen_match
            wire [DATA_WIDTH-1:0] xor_result;
            wire [DATA_WIDTH-1:0] masked_xor;
            wire entry_match;
            
            // XOR to find differences
            assign xor_result = search_key ^ tcam_data[k];
            
            // Apply mask (only care about bits where mask=1)
            assign masked_xor = xor_result & tcam_mask[k];
            
            // Match if all masked bits are zero and entry is valid
            assign entry_match = (masked_xor == {DATA_WIDTH{1'b0}}) && valid_bits[k];
            
            assign match_vector[k] = entry_match;
        end
    endgenerate
    
    // ========================================================================
    // Pipeline Stage 1: Compute matchlines
    // ========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            matchlines <= {DEPTH{1'b0}};
        end else begin
            if (search_en) begin
                matchlines <= match_vector;
            end else begin
                matchlines <= {DEPTH{1'b0}};
            end
        end
    end
    
    // ========================================================================
    // Pipeline Stage 2: Priority Encoder
    // Returns the lowest index (highest priority) matching entry
    // ========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_found <= 1'b0;
            match_addr  <= {ADDR_WIDTH{1'b0}};
        end else begin
            match_found <= |matchlines;  // OR reduction - any match?
            
            // Priority encoder - find first match (lowest index = highest priority)
            match_addr <= {ADDR_WIDTH{1'b0}};
            for (j = DEPTH-1; j >= 0; j = j - 1) begin
                if (matchlines[j]) begin
                    match_addr <= j[ADDR_WIDTH-1:0];
                end
            end
        end
    end
    
    // Status output
    assign entry_valid = valid_bits;

endmodule


// ============================================================================
// Alternative: Optimized Priority Encoder Module
// Can be used separately if needed for better timing
// ============================================================================

module priority_encoder #(
    parameter WIDTH = 32,
    parameter ADDR_WIDTH = 5
) (
    input  wire [WIDTH-1:0]      matchlines,
    output reg  [ADDR_WIDTH-1:0] match_addr,
    output wire                  match_found
);

    integer i;
    
    assign match_found = |matchlines;
    
    always @(*) begin
        match_addr = {ADDR_WIDTH{1'b0}};
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            if (matchlines[i]) begin
                match_addr = i[ADDR_WIDTH-1:0];
            end
        end
    end

endmodule