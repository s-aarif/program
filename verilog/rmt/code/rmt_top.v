`timescale 1ns/1ps

module rmt_pipeline #(
    parameter NUM_STAGES = 5,           // Number of MAU stages
    parameter MAX_UMTS = 5,
    parameter MAX_LMTS = 5,
    parameter NUM_PMTS_TCAM = 32,
    parameter NUM_PMTS_SRAM = 32,
    parameter PHV_WIDTH = 512,
    parameter MAX_KEY_WIDTH = 64,
    parameter MAX_DEPTH = 256,
    parameter MAX_DEPTH_BITS = 8,
    parameter PMT_WIDTH = 32,
    parameter PMT_DEPTH = 32,
    parameter PMT_ADDR_WIDTH = 5,
    parameter MAX_PMTS_PER_LMT = 8,
    parameter PMT_ID_WIDTH = 6
) (
    input  wire                          clk,
    input  wire                          rst_n,
    
    // ========================================================================
    // Control Plane Interface (UMT Configuration)
    // ========================================================================
    input  wire                          umt_cfg_valid,
    input  wire                          umt_cfg_wr_en,
    input  wire [2:0]                    umt_cfg_id,
    input  wire [15:0]                   umt_cfg_width,
    input  wire [15:0]                   umt_cfg_depth,
    input  wire                          umt_cfg_type,
    
    input  wire                          umt_map_trigger,
    output wire                          map_done,
    output wire                          map_error,
    
    // ========================================================================
    // Entry Installation Interface
    // ========================================================================
    input  wire                          entry_valid,
    input  wire [2:0]                    entry_umt_id,
    input  wire [MAX_DEPTH_BITS-1:0]     entry_addr,
    input  wire [MAX_KEY_WIDTH-1:0]      entry_data,
    input  wire [MAX_KEY_WIDTH-1:0]      entry_mask,
    
    // ========================================================================
    // Key Extractor Configuration (per stage)
    // ========================================================================
    input  wire [NUM_STAGES*4-1:0]       key_field_select,
    input  wire [NUM_STAGES*16-1:0]      key_field_offset,
    input  wire [NUM_STAGES*8-1:0]       key_field_length,
    
    // ========================================================================
    // Packet Processing Pipeline
    // ========================================================================
    input  wire                          pkt_valid_in,
    input  wire [PHV_WIDTH-1:0]          pkt_phv_in,
    input  wire [7:0]                    pkt_umt_id_in,
    
    output wire                          pkt_valid_out,
    output wire [PHV_WIDTH-1:0]          pkt_phv_out,
    output wire                          pkt_match_found_out,
    output wire [MAX_DEPTH_BITS-1:0]     pkt_match_addr_out,
    output wire [63:0]                   pkt_action_out,
    
    // ========================================================================
    // Status
    // ========================================================================
    output wire [7:0]                    total_lmts_used,
    output wire [15:0]                   total_pmts_needed,
    output wire [31:0]                   total_searches,
    output wire [31:0]                   total_matches
);

    // ========================================================================
    // Internal Signals
    // ========================================================================
    
    // UMT to LMT mapping
    wire [MAX_LMTS-1:0]       lmt_used;
    wire [MAX_LMTS*8-1:0]     lmt_uid;
    wire [MAX_LMTS*8-1:0]     lmt_internal_id;
    wire [MAX_LMTS*2-1:0]     lmt_status_flag;
    wire [MAX_LMTS*2-1:0]     lmt_width_gear;
    wire [MAX_LMTS*3-1:0]     lmt_depth_gear;
    
    // Entry installation
    wire                      lmt_entry_valid;
    wire [2:0]                lmt_entry_id;
    wire [MAX_DEPTH_BITS-1:0] lmt_entry_addr;
    wire [MAX_KEY_WIDTH-1:0]  lmt_entry_data;
    wire [MAX_KEY_WIDTH-1:0]  lmt_entry_mask;
    
    // PMT allocation (TCAM)
    wire                      tcam_alloc_done;
    wire                      tcam_alloc_error;
    wire [MAX_LMTS*8-1:0]     tcam_lmt_pmt_count;
    wire [MAX_LMTS*PMT_ID_WIDTH-1:0] tcam_lmt_aspid;
    wire [MAX_LMTS*PMT_ID_WIDTH-1:0] tcam_lmt_aepid;
    wire [NUM_PMTS_TCAM-1:0]  tcam_pmt_used;
    wire [NUM_PMTS_TCAM*8-1:0] tcam_pmt_lmt_id;
    wire [NUM_PMTS_TCAM*4-1:0] tcam_pmt_width_idx;
    wire [NUM_PMTS_TCAM*4-1:0] tcam_pmt_depth_idx;
    
    // Pipeline inter-stage signals
    wire [NUM_STAGES:0]       stage_valid;
    wire [NUM_STAGES*PHV_WIDTH-1:0] stage_phv;
    wire [NUM_STAGES*8-1:0]   stage_umt_id;
    wire [NUM_STAGES-1:0]     stage_match_found;
    wire [NUM_STAGES*MAX_DEPTH_BITS-1:0] stage_match_addr;
    wire [NUM_STAGES*64-1:0]  stage_metadata;
    wire [NUM_STAGES*8-1:0]   stage_action;
    
    // Crossbar to PMT pool (TCAM)
    wire [NUM_PMTS_TCAM-1:0]  tcam_pmt_wr_en;
    wire [NUM_PMTS_TCAM*PMT_ADDR_WIDTH-1:0] tcam_pmt_wr_addr;
    wire [NUM_PMTS_TCAM*PMT_WIDTH-1:0] tcam_pmt_wr_data;
    wire [NUM_PMTS_TCAM*PMT_WIDTH-1:0] tcam_pmt_wr_mask;
    
    wire [NUM_PMTS_TCAM-1:0]  tcam_pmt_search_en;
    wire [NUM_PMTS_TCAM*PMT_WIDTH-1:0] tcam_pmt_search_key;
    wire [NUM_PMTS_TCAM*PMT_DEPTH-1:0] tcam_pmt_matchlines;
    wire [NUM_PMTS_TCAM-1:0]  tcam_pmt_match_found;
    wire [NUM_PMTS_TCAM*PMT_ADDR_WIDTH-1:0] tcam_pmt_match_addr;
    
    // LMT to Crossbar (TCAM)
    wire [MAX_LMTS-1:0]       lmt_tcam_wr_en;
    wire [MAX_LMTS*MAX_DEPTH_BITS-1:0] lmt_tcam_wr_addr;
    wire [MAX_LMTS*MAX_KEY_WIDTH-1:0] lmt_tcam_wr_data;
    wire [MAX_LMTS*MAX_KEY_WIDTH-1:0] lmt_tcam_wr_mask;
    
    wire [MAX_LMTS-1:0]       lmt_tcam_search_en;
    wire [MAX_LMTS*MAX_KEY_WIDTH-1:0] lmt_tcam_search_key;
    wire [MAX_LMTS*MAX_DEPTH-1:0] lmt_tcam_matchlines;
    wire [MAX_LMTS-1:0]       lmt_tcam_match_found;
    wire [MAX_LMTS*MAX_DEPTH_BITS-1:0] lmt_tcam_match_addr;
    
    // ========================================================================
    // UMT Layer - Control Plane Configuration
    // ========================================================================
    umt_top #(
        .MAX_UMTS(MAX_UMTS),
        .MAX_LMTS(MAX_LMTS),
        .MAX_WIDTH(MAX_KEY_WIDTH),
        .MAX_DEPTH(MAX_DEPTH),
        .PMT_WIDTH(PMT_WIDTH),
        .PMT_DEPTH(PMT_DEPTH),
        .MAX_PMTS_PER_LMT(MAX_PMTS_PER_LMT)
    ) umt_layer (
        .clk(clk),
        .rst_n(rst_n),
        
        // Configuration
        .umt_cfg_valid(umt_cfg_valid),
        .umt_cfg_wr_en(umt_cfg_wr_en),
        .umt_cfg_id(umt_cfg_id),
        .umt_cfg_width(umt_cfg_width),
        .umt_cfg_depth(umt_cfg_depth),
        .umt_cfg_type(umt_cfg_type),
        .umt_map_trigger(umt_map_trigger),
        
        // Entry Management
        .entry_valid(entry_valid),
        .entry_umt_id(entry_umt_id),
        .entry_addr(entry_addr),
        .entry_data(entry_data),
        .entry_mask(entry_mask),
        
        // ULSS Output
        .map_done(map_done),
        .map_error(map_error),
        .lmt_used(lmt_used),
        .lmt_uid(lmt_uid),
        .lmt_internal_id(lmt_internal_id),
        .lmt_status_flag(lmt_status_flag),
        .lmt_width_gear(lmt_width_gear),
        .lmt_depth_gear(lmt_depth_gear),
        
        // Entry Installation
        .lmt_entry_valid(lmt_entry_valid),
        .lmt_entry_id(lmt_entry_id),
        .lmt_entry_addr(lmt_entry_addr),
        .lmt_entry_data(lmt_entry_data),
        .lmt_entry_mask(lmt_entry_mask),
        
        // Status
        .total_lmts_used(total_lmts_used),
        .total_pmts_needed(total_pmts_needed)
    );
    
    // ========================================================================
    // PMT Manager - Allocate PMTs to LMTs
    // ========================================================================
    pmt_manager #(
        .NUM_LMTS(MAX_LMTS),
        .NUM_PMTS(NUM_PMTS_TCAM),
        .PMT_WIDTH(PMT_WIDTH),
        .PMT_DEPTH(PMT_DEPTH),
        .MAX_PMTS_PER_LMT(MAX_PMTS_PER_LMT),
        .PMT_ID_WIDTH(PMT_ID_WIDTH)
    ) tcam_pmt_manager (
        .clk(clk),
        .rst_n(rst_n),
        
        .alloc_trigger(map_done),
        .lmt_used(lmt_used),
        .lmt_width_gear(lmt_width_gear),
        .lmt_depth_gear(lmt_depth_gear),
        
        .alloc_done(tcam_alloc_done),
        .alloc_error(tcam_alloc_error),
        .alloc_error_code(),
        
        .lmt_pmt_count(tcam_lmt_pmt_count),
        .lmt_aspid(tcam_lmt_aspid),
        .lmt_aepid(tcam_lmt_aepid),
        .lmt_pspid(),
        .lmt_pepid(),
        
        .pmt_used(tcam_pmt_used),
        .pmt_lmt_id(tcam_pmt_lmt_id),
        .pmt_width_idx(tcam_pmt_width_idx),
        .pmt_depth_idx(tcam_pmt_depth_idx),
        
        .total_pmts_used()
    );
    
    // ========================================================================
    // Segment Crossbar - Connect LMTs to PMT Pool
    // ========================================================================
    segment_crossbar #(
        .NUM_LMTS(MAX_LMTS),
        .NUM_PMTS(NUM_PMTS_TCAM),
        .LMT_MAX_WIDTH(MAX_KEY_WIDTH),
        .LMT_MAX_DEPTH(MAX_DEPTH),
        .LMT_ADDR_WIDTH(MAX_DEPTH_BITS),
        .PMT_WIDTH(PMT_WIDTH),
        .PMT_DEPTH(PMT_DEPTH),
        .PMT_ADDR_WIDTH(PMT_ADDR_WIDTH),
        .MAX_PMTS_PER_LMT(MAX_PMTS_PER_LMT),
        .PMT_ID_WIDTH(PMT_ID_WIDTH)
    ) tcam_crossbar (
        .clk(clk),
        .rst_n(rst_n),
        
        // Configuration (LPSS)
        .lmt_pmt_count(tcam_lmt_pmt_count),
        .lmt_aspid(tcam_lmt_aspid),
        .lmt_aepid(tcam_lmt_aepid),
        .lmt_width_gear(lmt_width_gear),
        .lmt_depth_gear(lmt_depth_gear),
        
        .pmt_used(tcam_pmt_used),
        .pmt_lmt_id(tcam_pmt_lmt_id),
        .pmt_width_idx(tcam_pmt_width_idx),
        .pmt_depth_idx(tcam_pmt_depth_idx),
        
        // LMT side
        .lmt_wr_en(lmt_tcam_wr_en),
        .lmt_wr_addr(lmt_tcam_wr_addr),
        .lmt_wr_data(lmt_tcam_wr_data),
        .lmt_wr_mask(lmt_tcam_wr_mask),
        
        .lmt_rd_en({MAX_LMTS{1'b0}}),
        .lmt_rd_addr({MAX_LMTS*MAX_DEPTH_BITS{1'b0}}),
        .lmt_rd_data(),
        .lmt_rd_valid(),
        
        .lmt_search_en(lmt_tcam_search_en),
        .lmt_search_key(lmt_tcam_search_key),
        .lmt_matchlines(lmt_tcam_matchlines),
        .lmt_match_found(lmt_tcam_match_found),
        .lmt_match_addr(lmt_tcam_match_addr),
        
        // PMT pool side
        .pmt_wr_en(tcam_pmt_wr_en),
        .pmt_wr_addr(tcam_pmt_wr_addr),
        .pmt_wr_data(tcam_pmt_wr_data),
        .pmt_wr_mask(tcam_pmt_wr_mask),
        
        .pmt_rd_en(),
        .pmt_rd_addr(),
        .pmt_rd_data({NUM_PMTS_TCAM*PMT_WIDTH{1'b0}}),
        .pmt_rd_valid({NUM_PMTS_TCAM{1'b0}}),
        
        .pmt_search_en(tcam_pmt_search_en),
        .pmt_search_key(tcam_pmt_search_key),
        .pmt_matchlines(tcam_pmt_matchlines),
        .pmt_match_found(tcam_pmt_match_found),
        .pmt_match_addr(tcam_pmt_match_addr)
    );
    
    // ========================================================================
    // PMT Pool - Physical Memory (TCAM)
    // ========================================================================
    pmt_pool #(
        .NUM_PMTS(NUM_PMTS_TCAM),
        .DATA_WIDTH(PMT_WIDTH),
        .ADDR_WIDTH(PMT_ADDR_WIDTH),
        .DEPTH(PMT_DEPTH),
        .PMT_TYPE("TCAM"),
        .PMT_ID_WIDTH(PMT_ID_WIDTH)
    ) tcam_pmt_pool (
        .clk(clk),
        .rst_n(rst_n),
        
        .pmt_used(tcam_pmt_used),
        .pmt_lmt_id(tcam_pmt_lmt_id),
        
        // Write (simplified - should have proper ID routing)
        .wr_en(|tcam_pmt_wr_en),
        .wr_pmt_id({PMT_ID_WIDTH{1'b0}}),
        .wr_addr(tcam_pmt_wr_addr[PMT_ADDR_WIDTH-1:0]),
        .wr_data(tcam_pmt_wr_data[PMT_WIDTH-1:0]),
        .wr_mask(tcam_pmt_wr_mask[PMT_WIDTH-1:0]),
        
        .rd_en({NUM_PMTS_TCAM{1'b0}}),
        .rd_addr({NUM_PMTS_TCAM*PMT_ADDR_WIDTH{1'b0}}),
        .rd_data(),
        .rd_valid(),
        
        .search_en(tcam_pmt_search_en),
        .search_key(tcam_pmt_search_key),
        .matchlines(tcam_pmt_matchlines),
        .match_found(tcam_pmt_match_found),
        .match_addr(tcam_pmt_match_addr),
        
        .entry_valid()
    );
    
    // ========================================================================
    // Pipeline Stages - MAUs with LMTs
    // ========================================================================
    
    // Stage 0 input
    assign stage_valid[0] = pkt_valid_in;
    assign stage_phv[0 +: PHV_WIDTH] = pkt_phv_in;
    assign stage_umt_id[0 +: 8] = pkt_umt_id_in;
    
    genvar s;
    generate
        for (s = 0; s < NUM_STAGES; s = s + 1) begin : gen_mau_stages
            
            match_action_unit #(
                .STAGE_ID(s),
                .PHV_WIDTH(PHV_WIDTH),
                .MAX_KEY_WIDTH(MAX_KEY_WIDTH),
                .MAX_DEPTH(MAX_DEPTH),
                .MAX_DEPTH_BITS(MAX_DEPTH_BITS),
                .PMT_WIDTH(PMT_WIDTH),
                .PMT_DEPTH(PMT_DEPTH),
                .PMT_ADDR_WIDTH(PMT_ADDR_WIDTH),
                .MAX_PMTS_PER_LMT(MAX_PMTS_PER_LMT)
            ) mau (
                .clk(clk),
                .rst_n(rst_n),
                
                // Configuration
                .key_field_select(key_field_select[s*4 +: 4]),
                .key_field_offset(key_field_offset[s*16 +: 16]),
                .key_field_length(key_field_length[s*8 +: 8]),
                
                .lmt_used(lmt_used[s]),
                .lmt_uid(lmt_uid[s*8 +: 8]),
                .lmt_internal_id(lmt_internal_id[s*8 +: 8]),
                .lmt_status_flag(lmt_status_flag[s*2 +: 2]),
                .lmt_width_gear(lmt_width_gear[s*2 +: 2]),
                .lmt_depth_gear(lmt_depth_gear[s*3 +: 3]),
                
                // Pipeline input
                .pipe_valid_in(stage_valid[s]),
                .pipe_phv_in((s == 0) ? pkt_phv_in : stage_phv[(s-1)*PHV_WIDTH +: PHV_WIDTH]),
                .pipe_umt_id_in((s == 0) ? pkt_umt_id_in : stage_umt_id[(s-1)*8 +: 8]),
                .pipe_match_found_in((s == 0) ? 1'b0 : stage_match_found[s-1]),
                .pipe_match_addr_in((s == 0) ? {MAX_DEPTH_BITS{1'b0}} : 
                                     stage_match_addr[(s-1)*MAX_DEPTH_BITS +: MAX_DEPTH_BITS]),
                .pipe_metadata_in((s == 0) ? 64'd0 : stage_metadata[(s-1)*64 +: 64]),
                
                // Pipeline output
                .pipe_valid_out(stage_valid[s+1]),
                .pipe_phv_out(stage_phv[s*PHV_WIDTH +: PHV_WIDTH]),
                .pipe_umt_id_out(stage_umt_id[s*8 +: 8]),
                .pipe_match_found_out(stage_match_found[s]),
                .pipe_match_addr_out(stage_match_addr[s*MAX_DEPTH_BITS +: MAX_DEPTH_BITS]),
                .pipe_metadata_out(stage_metadata[s*64 +: 64]),
                .pipe_action_out(stage_action[s*8 +: 8]),
                
                // Crossbar interface
                .xbar_wr_en(lmt_tcam_wr_en[s]),
                .xbar_wr_addr(lmt_tcam_wr_addr[s*MAX_DEPTH_BITS +: MAX_DEPTH_BITS]),
                .xbar_wr_data(lmt_tcam_wr_data[s*MAX_KEY_WIDTH +: MAX_KEY_WIDTH]),
                .xbar_wr_mask(lmt_tcam_wr_mask[s*MAX_KEY_WIDTH +: MAX_KEY_WIDTH]),
                
                .xbar_rd_en(),
                .xbar_rd_addr(),
                .xbar_rd_data({MAX_KEY_WIDTH{1'b0}}),
                .xbar_rd_valid(1'b0),
                
                .xbar_search_en(lmt_tcam_search_en[s]),
                .xbar_search_key(lmt_tcam_search_key[s*MAX_KEY_WIDTH +: MAX_KEY_WIDTH]),
                .xbar_matchlines(lmt_tcam_matchlines[s*MAX_DEPTH +: MAX_DEPTH]),
                .xbar_match_found(lmt_tcam_match_found[s]),
                .xbar_match_addr(lmt_tcam_match_addr[s*MAX_DEPTH_BITS +: MAX_DEPTH_BITS]),
                
                // Entry write
                .entry_wr_en(lmt_entry_valid && (lmt_entry_id == s)),
                .entry_wr_addr(lmt_entry_addr),
                .entry_wr_data(lmt_entry_data),
                .entry_wr_mask(lmt_entry_mask)
            );
        end
    endgenerate
    
    // ========================================================================
    // Pipeline Output (from last stage)
    // ========================================================================
    assign pkt_valid_out = stage_valid[NUM_STAGES];
    assign pkt_phv_out = stage_phv[(NUM_STAGES-1)*PHV_WIDTH +: PHV_WIDTH];
    assign pkt_match_found_out = stage_match_found[NUM_STAGES-1];
    assign pkt_match_addr_out = stage_match_addr[(NUM_STAGES-1)*MAX_DEPTH_BITS +: MAX_DEPTH_BITS];
    assign pkt_action_out = {56'd0, stage_action[(NUM_STAGES-1)*8 +: 8]};
    
    // ========================================================================
    // Statistics Monitor
    // ========================================================================
    lmt_status_monitor #(
        .NUM_LMTS(MAX_LMTS)
    ) stats_monitor (
        .clk(clk),
        .rst_n(rst_n),
        
        .lmt_search_en(lmt_tcam_search_en),
        .lmt_match_found(lmt_tcam_match_found),
        .lmt_used(lmt_used),
        
        .total_searches(total_searches),
        .total_matches(total_matches),
        .total_misses(),
        .per_lmt_searches(),
        .per_lmt_matches()
    );

endmodule