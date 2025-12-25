// ============================================================================
// Crossbar Testbench
// Tests segment crossbar with PMT manager and multiplexer abstractions
// ============================================================================

`timescale 1ns/1ps

module tb_crossbar;

    parameter NUM_LMTS = 5;
    parameter NUM_PMTS = 32;
    parameter LMT_MAX_WIDTH = 64;
    parameter LMT_MAX_DEPTH = 256;
    parameter LMT_ADDR_WIDTH = 8;
    parameter PMT_WIDTH = 32;
    parameter PMT_DEPTH = 32;
    parameter PMT_ADDR_WIDTH = 5;
    parameter MAX_PMTS_PER_LMT = 8;
    parameter PMT_ID_WIDTH = 6;
    parameter CLK_PERIOD = 4;

    // Signals
    reg clk, rst_n;
    
    // PMT Manager
    reg alloc_trigger;
    reg [NUM_LMTS-1:0] lmt_used;
    reg [NUM_LMTS*2-1:0] lmt_width_gear;
    reg [NUM_LMTS*3-1:0] lmt_depth_gear;
    
    wire alloc_done, alloc_error;
    wire [7:0] alloc_error_code;
    wire [NUM_LMTS*8-1:0] lmt_pmt_count;
    wire [NUM_LMTS*PMT_ID_WIDTH-1:0] lmt_aspid, lmt_aepid;
    wire [NUM_LMTS*PMT_ID_WIDTH-1:0] lmt_pspid, lmt_pepid;
    wire [NUM_PMTS-1:0] pmt_used;
    wire [NUM_PMTS*8-1:0] pmt_lmt_id;
    wire [NUM_PMTS*4-1:0] pmt_width_idx, pmt_depth_idx;
    wire [7:0] total_pmts_used;
    
    // LMT interfaces
    reg [NUM_LMTS-1:0] lmt_wr_en;
    reg [NUM_LMTS*LMT_ADDR_WIDTH-1:0] lmt_wr_addr;
    reg [NUM_LMTS*LMT_MAX_WIDTH-1:0] lmt_wr_data;
    reg [NUM_LMTS*LMT_MAX_WIDTH-1:0] lmt_wr_mask;
    
    reg [NUM_LMTS-1:0] lmt_search_en;
    reg [NUM_LMTS*LMT_MAX_WIDTH-1:0] lmt_search_key;
    wire [NUM_LMTS*LMT_MAX_DEPTH-1:0] lmt_matchlines;
    wire [NUM_LMTS-1:0] lmt_match_found;
    wire [NUM_LMTS*LMT_ADDR_WIDTH-1:0] lmt_match_addr;
    
    // PMT pool interfaces
    wire [NUM_PMTS-1:0] pmt_wr_en;
    wire [NUM_PMTS*PMT_ADDR_WIDTH-1:0] pmt_wr_addr;
    wire [NUM_PMTS*PMT_WIDTH-1:0] pmt_wr_data;
    wire [NUM_PMTS*PMT_WIDTH-1:0] pmt_wr_mask;
    
    wire [NUM_PMTS-1:0] pmt_search_en;
    wire [NUM_PMTS*PMT_WIDTH-1:0] pmt_search_key;
    wire [NUM_PMTS*PMT_DEPTH-1:0] pmt_matchlines;
    wire [NUM_PMTS-1:0] pmt_match_found;
    wire [NUM_PMTS*PMT_ADDR_WIDTH-1:0] pmt_match_addr;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // ========================================================================
    // DUT: PMT Manager
    // ========================================================================
    pmt_manager #(
        .NUM_LMTS(NUM_LMTS),
        .NUM_PMTS(NUM_PMTS),
        .PMT_WIDTH(PMT_WIDTH),
        .PMT_DEPTH(PMT_DEPTH),
        .MAX_PMTS_PER_LMT(MAX_PMTS_PER_LMT),
        .PMT_ID_WIDTH(PMT_ID_WIDTH)
    ) pmt_mgr (
        .clk(clk),
        .rst_n(rst_n),
        .alloc_trigger(alloc_trigger),
        .lmt_used(lmt_used),
        .lmt_width_gear(lmt_width_gear),
        .lmt_depth_gear(lmt_depth_gear),
        .alloc_done(alloc_done),
        .alloc_error(alloc_error),
        .alloc_error_code(alloc_error_code),
        .lmt_pmt_count(lmt_pmt_count),
        .lmt_aspid(lmt_aspid),
        .lmt_aepid(lmt_aepid),
        .lmt_pspid(lmt_pspid),
        .lmt_pepid(lmt_pepid),
        .pmt_used(pmt_used),
        .pmt_lmt_id(pmt_lmt_id),
        .pmt_width_idx(pmt_width_idx),
        .pmt_depth_idx(pmt_depth_idx),
        .total_pmts_used(total_pmts_used)
    );
    
    // ========================================================================
    // DUT: Segment Crossbar
    // ========================================================================
    segment_crossbar #(
        .NUM_LMTS(NUM_LMTS),
        .NUM_PMTS(NUM_PMTS),
        .LMT_MAX_WIDTH(LMT_MAX_WIDTH),
        .LMT_MAX_DEPTH(LMT_MAX_DEPTH),
        .LMT_ADDR_WIDTH(LMT_ADDR_WIDTH),
        .PMT_WIDTH(PMT_WIDTH),
        .PMT_DEPTH(PMT_DEPTH),
        .PMT_ADDR_WIDTH(PMT_ADDR_WIDTH),
        .MAX_PMTS_PER_LMT(MAX_PMTS_PER_LMT),
        .PMT_ID_WIDTH(PMT_ID_WIDTH)
    ) xbar (
        .clk(clk),
        .rst_n(rst_n),
        .lmt_pmt_count(lmt_pmt_count),
        .lmt_aspid(lmt_aspid),
        .lmt_aepid(lmt_aepid),
        .lmt_width_gear(lmt_width_gear),
        .lmt_depth_gear(lmt_depth_gear),
        .pmt_used(pmt_used),
        .pmt_lmt_id(pmt_lmt_id),
        .pmt_width_idx(pmt_width_idx),
        .pmt_depth_idx(pmt_depth_idx),
        .lmt_wr_en(lmt_wr_en),
        .lmt_wr_addr(lmt_wr_addr),
        .lmt_wr_data(lmt_wr_data),
        .lmt_wr_mask(lmt_wr_mask),
        .lmt_rd_en({NUM_LMTS{1'b0}}),
        .lmt_rd_addr({NUM_LMTS*LMT_ADDR_WIDTH{1'b0}}),
        .lmt_rd_data(),
        .lmt_rd_valid(),
        .lmt_search_en(lmt_search_en),
        .lmt_search_key(lmt_search_key),
        .lmt_matchlines(lmt_matchlines),
        .lmt_match_found(lmt_match_found),
        .lmt_match_addr(lmt_match_addr),
        .pmt_wr_en(pmt_wr_en),
        .pmt_wr_addr(pmt_wr_addr),
        .pmt_wr_data(pmt_wr_data),
        .pmt_wr_mask(pmt_wr_mask),
        .pmt_rd_en(),
        .pmt_rd_addr(),
        .pmt_rd_data({NUM_PMTS*PMT_WIDTH{1'b0}}),
        .pmt_rd_valid({NUM_PMTS{1'b0}}),
        .pmt_search_en(pmt_search_en),
        .pmt_search_key(pmt_search_key),
        .pmt_matchlines(pmt_matchlines),
        .pmt_match_found(pmt_match_found),
        .pmt_match_addr(pmt_match_addr)
    );
    
    // ========================================================================
    // DUT: PMT Pool (TCAM)
    // ========================================================================
    pmt_pool #(
        .NUM_PMTS(NUM_PMTS),
        .DATA_WIDTH(PMT_WIDTH),
        .ADDR_WIDTH(PMT_ADDR_WIDTH),
        .DEPTH(PMT_DEPTH),
        .PMT_TYPE("TCAM"),
        .PMT_ID_WIDTH(PMT_ID_WIDTH)
    ) pmt_pool_inst (
        .clk(clk),
        .rst_n(rst_n),
        .pmt_used(pmt_used),
        .pmt_lmt_id(pmt_lmt_id),
        .wr_en(|pmt_wr_en),
        .wr_pmt_id(6'd0),  // Simplified for test
        .wr_addr(pmt_wr_addr[PMT_ADDR_WIDTH-1:0]),
        .wr_data(pmt_wr_data[PMT_WIDTH-1:0]),
        .wr_mask(pmt_wr_mask[PMT_WIDTH-1:0]),
        .rd_en({NUM_PMTS{1'b0}}),
        .rd_addr({NUM_PMTS*PMT_ADDR_WIDTH{1'b0}}),
        .rd_data(),
        .rd_valid(),
        .search_en(pmt_search_en),
        .search_key(pmt_search_key),
        .matchlines(pmt_matchlines),
        .match_found(pmt_match_found),
        .match_addr(pmt_match_addr),
        .entry_valid()
    );
    
    // ========================================================================
    // Test Stimulus
    // ========================================================================
    integer i;
    initial begin
        rst_n = 0;
        alloc_trigger = 0;
        lmt_used = 0;
        lmt_width_gear = 0;
        lmt_depth_gear = 0;
        lmt_wr_en = 0;
        lmt_wr_addr = 0;
        lmt_wr_data = 0;
        lmt_wr_mask = 0;
        lmt_search_en = 0;
        lmt_search_key = 0;
        
        #(CLK_PERIOD*10);
        rst_n = 1;
        #(CLK_PERIOD*5);
        
        $display("========================================");
        $display("Crossbar Tests");
        $display("========================================");
        
        // ====================================================================
        // Test 1: Configure 3 LMTs with different sizes
        // ====================================================================
        $display("\n[Test 1] Configure LMTs");
        $display("  LMT 0: 32b x 64  (1x width, 2x depth)");
        $display("  LMT 1: 48b x 128 (2x width, 4x depth)");
        $display("  LMT 2: 32b x 32  (1x width, 1x depth)");
        
        @(posedge clk);
        lmt_used = 5'b00111;  // LMTs 0, 1, 2
        
        // LMT 0: 32b x 64 = 1x width, 2x depth = 2 PMTs
        lmt_width_gear[1:0] = 2'b00;
        lmt_depth_gear[2:0] = 3'b001;
        
        // LMT 1: 48b x 128 = 2x width, 4x depth = 8 PMTs
        lmt_width_gear[3:2] = 2'b01;
        lmt_depth_gear[5:3] = 3'b010;
        
        // LMT 2: 32b x 32 = 1x width, 1x depth = 1 PMT
        lmt_width_gear[5:4] = 2'b00;
        lmt_depth_gear[8:6] = 3'b000;
        
        @(posedge clk);
        alloc_trigger = 1;
        @(posedge clk);
        alloc_trigger = 0;
        
        wait(alloc_done);
        #(CLK_PERIOD*5);
        
        $display("\n[PMT Allocation Results]");
        $display("  Total PMTs used: %0d", total_pmts_used);
        $display("  Allocation error: %b", alloc_error);
        
        // Display allocation details
        for (i = 0; i < NUM_LMTS; i = i + 1) begin
            if (lmt_used[i]) begin
                $display("  LMT[%0d]: PMTs=%0d, AS=[%0d:%0d], PS=[%0d:%0d]",
                         i, lmt_pmt_count[i*8 +: 8],
                         lmt_aspid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH],
                         lmt_aepid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH]-1,
                         lmt_pspid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH],
                         lmt_pepid[i*PMT_ID_WIDTH +: PMT_ID_WIDTH]-1);
            end
        end
        
        // ====================================================================
        // Test 2: Write entries to LMT 0 (tests PARTITION, SELECT, SPREAD)
        // ====================================================================
        $display("\n[Test 2] Write entries to LMT 0");
        
        @(posedge clk);
        lmt_wr_en[0] = 1'b1;
        lmt_wr_addr[LMT_ADDR_WIDTH-1:0] = 8'd0;
        lmt_wr_data[LMT_MAX_WIDTH-1:0] = 64'hDEADBEEF_12345678;
        lmt_wr_mask[LMT_MAX_WIDTH-1:0] = 64'hFFFFFFFF_FFFFFFFF;
        
        @(posedge clk);
        lmt_wr_addr[LMT_ADDR_WIDTH-1:0] = 8'd1;
        lmt_wr_data[LMT_MAX_WIDTH-1:0] = 64'hCAFEBABE_ABCD1234;
        
        @(posedge clk);
        lmt_wr_addr[LMT_ADDR_WIDTH-1:0] = 8'd40;  // Should go to 2nd PMT
        lmt_wr_data[LMT_MAX_WIDTH-1:0] = 64'h11112222_33334444;
        
        @(posedge clk);
        lmt_wr_en[0] = 1'b0;
        
        #(CLK_PERIOD*5);
        
        // ====================================================================
        // Test 3: Search LMT 0 (tests COMBINE, MAND)
        // ====================================================================
        $display("\n[Test 3] Search LMT 0");
        
        @(posedge clk);
        lmt_search_en[0] = 1'b1;
        lmt_search_key[LMT_MAX_WIDTH-1:0] = 64'hDEADBEEF_12345678;
        
        repeat(5) @(posedge clk);
        
        lmt_search_key[LMT_MAX_WIDTH-1:0] = 64'hCAFEBABE_ABCD1234;
        
        repeat(5) @(posedge clk);
        
        lmt_search_key[LMT_MAX_WIDTH-1:0] = 64'h99999999_88888888;  // No match
        
        repeat(5) @(posedge clk);
        
        lmt_search_en[0] = 1'b0;
        
        #(CLK_PERIOD*10);
        
        // ====================================================================
        // Test 4: Test wide LMT (48-bit) - tests PARTITION across 2 PMTs
        // ====================================================================
        $display("\n[Test 4] Write to wide LMT 1 (48-bit)");
        
        @(posedge clk);
        lmt_wr_en[1] = 1'b1;
        lmt_wr_addr[1*LMT_ADDR_WIDTH +: LMT_ADDR_WIDTH] = 8'd0;
        lmt_wr_data[1*LMT_MAX_WIDTH +: LMT_MAX_WIDTH] = 64'hAABBCCDD_EEFF0011;
        lmt_wr_mask[1*LMT_MAX_WIDTH +: LMT_MAX_WIDTH] = 64'hFFFFFFFF_FFFFFFFF;
        
        @(posedge clk);
        lmt_wr_en[1] = 1'b0;
        
        #(CLK_PERIOD*5);
        
        // Search wide LMT
        @(posedge clk);
        lmt_search_en[1] = 1'b1;
        lmt_search_key[1*LMT_MAX_WIDTH +: LMT_MAX_WIDTH] = 64'hAABBCCDD_EEFF0011;
        
        repeat(5) @(posedge clk);
        
        lmt_search_en[1] = 1'b0;
        
        #(CLK_PERIOD*10);
        
        $display("\n========================================");
        $display("Crossbar Tests Complete");
        $display("========================================");
        $finish;
    end
    
    // Monitor
    always @(posedge clk) begin
        for (i = 0; i < NUM_LMTS; i = i + 1) begin
            if (lmt_match_found[i]) begin
                $display("[Match] LMT=%0d, Addr=%0d, Key=0x%016h",
                         i, lmt_match_addr[i*LMT_ADDR_WIDTH +: LMT_ADDR_WIDTH],
                         lmt_search_key[i*LMT_MAX_WIDTH +: LMT_MAX_WIDTH]);
            end
        end
        
        for (i = 0; i < NUM_PMTS; i = i + 1) begin
            if (pmt_wr_en[i]) begin
                $display("[PMT Write] PMT=%0d, Addr=%0d, Data=0x%08h, Mask=0x%08h",
                         i, pmt_wr_addr[i*PMT_ADDR_WIDTH +: PMT_ADDR_WIDTH],
                         pmt_wr_data[i*PMT_WIDTH +: PMT_WIDTH],
                         pmt_wr_mask[i*PMT_WIDTH +: PMT_WIDTH]);
            end
        end
    end
    
    // Timeout
    initial begin
        #500000;
        $display("ERROR: Timeout!");
        $finish;
    end
    
    // Waveform
    initial begin
        $dumpfile("crossbar_tb.vcd");
        $dumpvars(0, tb_crossbar);
    end

endmodule