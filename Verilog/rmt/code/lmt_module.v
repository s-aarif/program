`timescale 1ns/1ps

module logical_match_table #(
    parameter LMT_ID = 0,
    parameter MAX_WIDTH = 64,           // Maximum LMT width (2*Pw)
    parameter MAX_DEPTH = 256,          // Maximum LMT depth (8*Pd)
    parameter MAX_DEPTH_BITS = 8,       // log2(MAX_DEPTH)
    parameter PMT_WIDTH = 32,           // Single PMT width (Pw)
    parameter PMT_DEPTH = 32,           // Single PMT depth (Pd)
    parameter PMT_ADDR_WIDTH = 5,       // log2(PMT_DEPTH)
    parameter MAX_PMTS_PER_LMT = 8,     // Max PMTs this LMT can use (P)
    parameter MATCH_TYPE = "TCAM"       // "SRAM" or "TCAM"
) (
    input  wire                          clk,
    input  wire                          rst_n,
    
    // ========================================================================
    // Configuration Interface (from Control Plane)
    // ========================================================================
    input  wire                          lmt_used,           // Is this LMT in use?
    input  wire [7:0]                    lmt_uid,            // Parent UMT ID
    input  wire [7:0]                    lmt_internal_id,    // Position in UMT
    input  wire [1:0]                    lmt_status_flag,    // 00=single, 01=start, 10=middle, 11=end
    input  wire [1:0]                    lmt_width_gear,     // 0=1*Pw, 1=2*Pw
    input  wire [2:0]                    lmt_depth_gear,     // 0=1*Pd, 1=2*Pd, ..., 7=8*Pd
    
    // ========================================================================
    // Pipeline Input Interface (from previous stage)
    // ========================================================================
    input  wire                          pipe_valid_in,
    input  wire [MAX_WIDTH-1:0]          pipe_search_key,    // Extracted key for this stage
    input  wire [7:0]                    pipe_umt_id_in,     // Which UMT to match
    input  wire                          pipe_match_found_in,// Previous stage found match
    input  wire [MAX_DEPTH_BITS-1:0]     pipe_match_addr_in, // Previous stage match address
    input  wire [63:0]                   pipe_metadata_in,   // Action data from previous stage
    
    // ========================================================================
    // Pipeline Output Interface (to next stage)
    // ========================================================================
    output reg                           pipe_valid_out,
    output reg  [7:0]                    pipe_umt_id_out,
    output reg                           pipe_match_found_out,
    output reg  [MAX_DEPTH_BITS-1:0]     pipe_match_addr_out,
    output reg  [63:0]                   pipe_metadata_out,  // Action data output
    
    // ========================================================================
    // Crossbar Interface to PMT Pool
    // ========================================================================
    // Write Interface
    output wire                          xbar_wr_en,
    output wire [MAX_DEPTH_BITS-1:0]     xbar_wr_addr,       // LMT logical address
    output wire [MAX_WIDTH-1:0]          xbar_wr_data,
    output wire [MAX_WIDTH-1:0]          xbar_wr_mask,       // For TCAM
    
    // Read Interface (for SRAM action data)
    output wire                          xbar_rd_en,
    output wire [MAX_DEPTH_BITS-1:0]     xbar_rd_addr,
    input  wire [MAX_WIDTH-1:0]          xbar_rd_data,
    input  wire                          xbar_rd_valid,
    
    // Search Interface (for TCAM)
    output wire                          xbar_search_en,
    output wire [MAX_WIDTH-1:0]          xbar_search_key,
    input  wire [MAX_DEPTH-1:0]          xbar_matchlines,    // Combined from all PMTs
    input  wire                          xbar_match_found,
    input  wire [MAX_DEPTH_BITS-1:0]     xbar_match_addr,
    
    // ========================================================================
    // Entry Write Interface (from Control Plane)
    // ========================================================================
    input  wire                          entry_wr_en,
    input  wire [MAX_DEPTH_BITS-1:0]     entry_wr_addr,
    input  wire [MAX_WIDTH-1:0]          entry_wr_data,
    input  wire [MAX_WIDTH-1:0]          entry_wr_mask
);

    // ========================================================================
    // Local Parameters and Configuration Decode
    // ========================================================================
    wire [MAX_WIDTH-1:0] lmt_width_actual;
    wire [MAX_DEPTH_BITS-1:0] lmt_depth_actual;
    
    // Decode width gear: 0 -> 1*Pw, 1 -> 2*Pw
    assign lmt_width_actual = (lmt_width_gear == 1'b0) ? PMT_WIDTH : (2 * PMT_WIDTH);
    
    // Decode depth gear: gear value directly maps to multiplier
    assign lmt_depth_actual = PMT_DEPTH << lmt_depth_gear;
    
    // UMT cascade flags
    wire is_umt_single = (lmt_status_flag == 2'b00);
    wire is_umt_start  = (lmt_status_flag == 2'b01);
    wire is_umt_middle = (lmt_status_flag == 2'b10);
    wire is_umt_end    = (lmt_status_flag == 2'b11);
    
    // This LMT should process if:
    // - It's in use
    // - UMT ID matches OR it's receiving cascaded data from previous LMT
    wire lmt_should_process = lmt_used && (pipe_umt_id_in == lmt_uid);
    
    // ========================================================================
    // Stage Control Logic
    // ========================================================================
    // If previous stage found match in same UMT, skip this LMT
    wire skip_this_stage = pipe_match_found_in && (pipe_umt_id_in == lmt_uid) && !is_umt_end;
    
    // This stage should search if it should process and not skip
    wire perform_search = lmt_should_process && pipe_valid_in && !skip_this_stage;
    
    // ========================================================================
    // Entry Write Path (Configuration)
    // ========================================================================
    // Forward write requests to crossbar when this LMT is being configured
    assign xbar_wr_en   = entry_wr_en && lmt_used;
    assign xbar_wr_addr = entry_wr_addr;
    assign xbar_wr_data = entry_wr_data;
    assign xbar_wr_mask = entry_wr_mask;
    
    // ========================================================================
    // Search Path - Pipeline Stage 1: Issue Search
    // ========================================================================
    reg                      search_valid_s1;
    reg  [MAX_WIDTH-1:0]     search_key_s1;
    reg  [7:0]               umt_id_s1;
    reg                      prev_match_found_s1;
    reg  [MAX_DEPTH_BITS-1:0] prev_match_addr_s1;
    reg  [63:0]              metadata_s1;
    reg                      skip_stage_s1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            search_valid_s1      <= 1'b0;
            search_key_s1        <= {MAX_WIDTH{1'b0}};
            umt_id_s1            <= 8'd0;
            prev_match_found_s1  <= 1'b0;
            prev_match_addr_s1   <= {MAX_DEPTH_BITS{1'b0}};
            metadata_s1          <= 64'd0;
            skip_stage_s1        <= 1'b0;
        end else begin
            search_valid_s1      <= pipe_valid_in;
            search_key_s1        <= pipe_search_key;
            umt_id_s1            <= pipe_umt_id_in;
            prev_match_found_s1  <= pipe_match_found_in;
            prev_match_addr_s1   <= pipe_match_addr_in;
            metadata_s1          <= pipe_metadata_in;
            skip_stage_s1        <= skip_this_stage;
        end
    end
    
    // Crossbar search interface
    generate
        if (MATCH_TYPE == "TCAM") begin : gen_tcam_search
            assign xbar_search_en  = perform_search;
            assign xbar_search_key = pipe_search_key;
            assign xbar_rd_en      = 1'b0;
            assign xbar_rd_addr    = {MAX_DEPTH_BITS{1'b0}};
        end else begin : gen_sram_search
            // For SRAM, key is the address
            assign xbar_search_en  = 1'b0;
            assign xbar_search_key = {MAX_WIDTH{1'b0}};
            assign xbar_rd_en      = perform_search;
            assign xbar_rd_addr    = pipe_search_key[MAX_DEPTH_BITS-1:0];
        end
    endgenerate
    
    // ========================================================================
    // Search Path - Pipeline Stage 2: Receive Results
    // ========================================================================
    reg                      search_valid_s2;
    reg  [7:0]               umt_id_s2;
    reg                      prev_match_found_s2;
    reg  [MAX_DEPTH_BITS-1:0] prev_match_addr_s2;
    reg  [63:0]              metadata_s2;
    reg                      skip_stage_s2;
    reg                      this_match_found_s2;
    reg  [MAX_DEPTH_BITS-1:0] this_match_addr_s2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            search_valid_s2      <= 1'b0;
            umt_id_s2            <= 8'd0;
            prev_match_found_s2  <= 1'b0;
            prev_match_addr_s2   <= {MAX_DEPTH_BITS{1'b0}};
            metadata_s2          <= 64'd0;
            skip_stage_s2        <= 1'b0;
            this_match_found_s2  <= 1'b0;
            this_match_addr_s2   <= {MAX_DEPTH_BITS{1'b0}};
        end else begin
            search_valid_s2      <= search_valid_s1;
            umt_id_s2            <= umt_id_s1;
            prev_match_found_s2  <= prev_match_found_s1;
            prev_match_addr_s2   <= prev_match_addr_s1;
            metadata_s2          <= metadata_s1;
            skip_stage_s2        <= skip_stage_s1;
            
            // Capture match results from crossbar
            if (MATCH_TYPE == "TCAM") begin
                this_match_found_s2 <= xbar_match_found;
                this_match_addr_s2  <= xbar_match_addr;
            end else begin
                this_match_found_s2 <= xbar_rd_valid;
                this_match_addr_s2  <= prev_match_addr_s1; // SRAM uses address directly
            end
        end
    end
    
    // Search Path - Pipeline Stage 3: Read Action Data
    reg                      search_valid_s3;
    reg  [7:0]               umt_id_s3;
    reg                      match_found_s3;
    reg  [MAX_DEPTH_BITS-1:0] match_addr_s3;
    reg  [63:0]              action_data_s3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            search_valid_s3 <= 1'b0;
            umt_id_s3       <= 8'd0;
            match_found_s3  <= 1'b0;
            match_addr_s3   <= {MAX_DEPTH_BITS{1'b0}};
            action_data_s3  <= 64'd0;
        end else begin
            search_valid_s3 <= search_valid_s2;
            umt_id_s3       <= umt_id_s2;
            
            // Determine final match status
            if (skip_stage_s2) begin
                // Pass through previous match
                match_found_s3 <= prev_match_found_s2;
                match_addr_s3  <= prev_match_addr_s2;
                action_data_s3 <= metadata_s2;
            end else if (prev_match_found_s2 && !is_umt_end) begin
                // Previous LMT in cascade found match
                match_found_s3 <= 1'b1;
                match_addr_s3  <= prev_match_addr_s2;
                action_data_s3 <= metadata_s2;
            end else if (this_match_found_s2) begin
                // This LMT found match
                match_found_s3 <= 1'b1;
                match_addr_s3  <= this_match_addr_s2;
                // Read action data from SRAM (if applicable)
                action_data_s3 <= xbar_rd_data[63:0]; // Assumes action data in lower bits
            end else begin
                // No match
                match_found_s3 <= 1'b0;
                match_addr_s3  <= {MAX_DEPTH_BITS{1'b0}};
                action_data_s3 <= 64'd0;
            end
        end
    end
    
    // Output Stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_valid_out      <= 1'b0;
            pipe_umt_id_out     <= 8'd0;
            pipe_match_found_out <= 1'b0;
            pipe_match_addr_out <= {MAX_DEPTH_BITS{1'b0}};
            pipe_metadata_out   <= 64'd0;
        end else begin
            pipe_valid_out      <= search_valid_s3;
            pipe_umt_id_out     <= umt_id_s3;
            pipe_match_found_out <= match_found_s3;
            pipe_match_addr_out <= match_addr_s3;
            pipe_metadata_out   <= action_data_s3;
        end
    end

endmodule

// LMT Configuration Registers
// Stores ULSS (UMT-to-LMT State Structure) for each LMT

module lmt_config_regs #(
    parameter NUM_LMTS = 5,
    parameter LMT_ID_WIDTH = 3
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    // Configuration write interface
    input  wire                      cfg_wr_en,
    input  wire [LMT_ID_WIDTH-1:0]   cfg_lmt_id,
    input  wire                      cfg_lmt_used,
    input  wire [7:0]                cfg_lmt_uid,
    input  wire [7:0]                cfg_lmt_internal_id,
    input  wire [1:0]                cfg_lmt_status_flag,
    input  wire [1:0]                cfg_lmt_width_gear,
    input  wire [2:0]                cfg_lmt_depth_gear,
    
    // Configuration read interface (array output)
    output reg  [NUM_LMTS-1:0]       lmt_used_array,
    output reg  [NUM_LMTS*8-1:0]     lmt_uid_array,
    output reg  [NUM_LMTS*8-1:0]     lmt_internal_id_array,
    output reg  [NUM_LMTS*2-1:0]     lmt_status_flag_array,
    output reg  [NUM_LMTS*2-1:0]     lmt_width_gear_array,
    output reg  [NUM_LMTS*3-1:0]     lmt_depth_gear_array
);

    integer i;
    
    // Configuration storage
    reg                  lmt_used_reg [0:NUM_LMTS-1];
    reg [7:0]            lmt_uid_reg [0:NUM_LMTS-1];
    reg [7:0]            lmt_internal_id_reg [0:NUM_LMTS-1];
    reg [1:0]            lmt_status_flag_reg [0:NUM_LMTS-1];
    reg [1:0]            lmt_width_gear_reg [0:NUM_LMTS-1];
    reg [2:0]            lmt_depth_gear_reg [0:NUM_LMTS-1];
    
    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_LMTS; i = i + 1) begin
                lmt_used_reg[i]         <= 1'b0;
                lmt_uid_reg[i]          <= 8'd0;
                lmt_internal_id_reg[i]  <= 8'd0;
                lmt_status_flag_reg[i]  <= 2'b00;
                lmt_width_gear_reg[i]   <= 2'b00;
                lmt_depth_gear_reg[i]   <= 3'b000;
            end
        end else if (cfg_wr_en && cfg_lmt_id < NUM_LMTS) begin
            lmt_used_reg[cfg_lmt_id]         <= cfg_lmt_used;
            lmt_uid_reg[cfg_lmt_id]          <= cfg_lmt_uid;
            lmt_internal_id_reg[cfg_lmt_id]  <= cfg_lmt_internal_id;
            lmt_status_flag_reg[cfg_lmt_id]  <= cfg_lmt_status_flag;
            lmt_width_gear_reg[cfg_lmt_id]   <= cfg_lmt_width_gear;
            lmt_depth_gear_reg[cfg_lmt_id]   <= cfg_lmt_depth_gear;
        end
    end
    
    // Pack arrays for output
    always @(*) begin
        for (i = 0; i < NUM_LMTS; i = i + 1) begin
            lmt_used_array[i] = lmt_used_reg[i];
            lmt_uid_array[i*8 +: 8] = lmt_uid_reg[i];
            lmt_internal_id_array[i*8 +: 8] = lmt_internal_id_reg[i];
            lmt_status_flag_array[i*2 +: 2] = lmt_status_flag_reg[i];
            lmt_width_gear_array[i*2 +: 2] = lmt_width_gear_reg[i];
            lmt_depth_gear_array[i*3 +: 3] = lmt_depth_gear_reg[i];
        end
    end

endmodule

// Key Extractor
// Extracts specific fields from packet header vector (PHV) for matching

module key_extractor #(
    parameter PHV_WIDTH = 512,
    parameter MAX_KEY_WIDTH = 64,
    parameter NUM_FIELDS = 8          // Number of extractable fields
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    // Configuration: which fields to extract and where
    input  wire [3:0]                field_select,      // Which field to extract
    input  wire [15:0]               field_offset,      // Bit offset in PHV
    input  wire [7:0]                field_length,      // Length in bits
    
    // Input: Packet Header Vector
    input  wire                      phv_valid,
    input  wire [PHV_WIDTH-1:0]      phv_data,
    
    // Output: Extracted key
    output reg                       key_valid,
    output reg  [MAX_KEY_WIDTH-1:0]  key_data
);

    // Field extraction logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_valid <= 1'b0;
            key_data  <= {MAX_KEY_WIDTH{1'b0}};
        end else begin
            key_valid <= phv_valid;
            
            if (phv_valid) begin
                // Extract bits from PHV based on offset and length
                // Simplified: assumes field fits in MAX_KEY_WIDTH
                case (field_select)
                    4'd0: key_data <= phv_data[47:0];     // sMAC (48 bits)
                    4'd1: key_data <= phv_data[95:48];    // dMAC (48 bits)
                    4'd2: key_data <= phv_data[111:96];   // VLAN (16 bits)
                    4'd3: key_data <= phv_data[143:112];  // sIPv4 (32 bits)
                    4'd4: key_data <= phv_data[175:144];  // dIPv4 (32 bits)
                    4'd5: key_data <= phv_data[191:176];  // sPort (16 bits)
                    4'd6: key_data <= phv_data[207:192];  // dPort (16 bits)
                    4'd7: key_data <= phv_data[215:208];  // Protocol (8 bits)
                    default: key_data <= {MAX_KEY_WIDTH{1'b0}};
                endcase
            end else begin
                key_data <= {MAX_KEY_WIDTH{1'b0}};
            end
        end
    end

endmodule