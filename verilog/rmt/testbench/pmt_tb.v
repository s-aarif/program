// ============================================================================
// Testbench for PMT Modules
// Tests both SRAM and TCAM PMT implementations
// ============================================================================

`timescale 1ns/1ps

module tb_pmt;

    // Parameters
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 5;
    parameter DEPTH = 32;
    parameter CLK_PERIOD = 4;  // 250 MHz
    
    // Common signals
    reg clk;
    reg rst_n;
    
    // ========================================================================
    // SRAM PMT Signals
    // ========================================================================
    reg                      sram_wr_en;
    reg  [ADDR_WIDTH-1:0]    sram_wr_addr;
    reg  [DATA_WIDTH-1:0]    sram_wr_data;
    reg                      sram_rd_en;
    reg  [ADDR_WIDTH-1:0]    sram_rd_addr;
    wire [DATA_WIDTH-1:0]    sram_rd_data;
    wire                     sram_rd_valid;
    wire [DEPTH-1:0]         sram_entry_valid;
    
    // ========================================================================
    // TCAM PMT Signals
    // ========================================================================
    reg                      tcam_wr_en;
    reg  [ADDR_WIDTH-1:0]    tcam_wr_addr;
    reg  [DATA_WIDTH-1:0]    tcam_wr_data;
    reg  [DATA_WIDTH-1:0]    tcam_wr_mask;
    reg                      tcam_search_en;
    reg  [DATA_WIDTH-1:0]    tcam_search_key;
    wire [DEPTH-1:0]         tcam_matchlines;
    wire                     tcam_match_found;
    wire [ADDR_WIDTH-1:0]    tcam_match_addr;
    wire [DEPTH-1:0]         tcam_entry_valid;
    
    // ========================================================================
    // Clock Generation
    // ========================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // ========================================================================
    // DUT Instantiations
    // ========================================================================
    
    // SRAM PMT
    sram_pmt #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DEPTH(DEPTH)
    ) dut_sram (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(sram_wr_en),
        .wr_addr(sram_wr_addr),
        .wr_data(sram_wr_data),
        .rd_en(sram_rd_en),
        .rd_addr(sram_rd_addr),
        .rd_data(sram_rd_data),
        .rd_valid(sram_rd_valid),
        .entry_valid(sram_entry_valid)
    );
    
    // TCAM PMT
    tcam_pmt #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DEPTH(DEPTH)
    ) dut_tcam (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(tcam_wr_en),
        .wr_addr(tcam_wr_addr),
        .wr_data(tcam_wr_data),
        .wr_mask(tcam_wr_mask),
        .search_en(tcam_search_en),
        .search_key(tcam_search_key),
        .matchlines(tcam_matchlines),
        .match_found(tcam_match_found),
        .match_addr(tcam_match_addr),
        .entry_valid(tcam_entry_valid)
    );
    
    // ========================================================================
    // Test Stimulus
    // ========================================================================
    initial begin
        // Initialize
        rst_n = 0;
        sram_wr_en = 0;
        sram_wr_addr = 0;
        sram_wr_data = 0;
        sram_rd_en = 0;
        sram_rd_addr = 0;
        
        tcam_wr_en = 0;
        tcam_wr_addr = 0;
        tcam_wr_data = 0;
        tcam_wr_mask = 0;
        tcam_search_en = 0;
        tcam_search_key = 0;
        
        // Reset
        #(CLK_PERIOD*10);
        rst_n = 1;
        #(CLK_PERIOD*5);
        
        $display("========================================");
        $display("Starting PMT Tests");
        $display("========================================");
        
        // ====================================================================
        // Test 1: SRAM PMT Write and Read
        // ====================================================================
        $display("\n[Test 1] SRAM PMT: Write and Read");
        
        // Write data to SRAM
        @(posedge clk);
        sram_wr_en = 1;
        sram_wr_addr = 5'd0;
        sram_wr_data = 32'hDEADBEEF;
        @(posedge clk);
        sram_wr_addr = 5'd1;
        sram_wr_data = 32'hCAFEBABE;
        @(posedge clk);
        sram_wr_addr = 5'd10;
        sram_wr_data = 32'h12345678;
        @(posedge clk);
        sram_wr_en = 0;
        
        // Read back data
        #(CLK_PERIOD*2);
        @(posedge clk);
        sram_rd_en = 1;
        sram_rd_addr = 5'd0;
        @(posedge clk);
        sram_rd_addr = 5'd1;
        @(posedge clk);
        sram_rd_addr = 5'd10;
        @(posedge clk);
        sram_rd_en = 0;
        
        #(CLK_PERIOD*5);
        
        // ====================================================================
        // Test 2: TCAM PMT Exact Match
        // ====================================================================
        $display("\n[Test 2] TCAM PMT: Exact Match");
        
        // Write entries to TCAM (exact match - all bits care)
        @(posedge clk);
        tcam_wr_en = 1;
        tcam_wr_addr = 5'd0;
        tcam_wr_data = 32'h0A000001;  // 10.0.0.1
        tcam_wr_mask = 32'hFFFFFFFF;  // All bits matter
        @(posedge clk);
        tcam_wr_addr = 5'd1;
        tcam_wr_data = 32'h0A000002;  // 10.0.0.2
        tcam_wr_mask = 32'hFFFFFFFF;
        @(posedge clk);
        tcam_wr_addr = 5'd5;
        tcam_wr_data = 32'hC0A80001;  // 192.168.0.1
        tcam_wr_mask = 32'hFFFFFFFF;
        @(posedge clk);
        tcam_wr_en = 0;
        
        // Search for exact matches
        #(CLK_PERIOD*2);
        @(posedge clk);
        tcam_search_en = 1;
        tcam_search_key = 32'h0A000001;  // Should match entry 0
        @(posedge clk);
        tcam_search_key = 32'h0A000002;  // Should match entry 1
        @(posedge clk);
        tcam_search_key = 32'hC0A80001;  // Should match entry 5
        @(posedge clk);
        tcam_search_key = 32'h0A000003;  // No match
        @(posedge clk);
        tcam_search_en = 0;
        
        #(CLK_PERIOD*5);
        
        // ====================================================================
        // Test 3: TCAM PMT Prefix Match (Don't Care bits)
        // ====================================================================
        $display("\n[Test 3] TCAM PMT: Prefix/Wildcard Match");
        
        // Write entries with don't care bits
        @(posedge clk);
        tcam_wr_en = 1;
        tcam_wr_addr = 5'd10;
        tcam_wr_data = 32'h0A000000;  // 10.0.0.0/24
        tcam_wr_mask = 32'hFFFFFF00;  // Last 8 bits don't care
        @(posedge clk);
        tcam_wr_addr = 5'd11;
        tcam_wr_data = 32'hC0A80000;  // 192.168.0.0/16
        tcam_wr_mask = 32'hFFFF0000;  // Last 16 bits don't care
        @(posedge clk);
        tcam_wr_en = 0;
        
        // Search with wildcards
        #(CLK_PERIOD*2);
        @(posedge clk);
        tcam_search_en = 1;
        tcam_search_key = 32'h0A0000FF;  // Should match entry 10 (10.0.0.255)
        @(posedge clk);
        tcam_search_key = 32'h0A000042;  // Should match entry 10 (10.0.0.66)
        @(posedge clk);
        tcam_search_key = 32'hC0A81234;  // Should match entry 11 (192.168.18.52)
        @(posedge clk);
        tcam_search_key = 32'h0B000001;  // No match
        @(posedge clk);
        tcam_search_en = 0;
        
        #(CLK_PERIOD*5);
        
        // ====================================================================
        // Test 4: TCAM Priority (Multiple Matches)
        // ====================================================================
        $display("\n[Test 4] TCAM PMT: Priority Encoding");
        
        // Create overlapping entries
        @(posedge clk);
        tcam_wr_en = 1;
        tcam_wr_addr = 5'd20;
        tcam_wr_data = 32'h0A000000;  // 10.0.0.0/8 (broader)
        tcam_wr_mask = 32'hFF000000;
        @(posedge clk);
        tcam_wr_addr = 5'd21;
        tcam_wr_data = 32'h0A000000;  // 10.0.0.0/16 (more specific)
        tcam_wr_mask = 32'hFFFF0000;
        @(posedge clk);
        tcam_wr_en = 0;
        
        // Search - should return lowest index (highest priority)
        #(CLK_PERIOD*2);
        @(posedge clk);
        tcam_search_en = 1;
        tcam_search_key = 32'h0A001234;  // Matches both, should return 20
        @(posedge clk);
        tcam_search_en = 0;
        
        #(CLK_PERIOD*10);
        
        $display("\n========================================");
        $display("PMT Tests Complete");
        $display("========================================");
        $finish;
    end
    
    // ========================================================================
    // Monitor Results
    // ========================================================================
    always @(posedge clk) begin
        if (sram_rd_valid) begin
            $display("[SRAM] Read addr=%0d, data=0x%08h", sram_rd_addr, sram_rd_data);
        end
        
        if (tcam_match_found) begin
            $display("[TCAM] Match found! key=0x%08h, addr=%0d, matchlines=0b%032b", 
                     tcam_search_key, tcam_match_addr, tcam_matchlines);
        end else if (tcam_search_en) begin
            $display("[TCAM] No match for key=0x%08h", tcam_search_key);
        end
    end
    
    // Timeout watchdog
    initial begin
        #100000;
        $display("ERROR: Timeout!");
        $finish;
    end
    
    // Optional: Dump waveforms
    initial begin
        $dumpfile("pmt_tb.vcd");
        $dumpvars(0, tb_pmt);
    end

endmodule