// ============================================================================
// Testbench for Logical Match Table (LMT)
// Tests configuration, cascading, and pipeline operation
// ============================================================================

`timescale 1ns/1ps

module tb_lmt;

    // Parameters
    parameter MAX_WIDTH = 64;
    parameter MAX_DEPTH = 256;
    parameter MAX_DEPTH_BITS = 8;
    parameter PMT_WIDTH = 32;
    parameter PMT_DEPTH = 32;
    parameter PMT_ADDR_WIDTH = 5;
    parameter MAX_PMTS_PER_LMT = 8;
    parameter CLK_PERIOD = 4;  // 250 MHz
    
    // Common signals
    reg clk;
    reg rst_n;
    
    // ========================================================================
    // LMT Configuration
    // ========================================================================
    reg                      lmt_used;
    reg [7:0]                lmt_uid;
    reg [7:0]                lmt_internal_id;
    reg [1:0]                lmt_status_flag;
    reg [1:0]                lmt_width_gear;
    reg [2:0]                lmt_depth_gear;
    
    // ========================================================================
    // Pipeline Interface
    // ========================================================================
    reg                      pipe_valid_in;
    reg [MAX_WIDTH-1:0]      pipe_search_key;
    reg [7:0]                pipe_umt_id_in;
    reg                      pipe_match_found_in;
    reg [MAX_DEPTH_BITS-1:0] pipe_match_addr_in;
    reg [63:0]               pipe_metadata_in;
    
    wire                     pipe_valid_out;
    wire [7:0]               pipe_umt_id_out;
    wire                     pipe_match_found_out;
    wire [MAX_DEPTH_BITS-1:0] pipe_match_addr_out;
    wire [63:0]              pipe_metadata_out;
    
    // ========================================================================
    // Crossbar Interface (Mocked)
    // ========================================================================
    wire                     xbar_wr_en;
    wire [MAX_DEPTH_BITS-1:0] xbar_wr_addr;
    wire [MAX_WIDTH-1:0]     xbar_wr_data;
    wire [MAX_WIDTH-1:0]     xbar_wr_mask;
    
    wire                     xbar_rd_en;
    wire [MAX_DEPTH_BITS-1:0] xbar_rd_addr;
    reg  [MAX_WIDTH-1:0]     xbar_rd_data;
    reg                      xbar_rd_valid;
    
    wire                     xbar_search_en;
    wire [MAX_WIDTH-1:0]     xbar_search_key;
    reg  [MAX_DEPTH-1:0]     xbar_matchlines;
    reg                      xbar_match_found;
    reg  [MAX_DEPTH_BITS-1:0] xbar_match_addr;
    
    // ========================================================================
    // Entry Write Interface
    // ========================================================================
    reg                      entry_wr_en;
    reg [MAX_DEPTH_BITS-1:0] entry_wr_addr;
    reg [MAX_WIDTH-1:0]      entry_wr_data;
    reg [MAX_WIDTH-1:0]      entry_wr_mask;
    
    // ========================================================================
    // Clock Generation
    // ========================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // ========================================================================
    // DUT Instantiation
    // ========================================================================
    logical_match_table #(
        .LMT_ID(0),
        .MAX_WIDTH(MAX_WIDTH),
        .MAX_DEPTH(MAX_DEPTH),
        .MAX_DEPTH_BITS(MAX_DEPTH_BITS),
        .PMT_WIDTH(PMT_WIDTH),
        .PMT_DEPTH(PMT_DEPTH),
        .PMT_ADDR_WIDTH(PMT_ADDR_WIDTH),
        .MAX_PMTS_PER_LMT(MAX_PMTS_PER_LMT),
        .MATCH_TYPE("TCAM")
    ) dut (
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
        .pipe_valid_in(pipe_valid_in),
        .pipe_search_key(pipe_search_key),
        .pipe_umt_id_in(pipe_umt_id_in),
        .pipe_match_found_in(pipe_match_found_in),
        .pipe_match_addr_in(pipe_match_addr_in),
        .pipe_metadata_in(pipe_metadata_in),
        
        .pipe_valid_out(pipe_valid_out),
        .pipe_umt_id_out(pipe_umt_id_out),
        .pipe_match_found_out(pipe_match_found_out),
        .pipe_match_addr_out(pipe_match_addr_out),
        .pipe_metadata_out(pipe_metadata_out),
        
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
    // Mock Crossbar Response
    // Simulates PMT pool returning match results
    // ========================================================================
    always @(posedge clk) begin
        // Default values
        xbar_rd_data <= {MAX_WIDTH{1'b0}};
        xbar_rd_valid <= 1'b0;
        xbar_matchlines <= {MAX_DEPTH{1'b0}};
        xbar_match_found <= 1'b0;
        xbar_match_addr <= 8'd0;
        
        // Simulate search response with 2 cycle delay
        if (xbar_search_en) begin
            // Simple mock: match if key == 0xDEADBEEF
            if (xbar_search_key[31:0] == 32'hDEADBEEF) begin
                #(CLK_PERIOD*2);
                xbar_match_found <= 1'b1;
                xbar_match_addr <= 8'd5;
                xbar_matchlines[5] <= 1'b1;
            end else if (xbar_search_key[31:0] == 32'hCAFEBABE) begin
                #(CLK_PERIOD*2);
                xbar_match_found <= 1'b1;
                xbar_match_addr <= 8'd10;
                xbar_matchlines[10] <= 1'b1;
            end else begin
                #(CLK_PERIOD*2);
                xbar_match_found <= 1'b0;
            end
        end
        
        // Simulate read response
        if (xbar_rd_en) begin
            #(CLK_PERIOD*2);
            xbar_rd_data <= {32'hACE0_0000, xbar_rd_addr, 24'h000000}; // Mock action data
            xbar_rd_valid <= 1'b1;
        end
    end
    
    // ========================================================================
    // Test Stimulus
    // ========================================================================
    initial begin
        // Initialize
        rst_n = 0;
        lmt_used = 0;
        lmt_uid = 0;
        lmt_internal_id = 0;
        lmt_status_flag = 0;
        lmt_width_gear = 0;
        lmt_depth_gear = 0;
        
        pipe_valid_in = 0;
        pipe_search_key = 0;
        pipe_umt_id_in = 0;
        pipe_match_found_in = 0;
        pipe_match_addr_in = 0;
        pipe_metadata_in = 0;
        
        entry_wr_en = 0;
        entry_wr_addr = 0;
        entry_wr_data = 0;
        entry_wr_mask = 0;
        
        // Reset
        #(CLK_PERIOD*10);
        rst_n = 1;
        #(CLK_PERIOD*5);
        
        $display("========================================");
        $display("Starting LMT Tests");
        $display("========================================");
        
        // ====================================================================
        // Test 1: Configure LMT as single table
        // ====================================================================
        $display("\n[Test 1] Configure LMT as single table (32b x 128)");
        
        @(posedge clk);
        lmt_used = 1;
        lmt_uid = 8'd1;              // UMT ID = 1
        lmt_internal_id = 8'd0;      // First (and only) LMT in UMT
        lmt_status_flag = 2'b00;     // Single table (not cascaded)
        lmt_width_gear = 1'b0;       // 1*Pw = 32 bits
        lmt_depth_gear = 3'd2;       // 4*Pd = 128 entries
        
        #(CLK_PERIOD*5);
        
        // ====================================================================
        // Test 2: Write entries to LMT
        // ====================================================================
        $display("\n[Test 2] Write entries to LMT");
        
        @(posedge clk);
        entry_wr_en = 1;
        entry_wr_addr = 8'd5;
        entry_wr_data = 64'hDEADBEEF_00000000;
        entry_wr_mask = 64'hFFFFFFFF_00000000;
        
        @(posedge clk);
        entry_wr_addr = 8'd10;
        entry_wr_data = 64'hCAFEBABE_00000000;
        entry_wr_mask = 64'hFFFFFFFF_00000000;
        
        @(posedge clk);
        entry_wr_en = 0;
        
        #(CLK_PERIOD*5);
        
        // ====================================================================
        // Test 3: Pipeline search - Match found
        // ====================================================================
        $display("\n[Test 3] Pipeline search - Match found");
        
        @(posedge clk);
        pipe_valid_in = 1;
        pipe_search_key = 64'hDEADBEEF_00000000;
        pipe_umt_id_in = 8'd1;       // Match this LMT's UID
        pipe_match_found_in = 0;
        
        @(posedge clk);
        pipe_valid_in = 0;
        
        #(CLK_PERIOD*10);
        
        // ====================================================================
        // Test 4: Pipeline search - No match
        // ====================================================================
        $display("\n[Test 4] Pipeline search - No match");
        
        @(posedge clk);
        pipe_valid_in = 1;
        pipe_search_key = 64'h12345678_00000000;
        pipe_umt_id_in = 8'd1;
        pipe_match_found_in = 0;
        
        @(posedge clk);
        pipe_valid_in = 0;
        
        #(CLK_PERIOD*10);
        
        // ====================================================================
        // Test 5: Wrong UMT ID - Should pass through
        // ====================================================================
        $display("\n[Test 5] Wrong UMT ID - should pass through");
        
        @(posedge clk);
        pipe_valid_in = 1;
        pipe_search_key = 64'hDEADBEEF_00000000;
        pipe_umt_id_in = 8'd2;       // Different UMT ID
        pipe_match_found_in = 0;
        
        @(posedge clk);
        pipe_valid_in = 0;
        
        #(CLK_PERIOD*10);
        
        // ====================================================================
        // Test 6: Configure as cascaded table (start)
        // ====================================================================
        $display("\n[Test 6] Configure as cascaded table (start of UMT)");
        
        @(posedge clk);
        lmt_status_flag = 2'b01;     // Start of cascade
        lmt_internal_id = 8'd0;
        
        @(posedge clk);
        pipe_valid_in = 1;
        pipe_search_key = 64'hCAFEBABE_00000000;
        pipe_umt_id_in = 8'd1;
        pipe_match_found_in = 0;
        
        @(posedge clk);
        pipe_valid_in = 0;
        
        #(CLK_PERIOD*10);
        
        // ====================================================================
        // Test 7: Skip stage due to previous match
        // ====================================================================
        $display("\n[Test 7] Skip stage - previous LMT found match");
        
        @(posedge clk);
        lmt_status_flag = 2'b10;     // Middle of cascade
        lmt_internal_id = 8'd1;
        
        @(posedge clk);
        pipe_valid_in = 1;
        pipe_search_key = 64'hDEADBEEF_00000000;
        pipe_umt_id_in = 8'd1;
        pipe_match_found_in = 1;     // Previous stage found match
        pipe_match_addr_in = 8'd3;
        pipe_metadata_in = 64'hCAFEBABE_DEADBEEF;
        
        @(posedge clk);
        pipe_valid_in = 0;
        
        #(CLK_PERIOD*10);
        
        $display("\n========================================");
        $display("LMT Tests Complete");
        $display("========================================");
        $finish;
    end
    
    // ========================================================================
    // Monitor Results
    // ========================================================================
    always @(posedge clk) begin
        if (pipe_valid_out) begin
            $display("[LMT Output] UMT=%0d, Match=%b, Addr=%0d, Data=0x%016h", 
                     pipe_umt_id_out, pipe_match_found_out, 
                     pipe_match_addr_out, pipe_metadata_out);
        end
        
        if (xbar_wr_en) begin
            $display("[Entry Write] Addr=%0d, Data=0x%016h, Mask=0x%016h",
                     xbar_wr_addr, xbar_wr_data, xbar_wr_mask);
        end
        
        if (xbar_search_en) begin
            $display("[Search] Key=0x%016h", xbar_search_key);
        end
    end
    
    // Timeout watchdog
    initial begin
        #200000;
        $display("ERROR: Timeout!");
        $finish;
    end
    
    // Waveform dump
    initial begin
        $dumpfile("lmt_tb.vcd");
        $dumpvars(0, tb_lmt);
    end

endmodule