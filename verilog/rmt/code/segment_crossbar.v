`timescale 1ns / 1ps
// ============================================================================
// Segment Crossbar Implementation
// Based on: "An Implementation of Reconfigurable Match Table for 
//           FPGA-Based Programmable Switches"
// Implements the 5 multiplexer abstractions: PARTITION, SELECT, SPREAD,
// COMBINE, and MAND
// ============================================================================

// ============================================================================
// PMT Manager - Allocates PMTs to LMTs
// Implements Algorithm 2 from the paper (LMT to PMT mapping)
// ============================================================================

module pmt_manager #(
    parameter NUM_LMTS = 5,
    parameter NUM_PMTS = 32,
    parameter PMT_WIDTH = 32,           // Pw
    parameter PMT_DEPTH = 32,           // Pd
    parameter MAX_PMTS_PER_LMT = 8,     // P
    parameter PMT_ID_WIDTH = 6
) (
    input  wire                          clk,
    input  wire                          rst_n,
    
    // ========================================================================
    // ULSS Input (from UMT mapper)
    // ========================================================================
    input  wire                          alloc_trigger,
    input  wire [NUM_LMTS-1:0]           lmt_used,
    input  wire [NUM_LMTS*2-1:0]         lmt_width_gear,
    input  wire [NUM_LMTS*3-1:0]         lmt_depth_gear,
    
    // ========================================================================
    // LPSS Output (LMT to PMT State Structure)
    // ========================================================================
    output reg                           alloc_done,
    output reg                           alloc_error,
    output reg  [7:0]                    alloc_error_code,
    
    // Per-LMT allocation info
    output reg  [NUM_LMTS*8-1:0]         lmt_pmt_count,      // NPL - PMTs per LMT
    output reg  [NUM_LMTS*PMT_ID_WIDTH-1:0] lmt_aspid,       // Start PID in AS
    output reg  [NUM_LMTS*PMT_ID_WIDTH-1:0] lmt_aepid,       // End PID in AS
    output reg  [NUM_LMTS*PMT_ID_WIDTH-1:0] lmt_pspid,       // Start PID in PS
    output reg  [NUM_LMTS*PMT_ID_WIDTH-1:0] lmt_pepid,       // End PID in PS
    
    // Per-PMT allocation info
    output reg  [NUM_PMTS-1:0]           pmt_used,
    output reg  [NUM_PMTS*8-1:0]         pmt_lmt_id,         // PLID
    output reg  [NUM_PMTS*4-1:0]         pmt_width_idx,      // PWIdx
    output reg  [NUM_PMTS*4-1:0]         pmt_depth_idx,      // PDIdx
    
    // Status
    output reg  [7:0]                    total_pmts_used
);

    localparam ERR_NONE = 8'h00;
    localparam ERR_PMT_OVERFLOW = 8'h01;
    
    integer i, j, k;
    reg [PMT_ID_WIDTH-1:0] pmt_cursor;
    reg [7:0] pmt_needed;
    reg [7:0] width_blocks;
    reg [7:0] depth_blocks;
    reg [1:0] wg;
    reg [2:0] dg;
    
    // Segment crossbar PS calculation (from equations 2 & 3 in paper)
    function [PMT_ID_WIDTH-1:0] calc_pspid;
        input [3:0] lmt_id;
        begin
            if (lmt_id < 3)
                calc_pspid = (MAX_PMTS_PER_LMT / 2) * lmt_id;
            else
                calc_pspid = calc_pspid(lmt_id - 1) + MAX_PMTS_PER_LMT;
        end
    endfunction
    
    function [PMT_ID_WIDTH-1:0] calc_pepid;
        input [3:0] lmt_id;
        begin
            if (lmt_id >= (NUM_LMTS - 3))
                calc_pepid = NUM_PMTS - (MAX_PMTS_PER_LMT / 2) * (NUM_LMTS - 1 - lmt_id);
            else
                calc_pepid = MAX_PMTS_PER_LMT * (lmt_id + 1);
        end
    endfunction
    
    // Calculate number of PMTs needed for LMT (equation 4 in paper)
    function [7:0] calc_npl;
        input [1:0] width_gear;
        input [2:0] depth_gear;
        begin
            // Width blocks: 2^width_gear
            // Depth blocks: 2^depth_gear
            calc_npl = (1 << width_gear) * (1 << depth_gear);
        end
    endfunction
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alloc_done <= 1'b0;
            alloc_error <= 1'b0;
            alloc_error_code <= ERR_NONE;
            pmt_used <= {NUM_PMTS{1'b0}};
            total_pmts_used <= 8'd0;
            
            for (i = 0; i < NUM_LMTS; i = i + 1) begin
                lmt_pmt_count[i*8 +: 8] <= 8'd0;
                lmt_aspid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH] <= {PMT_ID_WIDTH{1'b0}};
                lmt_aepid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH] <= {PMT_ID_WIDTH{1'b0}};
                lmt_pspid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH] <= {PMT_ID_WIDTH{1'b0}};
                lmt_pepid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH] <= {PMT_ID_WIDTH{1'b0}};
            end
            
            for (i = 0; i < NUM_PMTS; i = i + 1) begin
                pmt_lmt_id[i*8 +: 8] <= 8'd0;
                pmt_width_idx[i*4 +: 4] <= 4'd0;
                pmt_depth_idx[i*4 +: 4] <= 4'd0;
            end
            
        end else if (alloc_trigger && !alloc_done) begin
            
            // Reset PMT allocation
            pmt_used <= {NUM_PMTS{1'b0}};
            pmt_cursor = 0;
            alloc_error <= 1'b0;
            
            // Allocate PMTs to each LMT
            for (i = 0; i < NUM_LMTS; i = i + 1) begin
                if (lmt_used[i]) begin
                    // Get configuration for this LMT
                    wg = lmt_width_gear[i*2 +: 2];
                    dg = lmt_depth_gear[i*3 +: 3];
                    
                    // Calculate PMTs needed
                    pmt_needed = calc_npl(wg, dg);
                    width_blocks = (1 << wg);
                    depth_blocks = (1 << dg);
                    
                    // Calculate PS range (equations 2 & 3)
                    lmt_pspid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH] <= calc_pspid(i[3:0]);
                    lmt_pepid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH] <= calc_pepid(i[3:0]);
                    
                    // Calculate AS range (equations 5 & 6)
                    if (i == 0) begin
                        lmt_aspid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH] <= {PMT_ID_WIDTH{1'b0}};
                    end else begin
                        // ASPID = max(previous AEPID, this PSPID)
                        if (lmt_aepid[(i-1)*PMT_ID_WIDTH +: PMT_ID_WIDTH] > calc_pspid(i[3:0]))
                            lmt_aspid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH] <= 
                                lmt_aepid[(i-1)*PMT_ID_WIDTH +: PMT_ID_WIDTH];
                        else
                            lmt_aspid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH] <= calc_pspid(i[3:0]);
                    end
                    
                    // AEPID = min(ASPID + NPL, PEPID)
                    if ((lmt_aspid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH] + pmt_needed) < calc_pepid(i[3:0]))
                        lmt_aepid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH] <= 
                            lmt_aspid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH] + pmt_needed;
                    else
                        lmt_aepid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH] <= calc_pepid(i[3:0]);
                    
                    lmt_pmt_count[i*8 +: 8] <= pmt_needed;
                    
                    // Allocate PMTs and set their indices
                    pmt_cursor = lmt_aspid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH];
                    
                    for (j = 0; j < pmt_needed && pmt_cursor < NUM_PMTS; j = j + 1) begin
                        pmt_used[pmt_cursor] <= 1'b1;
                        pmt_lmt_id[pmt_cursor*8 +: 8] <= i[7:0];
                        
                        // Calculate 2D indices for width/depth cascade
                        pmt_width_idx[pmt_cursor*4 +: 4] <= (j % width_blocks);
                        pmt_depth_idx[pmt_cursor*4 +: 4] <= (j / width_blocks);
                        
                        pmt_cursor = pmt_cursor + 1;
                    end
                    
                    if (pmt_cursor >= NUM_PMTS && j < pmt_needed) begin
                        alloc_error <= 1'b1;
                        alloc_error_code <= ERR_PMT_OVERFLOW;
                    end
                end
            end
            
            total_pmts_used <= pmt_cursor;
            alloc_done <= 1'b1;
            
        end else if (!alloc_trigger) begin
            alloc_done <= 1'b0;
        end
    end

endmodule


// ============================================================================
// LMT to PMT Crossbar (Single LMT)
// Implements multiplexer abstractions: PARTITION, SELECT, SPREAD, COMBINE, MAND
// ============================================================================

module lmt_pmt_crossbar #(
    parameter LMT_MAX_WIDTH = 64,
    parameter LMT_MAX_DEPTH = 256,
    parameter LMT_ADDR_WIDTH = 8,
    parameter PMT_WIDTH = 32,
    parameter PMT_DEPTH = 32,
    parameter PMT_ADDR_WIDTH = 5,
    parameter MAX_PMTS = 8,
    parameter PMT_ID_WIDTH = 6,
    parameter MATCH_TYPE = "TCAM"       // "TCAM" or "SRAM"
) (
    input  wire                          clk,
    input  wire                          rst_n,
    
    // ========================================================================
    // Configuration
    // ========================================================================
    input  wire [7:0]                    num_pmts,           // NPL
    input  wire [PMT_ID_WIDTH-1:0]       aspid,              // Start PID
    input  wire [PMT_ID_WIDTH-1:0]       aepid,              // End PID
    input  wire [1:0]                    width_gear,         // 0=1x, 1=2x
    input  wire [2:0]                    depth_gear,         // 0=1x, 1=2x, 2=4x, 3=8x
    
    // ========================================================================
    // LMT Side Interface
    // ========================================================================
    // Write
    input  wire                          lmt_wr_en,
    input  wire [LMT_ADDR_WIDTH-1:0]     lmt_wr_addr,
    input  wire [LMT_MAX_WIDTH-1:0]      lmt_wr_data,
    input  wire [LMT_MAX_WIDTH-1:0]      lmt_wr_mask,
    
    // Read (SRAM)
    input  wire                          lmt_rd_en,
    input  wire [LMT_ADDR_WIDTH-1:0]     lmt_rd_addr,
    output reg  [LMT_MAX_WIDTH-1:0]      lmt_rd_data,
    output reg                           lmt_rd_valid,
    
    // Search (TCAM)
    input  wire                          lmt_search_en,
    input  wire [LMT_MAX_WIDTH-1:0]      lmt_search_key,
    output reg  [LMT_MAX_DEPTH-1:0]      lmt_matchlines,
    output reg                           lmt_match_found,
    output reg  [LMT_ADDR_WIDTH-1:0]     lmt_match_addr,
    
    // ========================================================================
    // PMT Side Interface (to PMT Pool)
    // ========================================================================
    // Write
    output reg  [MAX_PMTS-1:0]           pmt_wr_en,
    output reg  [MAX_PMTS*PMT_ADDR_WIDTH-1:0] pmt_wr_addr,
    output reg  [MAX_PMTS*PMT_WIDTH-1:0] pmt_wr_data,
    output reg  [MAX_PMTS*PMT_WIDTH-1:0] pmt_wr_mask,
    
    // Read (SRAM)
    output reg  [MAX_PMTS-1:0]           pmt_rd_en,
    output reg  [MAX_PMTS*PMT_ADDR_WIDTH-1:0] pmt_rd_addr,
    input  wire [MAX_PMTS*PMT_WIDTH-1:0] pmt_rd_data,
    input  wire [MAX_PMTS-1:0]           pmt_rd_valid,
    
    // Search (TCAM)
    output reg  [MAX_PMTS-1:0]           pmt_search_en,
    output reg  [MAX_PMTS*PMT_WIDTH-1:0] pmt_search_key,
    input  wire [MAX_PMTS*PMT_DEPTH-1:0] pmt_matchlines,
    input  wire [MAX_PMTS-1:0]           pmt_match_found,
    input  wire [MAX_PMTS*PMT_ADDR_WIDTH-1:0] pmt_match_addr
);

    integer i, j, k;
    
    // Width and depth configuration
    wire [7:0] width_blocks;
    wire [7:0] depth_blocks;
    wire [7:0] lmt_actual_width;
    wire [15:0] lmt_actual_depth;
    
    assign width_blocks = (1 << width_gear);
    assign depth_blocks = (1 << depth_gear);
    assign lmt_actual_width = PMT_WIDTH * width_blocks;
    assign lmt_actual_depth = PMT_DEPTH * depth_blocks;
    
    // ========================================================================
    // WRITE PATH: LMT → PMT
    // Implements: PARTITION, SELECT, SPREAD
    // ========================================================================
    
    reg [PMT_ADDR_WIDTH-1:0] pmt_addr_base;
    reg [3:0] pmt_depth_idx;
    reg [3:0] pmt_width_idx;
    
    always @(*) begin
        // Default values
        pmt_wr_en = {MAX_PMTS{1'b0}};
        pmt_wr_addr = {MAX_PMTS*PMT_ADDR_WIDTH{1'b0}};
        pmt_wr_data = {MAX_PMTS*PMT_WIDTH{1'b0}};
        pmt_wr_mask = {MAX_PMTS*PMT_WIDTH{1'b0}};
        
        if (lmt_wr_en) begin
            // SELECT: Determine which depth block (row of PMTs)
            pmt_depth_idx = lmt_wr_addr[LMT_ADDR_WIDTH-1:PMT_ADDR_WIDTH];
            pmt_addr_base = lmt_wr_addr[PMT_ADDR_WIDTH-1:0];
            
            // PARTITION & SPREAD: Write to PMTs
            for (i = 0; i < MAX_PMTS; i = i + 1) begin
                if (i < num_pmts) begin
                    pmt_width_idx = i % width_blocks;
                    
                    // Check if this PMT is in the correct depth block
                    if ((i / width_blocks) == pmt_depth_idx) begin
                        // SPREAD: Enable write for this PMT
                        pmt_wr_en[i] = 1'b1;
                        pmt_wr_addr[i*PMT_ADDR_WIDTH +: PMT_ADDR_WIDTH] = pmt_addr_base;
                        
                        // PARTITION: Extract correct segment of data/mask
                        pmt_wr_data[i*PMT_WIDTH +: PMT_WIDTH] = 
                            lmt_wr_data[pmt_width_idx*PMT_WIDTH +: PMT_WIDTH];
                        pmt_wr_mask[i*PMT_WIDTH +: PMT_WIDTH] = 
                            lmt_wr_mask[pmt_width_idx*PMT_WIDTH +: PMT_WIDTH];
                    end
                end
            end
        end
    end
    
    // ========================================================================
    // READ PATH (SRAM): PMT → LMT
    // Implements: SELECT, COMBINE
    // ========================================================================
    
    reg [LMT_MAX_WIDTH-1:0] combined_rd_data;
    reg combined_rd_valid;
    
    always @(*) begin
        // Default values
        pmt_rd_en = {MAX_PMTS{1'b0}};
        pmt_rd_addr = {MAX_PMTS*PMT_ADDR_WIDTH{1'b0}};
        
        if (lmt_rd_en) begin
            // SELECT: Determine which depth block
            pmt_depth_idx = lmt_rd_addr[LMT_ADDR_WIDTH-1:PMT_ADDR_WIDTH];
            pmt_addr_base = lmt_rd_addr[PMT_ADDR_WIDTH-1:0];
            
            // Issue reads to selected PMTs
            for (i = 0; i < MAX_PMTS; i = i + 1) begin
                if (i < num_pmts && (i / width_blocks) == pmt_depth_idx) begin
                    pmt_rd_en[i] = 1'b1;
                    pmt_rd_addr[i*PMT_ADDR_WIDTH +: PMT_ADDR_WIDTH] = pmt_addr_base;
                end
            end
        end
    end
    
    // COMBINE: Merge read results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lmt_rd_data <= {LMT_MAX_WIDTH{1'b0}};
            lmt_rd_valid <= 1'b0;
        end else begin
            combined_rd_data = {LMT_MAX_WIDTH{1'b0}};
            combined_rd_valid = 1'b0;
            
            for (i = 0; i < MAX_PMTS; i = i + 1) begin
                if (pmt_rd_valid[i]) begin
                    pmt_width_idx = i % width_blocks;
                    combined_rd_data[pmt_width_idx*PMT_WIDTH +: PMT_WIDTH] = 
                        pmt_rd_data[i*PMT_WIDTH +: PMT_WIDTH];
                    combined_rd_valid = 1'b1;
                end
            end
            
            lmt_rd_data <= combined_rd_data;
            lmt_rd_valid <= combined_rd_valid;
        end
    end
    
    // ========================================================================
    // SEARCH PATH (TCAM): PMT → LMT
    // Implements: PARTITION, SPREAD, COMBINE, MAND
    // ========================================================================
    
    always @(*) begin
        // Default values
        pmt_search_en = {MAX_PMTS{1'b0}};
        pmt_search_key = {MAX_PMTS*PMT_WIDTH{1'b0}};
        
        if (lmt_search_en) begin
            // SPREAD & PARTITION: Search all PMTs with partitioned key
            for (i = 0; i < MAX_PMTS; i = i + 1) begin
                if (i < num_pmts) begin
                    pmt_search_en[i] = 1'b1;
                    pmt_width_idx = i % width_blocks;
                    
                    // PARTITION: Extract segment for this PMT
                    pmt_search_key[i*PMT_WIDTH +: PMT_WIDTH] = 
                        lmt_search_key[pmt_width_idx*PMT_WIDTH +: PMT_WIDTH];
                end
            end
        end
    end
    
    // COMBINE & MAND: Merge matchlines
    reg [LMT_MAX_DEPTH-1:0] combined_matchlines;
    reg [LMT_ADDR_WIDTH-1:0] priority_addr;
    reg match_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lmt_matchlines <= {LMT_MAX_DEPTH{1'b0}};
            lmt_match_found <= 1'b0;
            lmt_match_addr <= {LMT_ADDR_WIDTH{1'b0}};
        end else begin
            combined_matchlines = {LMT_MAX_DEPTH{1'b0}};
            
            // Process each depth block
            for (i = 0; i < depth_blocks; i = i + 1) begin
                for (j = 0; j < PMT_DEPTH; j = j + 1) begin
                    
                    match_valid = 1'b1;
                    
                    // MAND: AND matchlines across width for this entry
                    for (k = 0; k < width_blocks; k = k + 1) begin
                        if ((i * width_blocks + k) < num_pmts) begin
                            match_valid = match_valid & 
                                pmt_matchlines[(i*width_blocks + k)*PMT_DEPTH + j];
                        end
                    end
                    
                    // COMBINE: Set combined matchline
                    combined_matchlines[i*PMT_DEPTH + j] = match_valid;
                end
            end
            
            lmt_matchlines <= combined_matchlines;
            lmt_match_found <= |combined_matchlines;
            
            // Priority encoder - find first match
            priority_addr = {LMT_ADDR_WIDTH{1'b0}};
            for (i = LMT_MAX_DEPTH-1; i >= 0; i = i - 1) begin
                if (combined_matchlines[i]) begin
                    priority_addr = i[LMT_ADDR_WIDTH-1:0];
                end
            end
            lmt_match_addr <= priority_addr;
        end
    end

endmodule
