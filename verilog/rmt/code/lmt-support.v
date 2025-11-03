`timescale 1ns/1ps

module match_action_unit #(
    parameter STAGE_ID = 0,
    parameter PHV_WIDTH = 512,
    parameter MAX_KEY_WIDTH = 64,
    parameter MAX_DEPTH = 256,
    parameter MAX_DEPTH_BITS = 8,
    parameter PMT_WIDTH = 32,
    parameter PMT_DEPTH = 32,
    parameter PMT_ADDR_WIDTH = 5,
    parameter MAX_PMTS_PER_LMT = 8
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    // ========================================================================
    // Configuration Interface
    // ========================================================================
    // Key Extractor Configuration
    input  wire [3:0]                key_field_select,
    input  wire [15:0]               key_field_offset,
    input  wire [7:0]                key_field_length,
    
    // LMT Configuration
    input  wire                      lmt_used,
    input  wire [7:0]                lmt_uid,
    input  wire [7:0]                lmt_internal_id,
    input  wire [1:0]                lmt_status_flag,
    input  wire [1:0]                lmt_width_gear,
    input  wire [2:0]                lmt_depth_gear,
    
    // ========================================================================
    // Pipeline Interface
    // ========================================================================
    // Input
    input  wire                      pipe_valid_in,
    input  wire [PHV_WIDTH-1:0]      pipe_phv_in,
    input  wire [7:0]                pipe_umt_id_in,
    input  wire                      pipe_match_found_in,
    input  wire [MAX_DEPTH_BITS-1:0] pipe_match_addr_in,
    input  wire [63:0]               pipe_metadata_in,
    
    // Output
    output wire                      pipe_valid_out,
    output wire [PHV_WIDTH-1:0]      pipe_phv_out,
    output wire [7:0]                pipe_umt_id_out,
    output wire                      pipe_match_found_out,
    output wire [MAX_DEPTH_BITS-1:0] pipe_match_addr_out,
    output wire [63:0]               pipe_metadata_out,
    output wire [7:0]                pipe_action_out,
    
    // ========================================================================
    // Crossbar Interface to PMT Pool
    // ========================================================================
    output wire                      xbar_wr_en,
    output wire [MAX_DEPTH_BITS-1:0] xbar_wr_addr,
    output wire [MAX_KEY_WIDTH-1:0]  xbar_wr_data,
    output wire [MAX_KEY_WIDTH-1:0]  xbar_wr_mask,
    
    output wire                      xbar_rd_en,
    output wire [MAX_DEPTH_BITS-1:0] xbar_rd_addr,
    input  wire [MAX_KEY_WIDTH-1:0]  xbar_rd_data,
    input  wire                      xbar_rd_valid,
    
    output wire                      xbar_search_en,
    output wire [MAX_KEY_WIDTH-1:0]  xbar_search_key,
    input  wire [MAX_DEPTH-1:0]      xbar_matchlines,
    input  wire                      xbar_match_found,
    input  wire [MAX_DEPTH_BITS-1:0] xbar_match_addr,
    
    // ========================================================================
    // Entry Write Interface
    // ========================================================================
    input  wire                      entry_wr_en,
    input  wire [MAX_DEPTH_BITS-1:0] entry_wr_addr,
    input  wire [MAX_KEY_WIDTH-1:0]  entry_wr_data,
    input  wire [MAX_KEY_WIDTH-1:0]  entry_wr_mask
);

    // ========================================================================
    // Internal Signals
    // ========================================================================
    wire                      key_valid;
    wire [MAX_KEY_WIDTH-1:0]  extracted_key;
    
    wire                      lmt_valid_out;
    wire [7:0]                lmt_umt_id_out;
    wire                      lmt_match_found;
    wire [MAX_DEPTH_BITS-1:0] lmt_match_addr;
    wire [63:0]               lmt_metadata;
    
    wire [7:0]                action_opcode;
    
    // PHV pipeline registers (pass through MAU)
    reg  [PHV_WIDTH-1:0]      phv_pipe_s1, phv_pipe_s2, phv_pipe_s3, phv_pipe_s4;
    
    // ========================================================================
    // Key Extractor
    // ========================================================================
    key_extractor #(
        .PHV_WIDTH(PHV_WIDTH),
        .MAX_KEY_WIDTH(MAX_KEY_WIDTH),
        .NUM_FIELDS(8)
    ) key_ext_inst (
        .clk(clk),
        .rst_n(rst_n),
        .field_select(key_field_select),
        .field_offset(key_field_offset),
        .field_length(key_field_length),
        .phv_valid(pipe_valid_in),
        .phv_data(pipe_phv_in),
        .key_valid(key_valid),
        .key_data(extracted_key)
    );
    
    // ========================================================================
    // Logical Match Table
    // ========================================================================
    logical_match_table #(
        .LMT_ID(STAGE_ID),
        .MAX_WIDTH(MAX_KEY_WIDTH),
        .MAX_DEPTH(MAX_DEPTH),
        .MAX_DEPTH_BITS(MAX_DEPTH_BITS),
        .PMT_WIDTH(PMT_WIDTH),
        .PMT_DEPTH(PMT_DEPTH),
        .PMT_ADDR_WIDTH(PMT_ADDR_WIDTH),
        .MAX_PMTS_PER_LMT(MAX_PMTS_PER_LMT),
        .MATCH_TYPE("TCAM")
    ) lmt_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        // Configuration
        .lmt_used(lmt_used),
        .lmt_uid(lmt_uid),
        .lmt_internal_id(lmt_internal_id),
        .lmt_status_flag(lmt_status_flag),
        .lmt_width_gear(lmt_width_gear),
        .lmt_depth_gear(lmt_depth_gear),
        
        // Pipeline
        .pipe_valid_in(key_valid),
        .pipe_search_key(extracted_key),
        .pipe_umt_id_in(pipe_umt_id_in),
        .pipe_match_found_in(pipe_match_found_in),
        .pipe_match_addr_in(pipe_match_addr_in),
        .pipe_metadata_in(pipe_metadata_in),
        
        .pipe_valid_out(lmt_valid_out),
        .pipe_umt_id_out(lmt_umt_id_out),
        .pipe_match_found_out(lmt_match_found),
        .pipe_match_addr_out(lmt_match_addr),
        .pipe_metadata_out(lmt_metadata),
        
        // Crossbar
        .xbar_wr_en(xbar_wr_en),
        .xbar_wr_addr(xbar_wr_addr),
        .xbar_wr_data(xbar_wr_data),
        .xbar_wr_mask(xbar_wr_mask),
        
        .xbar_rd_en(xbar_rd_en),
        .xbar_rd_addr(xbar_rd_addr),
        .xbar_rd_data(xbar_rd_data),
        .xbar_rd_valid(xbar_rd_valid),
        
        .xbar_search_en(xbar_search_en),
        .xbar_search_key(xbar_search_key),
        .xbar_matchlines(xbar_matchlines),
        .xbar_match_found(xbar_match_found),
        .xbar_match_addr(xbar_match_addr),
        
        // Entry Write
        .entry_wr_en(entry_wr_en),
        .entry_wr_addr(entry_wr_addr),
        .entry_wr_data(entry_wr_data),
        .entry_wr_mask(entry_wr_mask)
    );
    
    // ========================================================================
    // Action Engine
    // Extracts action opcode from metadata
    // ========================================================================
    action_engine #(
        .METADATA_WIDTH(64),
        .ACTION_WIDTH(8)
    ) action_eng_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(lmt_valid_out),
        .match_found(lmt_match_found),
        .metadata_in(lmt_metadata),
        .action_opcode(action_opcode)
    );
    
    // ========================================================================
    // PHV Pipeline (pass through with same latency as LMT)
    // ========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phv_pipe_s1 <= {PHV_WIDTH{1'b0}};
            phv_pipe_s2 <= {PHV_WIDTH{1'b0}};
            phv_pipe_s3 <= {PHV_WIDTH{1'b0}};
            phv_pipe_s4 <= {PHV_WIDTH{1'b0}};
        end else begin
            phv_pipe_s1 <= pipe_phv_in;
            phv_pipe_s2 <= phv_pipe_s1;
            phv_pipe_s3 <= phv_pipe_s2;
            phv_pipe_s4 <= phv_pipe_s3;
        end
    end
    
    // ========================================================================
    // Output Assignment
    // ========================================================================
    assign pipe_valid_out      = lmt_valid_out;
    assign pipe_phv_out        = phv_pipe_s4;
    assign pipe_umt_id_out     = lmt_umt_id_out;
    assign pipe_match_found_out = lmt_match_found;
    assign pipe_match_addr_out = lmt_match_addr;
    assign pipe_metadata_out   = lmt_metadata;
    assign pipe_action_out     = action_opcode;

endmodule


// ============================================================================
// Action Engine
// Decodes action from metadata and can execute simple actions
// ============================================================================

module action_engine #(
    parameter METADATA_WIDTH = 64,
    parameter ACTION_WIDTH = 8
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    input  wire                      valid_in,
    input  wire                      match_found,
    input  wire [METADATA_WIDTH-1:0] metadata_in,
    
    output reg  [ACTION_WIDTH-1:0]   action_opcode
);

    // Action opcodes (example)
    localparam ACTION_DROP     = 8'h00;
    localparam ACTION_FORWARD  = 8'h01;
    localparam ACTION_MODIFY   = 8'h02;
    localparam ACTION_REDIRECT = 8'h03;
    localparam ACTION_COPY     = 8'h04;
    localparam ACTION_NOP      = 8'hFF;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            action_opcode <= ACTION_NOP;
        end else begin
            if (valid_in && match_found) begin
                // Extract action from metadata (lower 8 bits in this example)
                action_opcode <= metadata_in[7:0];
            end else begin
                action_opcode <= ACTION_NOP;
            end
        end
    end

endmodule


// ============================================================================
// Stage Bypass Controller
// Allows skipping unused stages to reduce latency
// ============================================================================

module stage_bypass_controller #(
    parameter NUM_STAGES = 5
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    // Configuration: which stages are in use
    input  wire [NUM_STAGES-1:0]     stage_used,
    
    // Pipeline control
    input  wire                      pipe_valid_in,
    input  wire [7:0]                pipe_umt_id_in,
    
    // Per-stage bypass signals
    output reg  [NUM_STAGES-1:0]     stage_bypass_en
);

    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_bypass_en <= {NUM_STAGES{1'b0}};
        end else begin
            for (i = 0; i < NUM_STAGES; i = i + 1) begin
                // Bypass stage if not used
                stage_bypass_en[i] <= !stage_used[i];
            end
        end
    end

endmodule


// ============================================================================
// PHV (Packet Header Vector) Structure
// Defines packet header layout for extraction
// ============================================================================

module phv_parser #(
    parameter DATA_WIDTH = 512,
    parameter PHV_WIDTH = 512
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    // Input: Raw packet data
    input  wire                      pkt_valid,
    input  wire [DATA_WIDTH-1:0]     pkt_data,
    input  wire                      pkt_sop,      // Start of packet
    input  wire                      pkt_eop,      // End of packet
    
    // Output: Parsed PHV
    output reg                       phv_valid,
    output reg  [PHV_WIDTH-1:0]      phv_data
);

    // PHV field offsets (example for Ethernet/IPv4)
    // [47:0]     - Source MAC
    // [95:48]    - Dest MAC
    // [111:96]   - EtherType/VLAN
    // [143:112]  - Source IPv4
    // [175:144]  - Dest IPv4
    // [191:176]  - Source Port
    // [207:192]  - Dest Port
    // [215:208]  - Protocol
    
    reg [1:0] parse_state;
    localparam IDLE = 2'd0, HEADER = 2'd1, DONE = 2'd2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phv_valid <= 1'b0;
            phv_data <= {PHV_WIDTH{1'b0}};
            parse_state <= IDLE;
        end else begin
            case (parse_state)
                IDLE: begin
                    phv_valid <= 1'b0;
                    if (pkt_valid && pkt_sop) begin
                        // First cycle: capture headers
                        phv_data <= pkt_data;
                        parse_state <= HEADER;
                    end
                end
                
                HEADER: begin
                    // Could parse additional cycles if needed
                    phv_valid <= 1'b1;
                    parse_state <= DONE;
                end
                
                DONE: begin
                    phv_valid <= 1'b1;
                    if (pkt_eop) begin
                        parse_state <= IDLE;
                    end
                end
                
                default: parse_state <= IDLE;
            endcase
        end
    end

endmodule


// ============================================================================
// LMT Status Monitor
// Monitors LMT usage and performance statistics
// ============================================================================

module lmt_status_monitor #(
    parameter NUM_LMTS = 5
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    // LMT activity signals
    input  wire [NUM_LMTS-1:0]       lmt_search_en,
    input  wire [NUM_LMTS-1:0]       lmt_match_found,
    input  wire [NUM_LMTS-1:0]       lmt_used,
    
    // Statistics outputs
    output reg  [31:0]               total_searches,
    output reg  [31:0]               total_matches,
    output reg  [31:0]               total_misses,
    output reg  [NUM_LMTS*32-1:0]    per_lmt_searches,
    output reg  [NUM_LMTS*32-1:0]    per_lmt_matches
);

    integer i;
    reg [31:0] lmt_search_cnt [0:NUM_LMTS-1];
    reg [31:0] lmt_match_cnt [0:NUM_LMTS-1];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            total_searches <= 32'd0;
            total_matches <= 32'd0;
            total_misses <= 32'd0;
            
            for (i = 0; i < NUM_LMTS; i = i + 1) begin
                lmt_search_cnt[i] <= 32'd0;
                lmt_match_cnt[i] <= 32'd0;
            end
        end else begin
            // Count total searches
            if (|lmt_search_en) begin
                total_searches <= total_searches + 1;
            end
            
            // Count total matches and misses
            if (|lmt_match_found) begin
                total_matches <= total_matches + 1;
            end else if (|lmt_search_en) begin
                total_misses <= total_misses + 1;
            end
            
            // Per-LMT statistics
            for (i = 0; i < NUM_LMTS; i = i + 1) begin
                if (lmt_search_en[i]) begin
                    lmt_search_cnt[i] <= lmt_search_cnt[i] + 1;
                end
                if (lmt_match_found[i]) begin
                    lmt_match_cnt[i] <= lmt_match_cnt[i] + 1;
                end
            end
        end
    end
    
    // Pack statistics into output arrays
    always @(*) begin
        for (i = 0; i < NUM_LMTS; i = i + 1) begin
            per_lmt_searches[i*32 +: 32] = lmt_search_cnt[i];
            per_lmt_matches[i*32 +: 32] = lmt_match_cnt[i];
        end
    end

endmodule