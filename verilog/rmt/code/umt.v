`timescale 1ns / 1ps

module umt_config_interface #(
    parameter MAX_UMTS = 5,
    parameter MAX_WIDTH = 64,
    parameter MAX_DEPTH = 512,
    parameter UMT_ID_WIDTH = 3
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    // ========================================================================
    // User Configuration Interface (from Control Plane)
    // ========================================================================
    input  wire                      cfg_valid,
    input  wire                      cfg_wr_en,
    input  wire [UMT_ID_WIDTH-1:0]   cfg_umt_id,
    input  wire [15:0]               cfg_umt_width,      // User desired width
    input  wire [15:0]               cfg_umt_depth,      // User desired depth
    input  wire                      cfg_umt_type,       // 0=TCAM, 1=SRAM
    
    // ========================================================================
    // Configuration Storage Outputs
    // ========================================================================
    output reg  [MAX_UMTS-1:0]       umt_valid,
    output reg  [MAX_UMTS*16-1:0]    umt_width,
    output reg  [MAX_UMTS*16-1:0]    umt_depth,
    output reg  [MAX_UMTS-1:0]       umt_type,
    
    // ========================================================================
    // Status
    // ========================================================================
    output reg                       cfg_error,
    output reg  [7:0]                cfg_error_code
);

    // Error codes
    localparam ERR_NONE          = 8'h00;
    localparam ERR_INVALID_ID    = 8'h01;
    localparam ERR_WIDTH_TOO_BIG = 8'h02;
    localparam ERR_DEPTH_TOO_BIG = 8'h03;
    localparam ERR_ZERO_SIZE     = 8'h04;
    
    integer i;
    
    // UMT configuration storage
    reg                  umt_valid_reg [0:MAX_UMTS-1];
    reg [15:0]           umt_width_reg [0:MAX_UMTS-1];
    reg [15:0]           umt_depth_reg [0:MAX_UMTS-1];
    reg                  umt_type_reg [0:MAX_UMTS-1];
    
    // ========================================================================
    // Configuration Write Logic
    // ========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cfg_error <= 1'b0;
            cfg_error_code <= ERR_NONE;
            
            for (i = 0; i < MAX_UMTS; i = i + 1) begin
                umt_valid_reg[i] <= 1'b0;
                umt_width_reg[i] <= 16'd0;
                umt_depth_reg[i] <= 16'd0;
                umt_type_reg[i] <= 1'b0;
            end
        end else begin
            cfg_error <= 1'b0;
            cfg_error_code <= ERR_NONE;
            
            if (cfg_valid && cfg_wr_en) begin
                // Validate configuration
                if (cfg_umt_id >= MAX_UMTS) begin
                    cfg_error <= 1'b1;
                    cfg_error_code <= ERR_INVALID_ID;
                end else if (cfg_umt_width > MAX_WIDTH) begin
                    cfg_error <= 1'b1;
                    cfg_error_code <= ERR_WIDTH_TOO_BIG;
                end else if (cfg_umt_depth > MAX_DEPTH) begin
                    cfg_error <= 1'b1;
                    cfg_error_code <= ERR_DEPTH_TOO_BIG;
                end else if (cfg_umt_width == 0 || cfg_umt_depth == 0) begin
                    cfg_error <= 1'b1;
                    cfg_error_code <= ERR_ZERO_SIZE;
                end else begin
                    // Valid configuration - store it
                    umt_valid_reg[cfg_umt_id] <= 1'b1;
                    umt_width_reg[cfg_umt_id] <= cfg_umt_width;
                    umt_depth_reg[cfg_umt_id] <= cfg_umt_depth;
                    umt_type_reg[cfg_umt_id] <= cfg_umt_type;
                end
            end
        end
    end
    
    // ========================================================================
    // Pack Configuration Arrays
    // ========================================================================
    always @(*) begin
        for (i = 0; i < MAX_UMTS; i = i + 1) begin
            umt_valid[i] = umt_valid_reg[i];
            umt_width[i*16 +: 16] = umt_width_reg[i];
            umt_depth[i*16 +: 16] = umt_depth_reg[i];
            umt_type[i] = umt_type_reg[i];
        end
    end

endmodule


module umt_to_lmt_mapper #(
    parameter MAX_UMTS = 5,
    parameter MAX_LMTS = 5,
    parameter PMT_WIDTH = 32,           // Pw
    parameter PMT_DEPTH = 32,           // Pd
    parameter MAX_PMTS_PER_LMT = 8      // P
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    // ========================================================================
    // UMT Configuration Input
    // ========================================================================
    input  wire                      map_trigger,        // Start mapping
    input  wire [MAX_UMTS-1:0]       umt_valid,
    input  wire [MAX_UMTS*16-1:0]    umt_width,
    input  wire [MAX_UMTS*16-1:0]    umt_depth,
    
    // ========================================================================
    // ULSS Output (UMT-to-LMT State Structure)
    // ========================================================================
    output reg                       map_done,
    output reg                       map_error,
    output reg  [7:0]                map_error_code,
    
    output reg  [MAX_LMTS-1:0]       lmt_used,
    output reg  [MAX_LMTS*8-1:0]     lmt_uid,            // Which UMT
    output reg  [MAX_LMTS*8-1:0]     lmt_internal_id,    // Position in UMT
    output reg  [MAX_LMTS*2-1:0]     lmt_status_flag,    // Single/Start/Mid/End
    output reg  [MAX_LMTS*2-1:0]     lmt_width_gear,     // Width configuration
    output reg  [MAX_LMTS*3-1:0]     lmt_depth_gear,     // Depth configuration
    
    output reg  [7:0]                total_lmts_used,
    output reg  [15:0]               total_pmts_needed
);

    // Error codes
    localparam ERR_NONE           = 8'h00;
    localparam ERR_TOO_MANY_LMTS  = 8'h01;
    localparam ERR_TOO_MANY_PMTS  = 8'h02;
    localparam ERR_WIDTH_UNSUP    = 8'h03;
    
    // Status flags
    localparam STATUS_SINGLE = 2'b00;
    localparam STATUS_START  = 2'b01;
    localparam STATUS_MIDDLE = 2'b10;
    localparam STATUS_END    = 2'b11;
    
    // FSM states
    localparam IDLE       = 3'd0;
    localparam ANALYZE    = 3'd1;
    localparam MAP_UMTS   = 3'd2;
    localparam CHECK_RES  = 3'd3;
    localparam DONE       = 3'd4;
    
    reg [2:0] state;
    reg [3:0] umt_idx;
    reg [3:0] lmt_idx;
    
    // Temporary storage
    reg [7:0]  lmt_count;
    reg [15:0] pmt_count;
    reg [15:0] umt_w, umt_d;
    reg [7:0]  num_lmts_for_umt;
    reg [15:0] num_pmts_for_umt;
    
    // Working arrays
    reg                  lmt_used_array [0:MAX_LMTS-1];
    reg [7:0]            lmt_uid_array [0:MAX_LMTS-1];
    reg [7:0]            lmt_iid_array [0:MAX_LMTS-1];
    reg [1:0]            lmt_sf_array [0:MAX_LMTS-1];
    reg [1:0]            lmt_wg_array [0:MAX_LMTS-1];
    reg [2:0]            lmt_dg_array [0:MAX_LMTS-1];
    
    integer i, j;
    
    // ========================================================================
    // Helper Functions
    // ========================================================================
    
    // Calculate width gear (0 = 1*Pw, 1 = 2*Pw)
    function [1:0] calc_width_gear;
        input [15:0] width;
        begin
            if (width <= PMT_WIDTH)
                calc_width_gear = 2'd0;  // 1x width
            else if (width <= 2*PMT_WIDTH)
                calc_width_gear = 2'd1;  // 2x width
            else
                calc_width_gear = 2'd3;  // Invalid
        end
    endfunction
    
    // Calculate depth gear (0-7 for 1x to 8x)
    function [2:0] calc_depth_gear;
        input [15:0] depth;
        begin
            if (depth <= PMT_DEPTH)
                calc_depth_gear = 3'd0;  // 1x
            else if (depth <= 2*PMT_DEPTH)
                calc_depth_gear = 3'd1;  // 2x
            else if (depth <= 4*PMT_DEPTH)
                calc_depth_gear = 3'd2;  // 4x
            else if (depth <= 8*PMT_DEPTH)
                calc_depth_gear = 3'd3;  // 8x
            else
                calc_depth_gear = 3'd7;  // Invalid
        end
    endfunction
    
    // Calculate number of PMTs needed
    function [15:0] calc_pmts_needed;
        input [15:0] width;
        input [15:0] depth;
        reg [15:0] width_blocks, depth_blocks;
        begin
            width_blocks = (width + PMT_WIDTH - 1) / PMT_WIDTH;
            depth_blocks = (depth + PMT_DEPTH - 1) / PMT_DEPTH;
            calc_pmts_needed = width_blocks * depth_blocks;
        end
    endfunction
    
    // Calculate number of LMTs needed
    function [7:0] calc_lmts_needed;
        input [15:0] width;
        input [15:0] depth;
        reg [15:0] pmts;
        begin
            pmts = calc_pmts_needed(width, depth);
            // Each LMT can use up to MAX_PMTS_PER_LMT PMTs
            calc_lmts_needed = (pmts + MAX_PMTS_PER_LMT - 1) / MAX_PMTS_PER_LMT;
        end
    endfunction
    
    // ========================================================================
    // Mapping State Machine
    // ========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            map_done <= 1'b0;
            map_error <= 1'b0;
            map_error_code <= ERR_NONE;
            umt_idx <= 0;
            lmt_idx <= 0;
            lmt_count <= 0;
            pmt_count <= 0;
            total_lmts_used <= 0;
            total_pmts_needed <= 0;
            
            for (i = 0; i < MAX_LMTS; i = i + 1) begin
                lmt_used_array[i] <= 1'b0;
                lmt_uid_array[i] <= 8'd0;
                lmt_iid_array[i] <= 8'd0;
                lmt_sf_array[i] <= 2'd0;
                lmt_wg_array[i] <= 2'd0;
                lmt_dg_array[i] <= 3'd0;
            end
            
        end else begin
            case (state)
                // ============================================================
                // IDLE: Wait for mapping trigger
                // ============================================================
                IDLE: begin
                    map_done <= 1'b0;
                    map_error <= 1'b0;
                    map_error_code <= ERR_NONE;
                    
                    if (map_trigger) begin
                        umt_idx <= 0;
                        lmt_idx <= 0;
                        lmt_count <= 0;
                        pmt_count <= 0;
                        state <= ANALYZE;
                    end
                end
                
                // ============================================================
                // ANALYZE: Count total resources needed
                // ============================================================
                ANALYZE: begin
                    if (umt_idx < MAX_UMTS) begin
                        if (umt_valid[umt_idx]) begin
                            umt_w = umt_width[umt_idx*16 +: 16];
                            umt_d = umt_depth[umt_idx*16 +: 16];
                            
                            // Calculate resources for this UMT
                            num_lmts_for_umt = calc_lmts_needed(umt_w, umt_d);
                            num_pmts_for_umt = calc_pmts_needed(umt_w, umt_d);
                            
                            lmt_count <= lmt_count + num_lmts_for_umt;
                            pmt_count <= pmt_count + num_pmts_for_umt;
                        end
                        umt_idx <= umt_idx + 1;
                    end else begin
                        total_lmts_used <= lmt_count;
                        total_pmts_needed <= pmt_count;
                        umt_idx <= 0;
                        lmt_idx <= 0;
                        state <= CHECK_RES;
                    end
                end
                
                // ============================================================
                // CHECK_RES: Verify resources don't exceed limits
                // ============================================================
                CHECK_RES: begin
                    if (lmt_count > MAX_LMTS) begin
                        map_error <= 1'b1;
                        map_error_code <= ERR_TOO_MANY_LMTS;
                        state <= DONE;
                    end else if (pmt_count > (MAX_LMTS * MAX_PMTS_PER_LMT)) begin
                        map_error <= 1'b1;
                        map_error_code <= ERR_TOO_MANY_PMTS;
                        state <= DONE;
                    end else begin
                        state <= MAP_UMTS;
                    end
                end
                
                // ============================================================
                // MAP_UMTS: Allocate LMTs to each UMT
                // ============================================================
                MAP_UMTS: begin
                    if (umt_idx < MAX_UMTS) begin
                        if (umt_valid[umt_idx]) begin
                            umt_w = umt_width[umt_idx*16 +: 16];
                            umt_d = umt_depth[umt_idx*16 +: 16];
                            
                            num_lmts_for_umt = calc_lmts_needed(umt_w, umt_d);
                            
                            // Validate width is supported
                            if (calc_width_gear(umt_w) == 2'd3) begin
                                map_error <= 1'b1;
                                map_error_code <= ERR_WIDTH_UNSUP;
                                state <= DONE;
                            end else begin
                                // Allocate LMTs for this UMT
                                for (j = 0; j < num_lmts_for_umt && lmt_idx < MAX_LMTS; j = j + 1) begin
                                    lmt_used_array[lmt_idx + j] <= 1'b1;
                                    lmt_uid_array[lmt_idx + j] <= umt_idx[7:0];
                                    lmt_iid_array[lmt_idx + j] <= j[7:0];
                                    lmt_wg_array[lmt_idx + j] <= calc_width_gear(umt_w);
                                    
                                    // Calculate depth for each LMT in cascade
                                    if (num_lmts_for_umt == 1) begin
                                        // Single LMT
                                        lmt_sf_array[lmt_idx + j] <= STATUS_SINGLE;
                                        lmt_dg_array[lmt_idx + j] <= calc_depth_gear(umt_d);
                                    end else begin
                                        // Multiple LMTs - divide depth
                                        if (j == 0)
                                            lmt_sf_array[lmt_idx + j] <= STATUS_START;
                                        else if (j == num_lmts_for_umt - 1)
                                            lmt_sf_array[lmt_idx + j] <= STATUS_END;
                                        else
                                            lmt_sf_array[lmt_idx + j] <= STATUS_MIDDLE;
                                        
                                        // Each cascaded LMT gets portion of depth
                                        lmt_dg_array[lmt_idx + j] <= calc_depth_gear(
                                            (umt_d + num_lmts_for_umt - 1) / num_lmts_for_umt
                                        );
                                    end
                                end
                                
                                lmt_idx <= lmt_idx + num_lmts_for_umt;
                            end
                        end
                        umt_idx <= umt_idx + 1;
                    end else begin
                        state <= DONE;
                    end
                end
                
                // ============================================================
                // DONE: Mapping complete
                // ============================================================
                DONE: begin
                    map_done <= 1'b1;
                    // Stay in DONE until next trigger
                    if (!map_trigger) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // ========================================================================
    // Pack Output Arrays
    // ========================================================================
    always @(*) begin
        for (i = 0; i < MAX_LMTS; i = i + 1) begin
            lmt_used[i] = lmt_used_array[i];
            lmt_uid[i*8 +: 8] = lmt_uid_array[i];
            lmt_internal_id[i*8 +: 8] = lmt_iid_array[i];
            lmt_status_flag[i*2 +: 2] = lmt_sf_array[i];
            lmt_width_gear[i*2 +: 2] = lmt_wg_array[i];
            lmt_depth_gear[i*3 +: 3] = lmt_dg_array[i];
        end
    end

endmodule


module umt_entry_manager #(
    parameter MAX_UMTS = 5,
    parameter MAX_LMTS = 5,
    parameter MAX_WIDTH = 64,
    parameter MAX_DEPTH = 512,
    parameter MAX_DEPTH_BITS = 9
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    // ========================================================================
    // UMT Entry Write Interface
    // ========================================================================
    input  wire                      entry_valid,
    input  wire [2:0]                entry_umt_id,
    input  wire [MAX_DEPTH_BITS-1:0] entry_addr,
    input  wire [MAX_WIDTH-1:0]      entry_data,
    input  wire [MAX_WIDTH-1:0]      entry_mask,
    input  wire                      entry_write,      // 1=write, 0=read
    
    // ========================================================================
    // ULSS Configuration (from mapper)
    // ========================================================================
    input  wire [MAX_LMTS-1:0]       lmt_used,
    input  wire [MAX_LMTS*8-1:0]     lmt_uid,
    input  wire [MAX_LMTS*8-1:0]     lmt_internal_id,
    input  wire [MAX_LMTS*16-1:0]    lmt_depth_actual,  // Actual depth per LMT
    
    // ========================================================================
    // LMT Entry Write Output
    // ========================================================================
    output reg                       lmt_entry_valid,
    output reg  [2:0]                lmt_entry_id,
    output reg  [MAX_DEPTH_BITS-1:0] lmt_entry_addr,
    output reg  [MAX_WIDTH-1:0]      lmt_entry_data,
    output reg  [MAX_WIDTH-1:0]      lmt_entry_mask,
    
    // Status
    output reg                       entry_error,
    output reg  [7:0]                entry_error_code
);

    localparam ERR_NONE       = 8'h00;
    localparam ERR_INVALID_UMT = 8'h01;
    localparam ERR_NO_LMT     = 8'h02;
    localparam ERR_ADDR_OOB   = 8'h03;
    
    integer i;
    reg [3:0] target_lmt;
    reg [MAX_DEPTH_BITS-1:0] lmt_addr_offset;
    reg [MAX_DEPTH_BITS-1:0] cumulative_depth;
    reg found_lmt;
    
    // ========================================================================
    // Entry Address Translation
    // ========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lmt_entry_valid <= 1'b0;
            lmt_entry_id <= 3'd0;
            lmt_entry_addr <= {MAX_DEPTH_BITS{1'b0}};
            lmt_entry_data <= {MAX_WIDTH{1'b0}};
            lmt_entry_mask <= {MAX_WIDTH{1'b0}};
            entry_error <= 1'b0;
            entry_error_code <= ERR_NONE;
        end else begin
            lmt_entry_valid <= 1'b0;
            entry_error <= 1'b0;
            entry_error_code <= ERR_NONE;
            
            if (entry_valid) begin
                // Find which LMT(s) belong to this UMT
                found_lmt = 1'b0;
                cumulative_depth = 0;
                
                for (i = 0; i < MAX_LMTS; i = i + 1) begin
                    if (lmt_used[i] && lmt_uid[i*8 +: 8] == entry_umt_id) begin
                        if (!found_lmt && entry_addr >= cumulative_depth && 
                            entry_addr < (cumulative_depth + lmt_depth_actual[i*16 +: 16])) begin
                            // This is the target LMT
                            found_lmt = 1'b1;
                            target_lmt = i[3:0];
                            lmt_addr_offset = entry_addr - cumulative_depth;
                        end
                        cumulative_depth = cumulative_depth + lmt_depth_actual[i*16 +: 16];
                    end
                end
                
                if (found_lmt) begin
                    // Write to target LMT
                    lmt_entry_valid <= 1'b1;
                    lmt_entry_id <= target_lmt[2:0];
                    lmt_entry_addr <= lmt_addr_offset;
                    lmt_entry_data <= entry_data;
                    lmt_entry_mask <= entry_mask;
                end else begin
                    entry_error <= 1'b1;
                    entry_error_code <= ERR_NO_LMT;
                end
            end
        end
    end

endmodule


// ============================================================================
// Complete UMT Top Module - Standalone
// All UMT control plane functionality in one module
// Connects to RMT pipeline top module
// ============================================================================

module umt_top #(
    parameter MAX_UMTS = 5,
    parameter MAX_LMTS = 5,
    parameter MAX_WIDTH = 64,
    parameter MAX_DEPTH = 512,
    parameter PMT_WIDTH = 32,
    parameter PMT_DEPTH = 32,
    parameter MAX_PMTS_PER_LMT = 8
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    // ========================================================================
    // User Configuration Interface
    // ========================================================================
    input  wire                      umt_cfg_valid,
    input  wire                      umt_cfg_wr_en,
    input  wire [2:0]                umt_cfg_id,
    input  wire [15:0]               umt_cfg_width,
    input  wire [15:0]               umt_cfg_depth,
    input  wire                      umt_cfg_type,
    
    input  wire                      umt_map_trigger,
    
    // ========================================================================
    // Entry Management Interface
    // ========================================================================
    input  wire                      entry_valid,
    input  wire [2:0]                entry_umt_id,
    input  wire [8:0]                entry_addr,
    input  wire [MAX_WIDTH-1:0]      entry_data,
    input  wire [MAX_WIDTH-1:0]      entry_mask,
    
    // ========================================================================
    // Output to LMT Layer (ULSS)
    // ========================================================================
    output wire                      map_done,
    output wire                      map_error,
    output wire [MAX_LMTS-1:0]       lmt_used,
    output wire [MAX_LMTS*8-1:0]     lmt_uid,
    output wire [MAX_LMTS*8-1:0]     lmt_internal_id,
    output wire [MAX_LMTS*2-1:0]     lmt_status_flag,
    output wire [MAX_LMTS*2-1:0]     lmt_width_gear,
    output wire [MAX_LMTS*3-1:0]     lmt_depth_gear,
    
    // ========================================================================
    // Output to Entry Installation
    // ========================================================================
    output wire                      lmt_entry_valid,
    output wire [2:0]                lmt_entry_id,
    output wire [8:0]                lmt_entry_addr,
    output wire [MAX_WIDTH-1:0]      lmt_entry_data,
    output wire [MAX_WIDTH-1:0]      lmt_entry_mask,
    
    // ========================================================================
    // Status
    // ========================================================================
    output wire [7:0]                total_lmts_used,
    output wire [15:0]               total_pmts_needed
);

    // ========================================================================
    // Internal Signals
    // ========================================================================
    wire [MAX_UMTS-1:0]       umt_valid;
    wire [MAX_UMTS*16-1:0]    umt_width;
    wire [MAX_UMTS*16-1:0]    umt_depth;
    wire [MAX_UMTS-1:0]       umt_type;
    wire                      cfg_error;
    wire [7:0]                cfg_error_code;
    
    wire [7:0]                map_error_code;
    
    wire [MAX_LMTS*16-1:0]    lmt_depth_actual;
    wire                      entry_error;
    wire [7:0]                entry_error_code;
    
    // ========================================================================
    // UMT Configuration Interface
    // ========================================================================
    umt_config_interface #(
        .MAX_UMTS(MAX_UMTS),
        .MAX_WIDTH(MAX_WIDTH),
        .MAX_DEPTH(MAX_DEPTH),
        .UMT_ID_WIDTH(3)
    ) umt_cfg_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        .cfg_valid(umt_cfg_valid),
        .cfg_wr_en(umt_cfg_wr_en),
        .cfg_umt_id(umt_cfg_id),
        .cfg_umt_width(umt_cfg_width),
        .cfg_umt_depth(umt_cfg_depth),
        .cfg_umt_type(umt_cfg_type),
        
        .umt_valid(umt_valid),
        .umt_width(umt_width),
        .umt_depth(umt_depth),
        .umt_type(umt_type),
        
        .cfg_error(cfg_error),
        .cfg_error_code(cfg_error_code)
    );
    
    // ========================================================================
    // UMT to LMT Mapper
    // ========================================================================
    umt_to_lmt_mapper #(
        .MAX_UMTS(MAX_UMTS),
        .MAX_LMTS(MAX_LMTS),
        .PMT_WIDTH(PMT_WIDTH),
        .PMT_DEPTH(PMT_DEPTH),
        .MAX_PMTS_PER_LMT(MAX_PMTS_PER_LMT)
    ) mapper_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        .map_trigger(umt_map_trigger),
        .umt_valid(umt_valid),
        .umt_width(umt_width),
        .umt_depth(umt_depth),
        
        .map_done(map_done),
        .map_error(map_error),
        .map_error_code(map_error_code),
        
        .lmt_used(lmt_used),
        .lmt_uid(lmt_uid),
        .lmt_internal_id(lmt_internal_id),
        .lmt_status_flag(lmt_status_flag),
        .lmt_width_gear(lmt_width_gear),
        .lmt_depth_gear(lmt_depth_gear),
        
        .total_lmts_used(total_lmts_used),
        .total_pmts_needed(total_pmts_needed)
    );
    
    // ========================================================================
    // Calculate Actual LMT Depths from Depth Gears
    // ========================================================================
    reg [MAX_LMTS*16-1:0] lmt_depth_actual_reg;
    
    integer i;
    always @(*) begin
        for (i = 0; i < MAX_LMTS; i = i + 1) begin
            if (lmt_used[i]) begin
                case (lmt_depth_gear[i*3 +: 3])
                    3'd0: lmt_depth_actual_reg[i*16 +: 16] = PMT_DEPTH;
                    3'd1: lmt_depth_actual_reg[i*16 +: 16] = PMT_DEPTH * 2;
                    3'd2: lmt_depth_actual_reg[i*16 +: 16] = PMT_DEPTH * 4;
                    3'd3: lmt_depth_actual_reg[i*16 +: 16] = PMT_DEPTH * 8;
                    3'd4: lmt_depth_actual_reg[i*16 +: 16] = PMT_DEPTH * 16;
                    3'd5: lmt_depth_actual_reg[i*16 +: 16] = PMT_DEPTH * 32;
                    3'd6: lmt_depth_actual_reg[i*16 +: 16] = PMT_DEPTH * 64;
                    3'd7: lmt_depth_actual_reg[i*16 +: 16] = PMT_DEPTH * 128;
                    default: lmt_depth_actual_reg[i*16 +: 16] = PMT_DEPTH;
                endcase
            end else begin
                lmt_depth_actual_reg[i*16 +: 16] = 16'd0;
            end
        end
    end
    
    assign lmt_depth_actual = lmt_depth_actual_reg;
    
    // ========================================================================
    // UMT Entry Manager
    // ========================================================================
    umt_entry_manager #(
        .MAX_UMTS(MAX_UMTS),
        .MAX_LMTS(MAX_LMTS),
        .MAX_WIDTH(MAX_WIDTH),
        .MAX_DEPTH(MAX_DEPTH),
        .MAX_DEPTH_BITS(9)
    ) entry_mgr_inst (
        .clk(clk),
        .rst_n(rst_n),
        
        .entry_valid(entry_valid),
        .entry_umt_id(entry_umt_id),
        .entry_addr(entry_addr),
        .entry_data(entry_data),
        .entry_mask(entry_mask),
        .entry_write(1'b1),
        
        .lmt_used(lmt_used),
        .lmt_uid(lmt_uid),
        .lmt_internal_id(lmt_internal_id),
        .lmt_depth_actual(lmt_depth_actual),
        
        .lmt_entry_valid(lmt_entry_valid),
        .lmt_entry_id(lmt_entry_id),
        .lmt_entry_addr(lmt_entry_addr),
        .lmt_entry_data(lmt_entry_data),
        .lmt_entry_mask(lmt_entry_mask),
        
        .entry_error(entry_error),
        .entry_error_code(entry_error_code)
    );

endmodule