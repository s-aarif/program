// ============================================================================
// Complete Segment Crossbar Module
// Connects all LMTs to PMT Pool with segment interconnect architecture
// Implements multiplexer abstractions: PARTITION, SELECT, SPREAD, COMBINE, MAND
// ============================================================================

module segment_crossbar #(
    parameter NUM_LMTS = 5,
    parameter NUM_PMTS = 32,
    parameter LMT_MAX_WIDTH = 64,
    parameter LMT_MAX_DEPTH = 256,
    parameter LMT_ADDR_WIDTH = 8,
    parameter PMT_WIDTH = 32,
    parameter PMT_DEPTH = 32,
    parameter PMT_ADDR_WIDTH = 5,
    parameter MAX_PMTS_PER_LMT = 8,
    parameter PMT_ID_WIDTH = 6
) (
    input  wire                          clk,
    input  wire                          rst_n,
    
    // ========================================================================
    // Configuration (LPSS)
    // ========================================================================
    input  wire [NUM_LMTS*8-1:0]         lmt_pmt_count,
    input  wire [NUM_LMTS*PMT_ID_WIDTH-1:0] lmt_aspid,
    input  wire [NUM_LMTS*PMT_ID_WIDTH-1:0] lmt_aepid,
    input  wire [NUM_LMTS*2-1:0]         lmt_width_gear,
    input  wire [NUM_LMTS*3-1:0]         lmt_depth_gear,
    
    input  wire [NUM_PMTS-1:0]           pmt_used,
    input  wire [NUM_PMTS*8-1:0]         pmt_lmt_id,
    input  wire [NUM_PMTS*4-1:0]         pmt_width_idx,
    input  wire [NUM_PMTS*4-1:0]         pmt_depth_idx,
    
    // ========================================================================
    // LMT Side Interfaces (Array)
    // ========================================================================
    input  wire [NUM_LMTS-1:0]           lmt_wr_en,
    input  wire [NUM_LMTS*LMT_ADDR_WIDTH-1:0] lmt_wr_addr,
    input  wire [NUM_LMTS*LMT_MAX_WIDTH-1:0] lmt_wr_data,
    input  wire [NUM_LMTS*LMT_MAX_WIDTH-1:0] lmt_wr_mask,
    
    input  wire [NUM_LMTS-1:0]           lmt_rd_en,
    input  wire [NUM_LMTS*LMT_ADDR_WIDTH-1:0] lmt_rd_addr,
    output wire [NUM_LMTS*LMT_MAX_WIDTH-1:0] lmt_rd_data,
    output wire [NUM_LMTS-1:0]           lmt_rd_valid,
    
    input  wire [NUM_LMTS-1:0]           lmt_search_en,
    input  wire [NUM_LMTS*LMT_MAX_WIDTH-1:0] lmt_search_key,
    output wire [NUM_LMTS*LMT_MAX_DEPTH-1:0] lmt_matchlines,
    output wire [NUM_LMTS-1:0]           lmt_match_found,
    output wire [NUM_LMTS*LMT_ADDR_WIDTH-1:0] lmt_match_addr,
    
    // ========================================================================
    // PMT Side Interfaces (to PMT Pool)
    // ========================================================================
    output wire [NUM_PMTS-1:0]           pmt_wr_en,
    output wire [NUM_PMTS*PMT_ADDR_WIDTH-1:0] pmt_wr_addr,
    output wire [NUM_PMTS*PMT_WIDTH-1:0] pmt_wr_data,
    output wire [NUM_PMTS*PMT_WIDTH-1:0] pmt_wr_mask,
    
    output wire [NUM_PMTS-1:0]           pmt_rd_en,
    output wire [NUM_PMTS*PMT_ADDR_WIDTH-1:0] pmt_rd_addr,
    input  wire [NUM_PMTS*PMT_WIDTH-1:0] pmt_rd_data,
    input  wire [NUM_PMTS-1:0]           pmt_rd_valid,
    
    output wire [NUM_PMTS-1:0]           pmt_search_en,
    output wire [NUM_PMTS*PMT_WIDTH-1:0] pmt_search_key,
    input  wire [NUM_PMTS*PMT_DEPTH-1:0] pmt_matchlines,
    input  wire [NUM_PMTS-1:0]           pmt_match_found,
    input  wire [NUM_PMTS*PMT_ADDR_WIDTH-1:0] pmt_match_addr
);

    // ========================================================================
    // Internal Signals - Per LMT Crossbar Outputs
    // ========================================================================
    genvar g;
    integer i, j, k;
    
    // Per-LMT to PMT signals (before arbitration)
    reg [NUM_PMTS-1:0]                   lmt_to_pmt_wr_en [0:NUM_LMTS-1];
    reg [NUM_PMTS*PMT_ADDR_WIDTH-1:0]   lmt_to_pmt_wr_addr [0:NUM_LMTS-1];
    reg [NUM_PMTS*PMT_WIDTH-1:0]        lmt_to_pmt_wr_data [0:NUM_LMTS-1];
    reg [NUM_PMTS*PMT_WIDTH-1:0]        lmt_to_pmt_wr_mask [0:NUM_LMTS-1];
    
    reg [NUM_PMTS-1:0]                   lmt_to_pmt_rd_en [0:NUM_LMTS-1];
    reg [NUM_PMTS*PMT_ADDR_WIDTH-1:0]   lmt_to_pmt_rd_addr [0:NUM_LMTS-1];
    
    reg [NUM_PMTS-1:0]                   lmt_to_pmt_search_en [0:NUM_LMTS-1];
    reg [NUM_PMTS*PMT_WIDTH-1:0]        lmt_to_pmt_search_key [0:NUM_LMTS-1];
    
    // Per-LMT outputs (after combining PMT results)
    reg [LMT_MAX_WIDTH-1:0]              lmt_rd_data_reg [0:NUM_LMTS-1];
    reg                                  lmt_rd_valid_reg [0:NUM_LMTS-1];
    reg [LMT_MAX_DEPTH-1:0]              lmt_matchlines_reg [0:NUM_LMTS-1];
    reg                                  lmt_match_found_reg [0:NUM_LMTS-1];
    reg [LMT_ADDR_WIDTH-1:0]             lmt_match_addr_reg [0:NUM_LMTS-1];
    
    // ========================================================================
    // Generate Crossbar Logic for Each LMT
    // ========================================================================
    generate
        for (g = 0; g < NUM_LMTS; g = g + 1) begin : gen_lmt_crossbar
            
            // Local parameters for this LMT
            wire [7:0] num_pmts;
            wire [PMT_ID_WIDTH-1:0] aspid;
            wire [PMT_ID_WIDTH-1:0] aepid;
            wire [1:0] width_gear;
            wire [2:0] depth_gear;
            wire [7:0] width_blocks;
            wire [7:0] depth_blocks;
            
            assign num_pmts = lmt_pmt_count[g*8 +: 8];
            assign aspid = lmt_aspid[g*PMT_ID_WIDTH +: PMT_ID_WIDTH];
            assign aepid = lmt_aepid[g*PMT_ID_WIDTH +: PMT_ID_WIDTH];
            assign width_gear = lmt_width_gear[g*2 +: 2];
            assign depth_gear = lmt_depth_gear[g*3 +: 3];
            assign width_blocks = (1 << width_gear);
            assign depth_blocks = (1 << depth_gear);
            
            // ================================================================
            // Write Path: PARTITION, SELECT, SPREAD
            // ================================================================
            reg [LMT_ADDR_WIDTH-1:0] wr_addr_this_lmt;
            reg [PMT_ADDR_WIDTH-1:0] wr_addr_low;
            reg [3:0] wr_addr_high;
            reg [PMT_WIDTH-1:0] wr_data_segment;
            reg [PMT_WIDTH-1:0] wr_mask_segment;
            
            always @(*) begin
                lmt_to_pmt_wr_en[g] = {NUM_PMTS{1'b0}};
                lmt_to_pmt_wr_addr[g] = {NUM_PMTS*PMT_ADDR_WIDTH{1'b0}};
                lmt_to_pmt_wr_data[g] = {NUM_PMTS*PMT_WIDTH{1'b0}};
                lmt_to_pmt_wr_mask[g] = {NUM_PMTS*PMT_WIDTH{1'b0}};
                
                // Extract LMT write address
                for (i = 0; i < LMT_ADDR_WIDTH; i = i + 1) begin
                    wr_addr_this_lmt[i] = lmt_wr_addr[g*LMT_ADDR_WIDTH + i];
                end
                
                // Split address into high and low parts
                for (i = 0; i < PMT_ADDR_WIDTH; i = i + 1) begin
                    wr_addr_low[i] = wr_addr_this_lmt[i];
                end
                
                if (LMT_ADDR_WIDTH > PMT_ADDR_WIDTH) begin
                    for (i = 0; i < (LMT_ADDR_WIDTH - PMT_ADDR_WIDTH); i = i + 1) begin
                        wr_addr_high[i] = wr_addr_this_lmt[PMT_ADDR_WIDTH + i];
                    end
                end else begin
                    wr_addr_high = 4'd0;
                end
                
                if (lmt_wr_en[g]) begin
                    for (i = 0; i < MAX_PMTS_PER_LMT; i = i + 1) begin
                        if (i < num_pmts && (aspid + i) < NUM_PMTS) begin
                            // SELECT: Determine which depth block
                            if (depth_blocks > 1) begin
                                if ((i / width_blocks) == wr_addr_high) begin
                                    // SPREAD: Enable write
                                    lmt_to_pmt_wr_en[g][aspid + i] = 1'b1;
                                    
                                    // Address (low bits)
                                    for (j = 0; j < PMT_ADDR_WIDTH; j = j + 1) begin
                                        lmt_to_pmt_wr_addr[g][(aspid + i)*PMT_ADDR_WIDTH + j] = wr_addr_low[j];
                                    end
                                    
                                    // PARTITION: Extract data segment
                                    for (j = 0; j < PMT_WIDTH; j = j + 1) begin
                                        wr_data_segment[j] = lmt_wr_data[g*LMT_MAX_WIDTH + (i % width_blocks)*PMT_WIDTH + j];
                                        wr_mask_segment[j] = lmt_wr_mask[g*LMT_MAX_WIDTH + (i % width_blocks)*PMT_WIDTH + j];
                                    end
                                    
                                    for (j = 0; j < PMT_WIDTH; j = j + 1) begin
                                        lmt_to_pmt_wr_data[g][(aspid + i)*PMT_WIDTH + j] = wr_data_segment[j];
                                        lmt_to_pmt_wr_mask[g][(aspid + i)*PMT_WIDTH + j] = wr_mask_segment[j];
                                    end
                                end
                            end else begin
                                // Single depth block
                                lmt_to_pmt_wr_en[g][aspid + i] = 1'b1;
                                
                                for (j = 0; j < PMT_ADDR_WIDTH; j = j + 1) begin
                                    lmt_to_pmt_wr_addr[g][(aspid + i)*PMT_ADDR_WIDTH + j] = wr_addr_low[j];
                                end
                                
                                for (j = 0; j < PMT_WIDTH; j = j + 1) begin
                                    wr_data_segment[j] = lmt_wr_data[g*LMT_MAX_WIDTH + (i % width_blocks)*PMT_WIDTH + j];
                                    wr_mask_segment[j] = lmt_wr_mask[g*LMT_MAX_WIDTH + (i % width_blocks)*PMT_WIDTH + j];
                                end
                                
                                for (j = 0; j < PMT_WIDTH; j = j + 1) begin
                                    lmt_to_pmt_wr_data[g][(aspid + i)*PMT_WIDTH + j] = wr_data_segment[j];
                                    lmt_to_pmt_wr_mask[g][(aspid + i)*PMT_WIDTH + j] = wr_mask_segment[j];
                                end
                            end
                        end
                    end
                end
            end
            
            // ================================================================
            // Read Path: SELECT, COMBINE
            // ================================================================
            reg [LMT_ADDR_WIDTH-1:0] rd_addr_this_lmt;
            reg [PMT_ADDR_WIDTH-1:0] rd_addr_low;
            reg [3:0] rd_addr_high;
            
            always @(*) begin
                lmt_to_pmt_rd_en[g] = {NUM_PMTS{1'b0}};
                lmt_to_pmt_rd_addr[g] = {NUM_PMTS*PMT_ADDR_WIDTH{1'b0}};
                
                // Extract LMT read address
                for (i = 0; i < LMT_ADDR_WIDTH; i = i + 1) begin
                    rd_addr_this_lmt[i] = lmt_rd_addr[g*LMT_ADDR_WIDTH + i];
                end
                
                // Split address
                for (i = 0; i < PMT_ADDR_WIDTH; i = i + 1) begin
                    rd_addr_low[i] = rd_addr_this_lmt[i];
                end
                
                if (LMT_ADDR_WIDTH > PMT_ADDR_WIDTH) begin
                    for (i = 0; i < (LMT_ADDR_WIDTH - PMT_ADDR_WIDTH); i = i + 1) begin
                        rd_addr_high[i] = rd_addr_this_lmt[PMT_ADDR_WIDTH + i];
                    end
                end else begin
                    rd_addr_high = 4'd0;
                end
                
                if (lmt_rd_en[g]) begin
                    for (i = 0; i < MAX_PMTS_PER_LMT; i = i + 1) begin
                        if (i < num_pmts && (aspid + i) < NUM_PMTS) begin
                            // SELECT depth block
                            if (depth_blocks > 1) begin
                                if ((i / width_blocks) == rd_addr_high) begin
                                    lmt_to_pmt_rd_en[g][aspid + i] = 1'b1;
                                    for (j = 0; j < PMT_ADDR_WIDTH; j = j + 1) begin
                                        lmt_to_pmt_rd_addr[g][(aspid + i)*PMT_ADDR_WIDTH + j] = rd_addr_low[j];
                                    end
                                end
                            end else begin
                                lmt_to_pmt_rd_en[g][aspid + i] = 1'b1;
                                for (j = 0; j < PMT_ADDR_WIDTH; j = j + 1) begin
                                    lmt_to_pmt_rd_addr[g][(aspid + i)*PMT_ADDR_WIDTH + j] = rd_addr_low[j];
                                end
                            end
                        end
                    end
                end
            end
            
            // COMBINE read results
            reg [PMT_WIDTH-1:0] rd_data_segment;
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    lmt_rd_data_reg[g] <= {LMT_MAX_WIDTH{1'b0}};
                    lmt_rd_valid_reg[g] <= 1'b0;
                end else begin
                    lmt_rd_data_reg[g] = {LMT_MAX_WIDTH{1'b0}};
                    lmt_rd_valid_reg[g] = 1'b0;
                    
                    for (i = 0; i < MAX_PMTS_PER_LMT; i = i + 1) begin
                        if (i < num_pmts && (aspid + i) < NUM_PMTS) begin
                            if (pmt_rd_valid[aspid + i]) begin
                                // COMBINE: Assemble data from PMT segments
                                for (j = 0; j < PMT_WIDTH; j = j + 1) begin
                                    rd_data_segment[j] = pmt_rd_data[(aspid + i)*PMT_WIDTH + j];
                                end
                                
                                for (j = 0; j < PMT_WIDTH; j = j + 1) begin
                                    lmt_rd_data_reg[g][(i % width_blocks)*PMT_WIDTH + j] = rd_data_segment[j];
                                end
                                
                                lmt_rd_valid_reg[g] = 1'b1;
                            end
                        end
                    end
                end
            end
            
            // ================================================================
            // Search Path: PARTITION, SPREAD, COMBINE, MAND
            // ================================================================
            reg [PMT_WIDTH-1:0] search_key_segment;
            
            always @(*) begin
                lmt_to_pmt_search_en[g] = {NUM_PMTS{1'b0}};
                lmt_to_pmt_search_key[g] = {NUM_PMTS*PMT_WIDTH{1'b0}};
                
                if (lmt_search_en[g]) begin
                    for (i = 0; i < MAX_PMTS_PER_LMT; i = i + 1) begin
                        if (i < num_pmts && (aspid + i) < NUM_PMTS) begin
                            // SPREAD: Search all PMTs
                            lmt_to_pmt_search_en[g][aspid + i] = 1'b1;
                            
                            // PARTITION: Extract key segment
                            for (j = 0; j < PMT_WIDTH; j = j + 1) begin
                                search_key_segment[j] = lmt_search_key[g*LMT_MAX_WIDTH + (i % width_blocks)*PMT_WIDTH + j];
                            end
                            
                            for (j = 0; j < PMT_WIDTH; j = j + 1) begin
                                lmt_to_pmt_search_key[g][(aspid + i)*PMT_WIDTH + j] = search_key_segment[j];
                            end
                        end
                    end
                end
            end
            
            // COMBINE & MAND: Merge matchlines
            reg [LMT_MAX_DEPTH-1:0] combined_ml;
            reg match_valid;
            reg pmt_ml_bit;
            integer entry_idx;
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    lmt_matchlines_reg[g] <= {LMT_MAX_DEPTH{1'b0}};
                    lmt_match_found_reg[g] <= 1'b0;
                    lmt_match_addr_reg[g] <= {LMT_ADDR_WIDTH{1'b0}};
                end else begin
                    
                    combined_ml = {LMT_MAX_DEPTH{1'b0}};
                    
                    // Process each entry across all PMTs
                    for (i = 0; i < depth_blocks; i = i + 1) begin
                        for (j = 0; j < PMT_DEPTH; j = j + 1) begin
                            match_valid = 1'b1;
                            
                            // MAND: AND across width blocks for this entry
                            for (k = 0; k < width_blocks; k = k + 1) begin
                                if ((i * width_blocks + k) < num_pmts && (aspid + i * width_blocks + k) < NUM_PMTS) begin
                                    pmt_ml_bit = pmt_matchlines[(aspid + i * width_blocks + k)*PMT_DEPTH + j];
                                    match_valid = match_valid & pmt_ml_bit;
                                end
                            end
                            
                            // COMBINE: Set combined matchline
                            entry_idx = i*PMT_DEPTH + j;
                            if (entry_idx < LMT_MAX_DEPTH) begin
                                combined_ml[entry_idx] = match_valid;
                            end
                        end
                    end
                    
                    lmt_matchlines_reg[g] = combined_ml;
                    lmt_match_found_reg[g] = |combined_ml;
                    
                    // Priority encoder
                    lmt_match_addr_reg[g] = {LMT_ADDR_WIDTH{1'b0}};
                    for (i = LMT_MAX_DEPTH-1; i >= 0; i = i - 1) begin
                        if (combined_ml[i]) begin
                            lmt_match_addr_reg[g] = i[LMT_ADDR_WIDTH-1:0];
                        end
                    end
                end
            end
            
            // Pack outputs
            assign lmt_rd_data[g*LMT_MAX_WIDTH +: LMT_MAX_WIDTH] = lmt_rd_data_reg[g];
            assign lmt_rd_valid[g] = lmt_rd_valid_reg[g];
            assign lmt_matchlines[g*LMT_MAX_DEPTH +: LMT_MAX_DEPTH] = lmt_matchlines_reg[g];
            assign lmt_match_found[g] = lmt_match_found_reg[g];
            assign lmt_match_addr[g*LMT_ADDR_WIDTH +: LMT_ADDR_WIDTH] = lmt_match_addr_reg[g];
        end
    endgenerate
    
    // ========================================================================
    // Arbitrate Multiple LMTs to Single PMT (OR Logic)
    // ========================================================================
    reg [NUM_PMTS-1:0]                   pmt_wr_en_reg;
    reg [NUM_PMTS*PMT_ADDR_WIDTH-1:0]   pmt_wr_addr_reg;
    reg [NUM_PMTS*PMT_WIDTH-1:0]        pmt_wr_data_reg;
    reg [NUM_PMTS*PMT_WIDTH-1:0]        pmt_wr_mask_reg;
    
    reg [NUM_PMTS-1:0]                   pmt_rd_en_reg;
    reg [NUM_PMTS*PMT_ADDR_WIDTH-1:0]   pmt_rd_addr_reg;
    
    reg [NUM_PMTS-1:0]                   pmt_search_en_reg;
    reg [NUM_PMTS*PMT_WIDTH-1:0]        pmt_search_key_reg;
    
    always @(*) begin
        pmt_wr_en_reg = {NUM_PMTS{1'b0}};
        pmt_wr_addr_reg = {NUM_PMTS*PMT_ADDR_WIDTH{1'b0}};
        pmt_wr_data_reg = {NUM_PMTS*PMT_WIDTH{1'b0}};
        pmt_wr_mask_reg = {NUM_PMTS*PMT_WIDTH{1'b0}};
        
        pmt_rd_en_reg = {NUM_PMTS{1'b0}};
        pmt_rd_addr_reg = {NUM_PMTS*PMT_ADDR_WIDTH{1'b0}};
        
        pmt_search_en_reg = {NUM_PMTS{1'b0}};
        pmt_search_key_reg = {NUM_PMTS*PMT_WIDTH{1'b0}};
        
        // OR all LMT requests for each PMT
        for (i = 0; i < NUM_PMTS; i = i + 1) begin
            for (j = 0; j < NUM_LMTS; j = j + 1) begin
                if (lmt_to_pmt_wr_en[j][i]) begin
                    pmt_wr_en_reg[i] = 1'b1;
                    for (k = 0; k < PMT_ADDR_WIDTH; k = k + 1) begin
                        pmt_wr_addr_reg[i*PMT_ADDR_WIDTH + k] = 
                            lmt_to_pmt_wr_addr[j][i*PMT_ADDR_WIDTH + k];
                    end
                    for (k = 0; k < PMT_WIDTH; k = k + 1) begin
                        pmt_wr_data_reg[i*PMT_WIDTH + k] = 
                            lmt_to_pmt_wr_data[j][i*PMT_WIDTH + k];
                        pmt_wr_mask_reg[i*PMT_WIDTH + k] = 
                            lmt_to_pmt_wr_mask[j][i*PMT_WIDTH + k];
                    end
                end
                
                if (lmt_to_pmt_rd_en[j][i]) begin
                    pmt_rd_en_reg[i] = 1'b1;
                    for (k = 0; k < PMT_ADDR_WIDTH; k = k + 1) begin
                        pmt_rd_addr_reg[i*PMT_ADDR_WIDTH + k] = 
                            lmt_to_pmt_rd_addr[j][i*PMT_ADDR_WIDTH + k];
                    end
                end
                
                if (lmt_to_pmt_search_en[j][i]) begin
                    pmt_search_en_reg[i] = 1'b1;
                    for (k = 0; k < PMT_WIDTH; k = k + 1) begin
                        pmt_search_key_reg[i*PMT_WIDTH + k] = 
                            lmt_to_pmt_search_key[j][i*PMT_WIDTH + k];
                    end
                end
            end
        end
    end
    
    assign pmt_wr_en = pmt_wr_en_reg & pmt_used;
    assign pmt_wr_addr = pmt_wr_addr_reg;
    assign pmt_wr_data = pmt_wr_data_reg;
    assign pmt_wr_mask = pmt_wr_mask_reg;
    
    assign pmt_rd_en = pmt_rd_en_reg & pmt_used;
    assign pmt_rd_addr = pmt_rd_addr_reg;
    
    assign pmt_search_en = pmt_search_en_reg & pmt_used;
    assign pmt_search_key = pmt_search_key_reg;

endmodule