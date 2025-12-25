`timescale 1ns / 1ps
// ============================================================================
// PMT Wrapper - Unified interface for SRAM or TCAM PMT
// Allows runtime selection of match table type
// ============================================================================

module pmt_wrapper #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter DEPTH = 32,
    parameter PMT_TYPE = "SRAM"  // "SRAM" or "TCAM"
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    // Configuration
    input  wire                      pmt_used,      // Is this PMT allocated?
    input  wire [7:0]                pmt_lmt_id,    // Which LMT owns this PMT
    
    // Write Interface
    input  wire                      wr_en,
    input  wire [ADDR_WIDTH-1:0]     wr_addr,
    input  wire [DATA_WIDTH-1:0]     wr_data,
    input  wire [DATA_WIDTH-1:0]     wr_mask,       // Only for TCAM
    
    // Read Interface (SRAM only)
    input  wire                      rd_en,
    input  wire [ADDR_WIDTH-1:0]     rd_addr,
    output wire [DATA_WIDTH-1:0]     rd_data,
    output wire                      rd_valid,
    
    // Search Interface (TCAM only)
    input  wire                      search_en,
    input  wire [DATA_WIDTH-1:0]     search_key,
    output wire [DEPTH-1:0]          matchlines,
    output wire                      match_found,
    output wire [ADDR_WIDTH-1:0]     match_addr,
    
    // Status
    output wire [DEPTH-1:0]          entry_valid,
    output wire                      pmt_busy
);

    // ========================================================================
    // Generate SRAM or TCAM based on parameter
    // ========================================================================
    
    generate
        if (PMT_TYPE == "SRAM") begin : gen_sram
            
            sram_pmt #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .DEPTH(DEPTH)
            ) sram_inst (
                .clk(clk),
                .rst_n(rst_n),
                .wr_en(wr_en & pmt_used),
                .wr_addr(wr_addr),
                .wr_data(wr_data),
                .rd_en(rd_en & pmt_used),
                .rd_addr(rd_addr),
                .rd_data(rd_data),
                .rd_valid(rd_valid),
                .entry_valid(entry_valid)
            );
            
            // Unused TCAM outputs
            assign matchlines = {DEPTH{1'b0}};
            assign match_found = 1'b0;
            assign match_addr = {ADDR_WIDTH{1'b0}};
            
        end else if (PMT_TYPE == "TCAM") begin : gen_tcam
            
            tcam_pmt #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .DEPTH(DEPTH)
            ) tcam_inst (
                .clk(clk),
                .rst_n(rst_n),
                .wr_en(wr_en & pmt_used),
                .wr_addr(wr_addr),
                .wr_data(wr_data),
                .wr_mask(wr_mask),
                .search_en(search_en & pmt_used),
                .search_key(search_key),
                .matchlines(matchlines),
                .match_found(match_found),
                .match_addr(match_addr),
                .entry_valid(entry_valid)
            );
            
            // Unused SRAM outputs
            assign rd_data = {DATA_WIDTH{1'b0}};
            assign rd_valid = 1'b0;
            
        end
    endgenerate
    
    // Busy flag - could be extended for multi-cycle operations
    assign pmt_busy = 1'b0;

endmodule


// ============================================================================
// PMT Pool - Collection of PMTs
// Manages multiple PMT instances as a resource pool
// ============================================================================

module pmt_pool #(
    parameter NUM_PMTS = 32,        // Total number of PMTs (M)
    parameter DATA_WIDTH = 32,      // PMT width (Pw)
    parameter ADDR_WIDTH = 5,       // Address width
    parameter DEPTH = 32,           // PMT depth (Pd)
    parameter PMT_TYPE = "SRAM",    // "SRAM" or "TCAM"
    parameter PMT_ID_WIDTH = 6      // log2(NUM_PMTS) + 1
) (
    input  wire                          clk,
    input  wire                          rst_n,
    
    // Configuration per PMT
    input  wire [NUM_PMTS-1:0]           pmt_used,
    input  wire [NUM_PMTS*8-1:0]         pmt_lmt_id,  // 8-bit LMT ID per PMT
    
    // Write Interface (broadcasted to all PMTs, selected by ID)
    input  wire                          wr_en,
    input  wire [PMT_ID_WIDTH-1:0]       wr_pmt_id,
    input  wire [ADDR_WIDTH-1:0]         wr_addr,
    input  wire [DATA_WIDTH-1:0]         wr_data,
    input  wire [DATA_WIDTH-1:0]         wr_mask,
    
    // Read Interface Array (SRAM)
    input  wire [NUM_PMTS-1:0]           rd_en,
    input  wire [NUM_PMTS*ADDR_WIDTH-1:0] rd_addr,
    output wire [NUM_PMTS*DATA_WIDTH-1:0] rd_data,
    output wire [NUM_PMTS-1:0]           rd_valid,
    
    // Search Interface Array (TCAM)
    input  wire [NUM_PMTS-1:0]           search_en,
    input  wire [NUM_PMTS*DATA_WIDTH-1:0] search_key,
    output wire [NUM_PMTS*DEPTH-1:0]     matchlines,
    output wire [NUM_PMTS-1:0]           match_found,
    output wire [NUM_PMTS*ADDR_WIDTH-1:0] match_addr,
    
    // Status
    output wire [NUM_PMTS*DEPTH-1:0]     entry_valid
);

    genvar i;
    
    generate
        for (i = 0; i < NUM_PMTS; i = i + 1) begin : gen_pmts
            
            wire wr_en_this_pmt;
            assign wr_en_this_pmt = wr_en && (wr_pmt_id == i);
            
            pmt_wrapper #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .DEPTH(DEPTH),
                .PMT_TYPE(PMT_TYPE)
            ) pmt_inst (
                .clk(clk),
                .rst_n(rst_n),
                .pmt_used(pmt_used[i]),
                .pmt_lmt_id(pmt_lmt_id[i*8 +: 8]),
                
                // Write
                .wr_en(wr_en_this_pmt),
                .wr_addr(wr_addr),
                .wr_data(wr_data),
                .wr_mask(wr_mask),
                
                // Read (SRAM)
                .rd_en(rd_en[i]),
                .rd_addr(rd_addr[i*ADDR_WIDTH +: ADDR_WIDTH]),
                .rd_data(rd_data[i*DATA_WIDTH +: DATA_WIDTH]),
                .rd_valid(rd_valid[i]),
                
                // Search (TCAM)
                .search_en(search_en[i]),
                .search_key(search_key[i*DATA_WIDTH +: DATA_WIDTH]),
                .matchlines(matchlines[i*DEPTH +: DEPTH]),
                .match_found(match_found[i]),
                .match_addr(match_addr[i*ADDR_WIDTH +: ADDR_WIDTH]),
                
                // Status
                .entry_valid(entry_valid[i*DEPTH +: DEPTH]),
                .pmt_busy()
            );
        end
    endgenerate

endmodule
