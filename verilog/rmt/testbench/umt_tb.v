// ============================================================================
// UMT Testbench
// Tests UMT configuration, mapping, and entry management
// ============================================================================

`timescale 1ns/1ps

module tb_umt;

    parameter MAX_UMTS = 5;
    parameter MAX_LMTS = 5;
    parameter MAX_WIDTH = 64;
    parameter MAX_DEPTH = 512;
    parameter PMT_WIDTH = 32;
    parameter PMT_DEPTH = 32;
    parameter MAX_PMTS_PER_LMT = 8;
    parameter CLK_PERIOD = 4;  // 250 MHz
    
    // Signals
    reg clk;
    reg rst_n;
    
    // UMT Configuration
    reg                      umt_cfg_valid;
    reg                      umt_cfg_wr_en;
    reg [2:0]                umt_cfg_id;
    reg [15:0]               umt_cfg_width;
    reg [15:0]               umt_cfg_depth;
    reg                      umt_cfg_type;
    reg                      umt_map_trigger;
    
    // Entry Management
    reg                      entry_valid;
    reg [2:0]                entry_umt_id;
    reg [8:0]                entry_addr;
    reg [MAX_WIDTH-1:0]      entry_data;
    reg [MAX_WIDTH-1:0]      entry_mask;
    
    // Outputs
    wire                     map_done;
    wire                     map_error;
    wire [MAX_LMTS-1:0]      lmt_used;
    wire [MAX_LMTS*8-1:0]    lmt_uid;
    wire [MAX_LMTS*8-1:0]    lmt_internal_id;
    wire [MAX_LMTS*2-1:0]    lmt_status_flag;
    wire [MAX_LMTS*2-1:0]    lmt_width_gear;
    wire [MAX_LMTS*3-1:0]    lmt_depth_gear;
    wire                     lmt_entry_valid;
    wire [2:0]               lmt_entry_id;
    wire [8:0]               lmt_entry_addr;
    wire [MAX_WIDTH-1:0]     lmt_entry_data;
    wire [MAX_WIDTH-1:0]     lmt_entry_mask;
    wire [7:0]               total_lmts_used;
    wire [15:0]              total_pmts_needed;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // DUT
    umt_top #(
        .MAX_UMTS(MAX_UMTS),
        .MAX_LMTS(MAX_LMTS),
        .MAX_WIDTH(MAX_WIDTH),
        .MAX_DEPTH(MAX_DEPTH),
        .PMT_WIDTH(PMT_WIDTH),
        .PMT_DEPTH(PMT_DEPTH),
        .MAX_PMTS_PER_LMT(MAX_PMTS_PER_LMT)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .umt_cfg_valid(umt_cfg_valid),
        .umt_cfg_wr_en(umt_cfg_wr_en),
        .umt_cfg_id(umt_cfg_id),
        .umt_cfg_width(umt_cfg_width),
        .umt_cfg_depth(umt_cfg_depth),
        .umt_cfg_type(umt_cfg_type),
        .umt_map_trigger(umt_map_trigger),
        .entry_valid(entry_valid),
        .entry_umt_id(entry_umt_id),
        .entry_addr(entry_addr),
        .entry_data(entry_data),
        .entry_mask(entry_mask),
        .map_done(map_done),
        .map_error(map_error),
        .lmt_used(lmt_used),
        .lmt_uid(lmt_uid),
        .lmt_internal_id(lmt_internal_id),
        .lmt_status_flag(lmt_status_flag),
        .lmt_width_gear(lmt_width_gear),
        .lmt_depth_gear(lmt_depth_gear),
        .lmt_entry_valid(lmt_entry_valid),
        .lmt_entry_id(lmt_entry_id),
        .lmt_entry_addr(lmt_entry_addr),
        .lmt_entry_data(lmt_entry_data),
        .lmt_entry_mask(lmt_entry_mask),
        .total_lmts_used(total_lmts_used),
        .total_pmts_needed(total_pmts_needed)
    );
    
    // Test stimulus
    initial begin
        // Initialize
        rst_n = 0;
        umt_cfg_valid = 0;
        umt_cfg_wr_en = 0;
        umt_cfg_id = 0;
        umt_cfg_width = 0;
        umt_cfg_depth = 0;
        umt_cfg_type = 0;
        umt_map_trigger = 0;
        entry_valid = 0;
        entry_umt_id = 0;
        entry_addr = 0;
        entry_data = 0;
        entry_mask = 0;
        
        #(CLK_PERIOD*10);
        rst_n = 1;
        #(CLK_PERIOD*5);
        
        $display("========================================");
        $display("Starting UMT Tests");
        $display("========================================");
        
        // ====================================================================
        // Test 1: Configure Single UMT (48b x 64) - sMAC filter
        // ====================================================================
        $display("\n[Test 1] Configure UMT 0: 48b x 64 (sMAC filter)");
        @(posedge clk);
        umt_cfg_valid = 1;
        umt_cfg_wr_en = 1;
        umt_cfg_id = 3'd0;
        umt_cfg_width = 16'd48;  // MAC address
        umt_cfg_depth = 16'd64;
        umt_cfg_type = 1'b0;     // TCAM
        
        @(posedge clk);
        umt_cfg_valid = 0;
        umt_cfg_wr_en = 0;
        #(CLK_PERIOD*5);
        
        // ====================================================================
        // Test 2: Configure UMT 1 (48b x 256) - dMAC filter (needs cascade)
        // ====================================================================
        $display("\n[Test 2] Configure UMT 1: 48b x 256 (dMAC filter, cascaded)");
        @(posedge clk);
        umt_cfg_valid = 1;
        umt_cfg_wr_en = 1;
        umt_cfg_id = 3'd1;
        umt_cfg_width = 16'd48;
        umt_cfg_depth = 16'd256;
        umt_cfg_type = 1'b0;
        
        @(posedge clk);
        umt_cfg_valid = 0;
        #(CLK_PERIOD*5);
        
        // ====================================================================
        // Test 3: Configure UMT 2 (32b x 128) - IPv4 filter
        // ====================================================================
        $display("\n[Test 3] Configure UMT 2: 32b x 128 (IPv4 filter)");
        @(posedge clk);
        umt_cfg_valid = 1;
        umt_cfg_wr_en = 1;
        umt_cfg_id = 3'd2;
        umt_cfg_width = 16'd32;
        umt_cfg_depth = 16'd128;
        umt_cfg_type = 1'b0;
        
        @(posedge clk);
        umt_cfg_valid = 0;
        #(CLK_PERIOD*5);
        
        // ====================================================================
        // Test 4: Trigger Mapping
        // ====================================================================
        $display("\n[Test 4] Trigger UMT to LMT mapping");
        @(posedge clk);
        umt_map_trigger = 1;
        
        @(posedge clk);
        umt_map_trigger = 0;
        
        // Wait for mapping to complete
        wait(map_done);
        #(CLK_PERIOD*5);
        
        $display("\n[Mapping Results]");
        $display("  Total LMTs used: %0d", total_lmts_used);
        $display("  Total PMTs needed: %0d", total_pmts_needed);
        $display("  Mapping error: %b", map_error);
        
        // Display LMT configuration
        display_lmt_config();
        
        // ====================================================================
        // Test 5: Install entries into UMT 0
        // ====================================================================
        $display("\n[Test 5] Install entries into UMT 0");
        
        @(posedge clk);
        entry_valid = 1;
        entry_umt_id = 3'd0;
        entry_addr = 9'd0;
        entry_data = 64'hAABBCCDDEEFF_0000;  // MAC address
        entry_mask = 64'hFFFFFFFFFFFF_0000;
        
        @(posedge clk);
        entry_addr = 9'd1;
        entry_data = 64'h112233445566_0000;
        entry_mask = 64'hFFFFFFFFFFFF_0000;
        
        @(posedge clk);
        entry_addr = 9'd10;
        entry_data = 64'h001122334455_0000;
        entry_mask = 64'hFFFFFFFFFFFF_0000;
        
        @(posedge clk);
        entry_valid = 0;
        
        #(CLK_PERIOD*10);
        
        // ====================================================================
        // Test 6: Install entries into cascaded UMT 1
        // ====================================================================
        $display("\n[Test 6] Install entries into cascaded UMT 1");
        
        @(posedge clk);
        entry_valid = 1;
        entry_umt_id = 3'd1;
        entry_addr = 9'd0;
        entry_data = 64'hFFEEDDCCBBAA_0000;
        entry_mask = 64'hFFFFFFFFFFFF_0000;
        
        @(posedge clk);
        entry_addr = 9'd128;  // Should go to 2nd LMT in cascade
        entry_data = 64'h998877665544_0000;
        entry_mask = 64'hFFFFFFFFFFFF_0000;
        
        @(posedge clk);
        entry_addr = 9'd200;
        entry_data = 64'hAABB00112233_0000;
        entry_mask = 64'hFFFFFFFFFFFF_0000;
        
        @(posedge clk);
        entry_valid = 0;
        
        #(CLK_PERIOD*10);
        
        // ====================================================================
        // Test 7: Test resource limits - too many UMTs
        // ====================================================================
        $display("\n[Test 7] Test resource limits");
        
        // Configure more UMTs
        @(posedge clk);
        umt_cfg_valid = 1;
        umt_cfg_wr_en = 1;
        umt_cfg_id = 3'd3;
        umt_cfg_width = 16'd64;
        umt_cfg_depth = 16'd256;
        umt_cfg_type = 1'b0;
        
        @(posedge clk);
        umt_cfg_id = 3'd4;
        umt_cfg_width = 16'd32;
        umt_cfg_depth = 16'd128;
        
        @(posedge clk);
        umt_cfg_valid = 0;
        
        #(CLK_PERIOD*5);
        
        // Try to map again
        @(posedge clk);
        umt_map_trigger = 1;
        @(posedge clk);
        umt_map_trigger = 0;
        
        wait(map_done);
        #(CLK_PERIOD*5);
        
        $display("\n[Remapping Results]");
        $display("  Total LMTs used: %0d", total_lmts_used);
        $display("  Total PMTs needed: %0d", total_pmts_needed);
        $display("  Mapping error: %b", map_error);
        
        #(CLK_PERIOD*10);
        
        $display("\n========================================");
        $display("UMT Tests Complete");
        $display("========================================");
        $finish;
    end
    
    // Task to display LMT configuration
    task display_lmt_config;
        integer i;
        reg [7:0] uid, iid;
        reg [1:0] sf, wg;
        reg [2:0] dg;
        begin
            $display("\n  LMT Configuration:");
            for (i = 0; i < MAX_LMTS; i = i + 1) begin
                if (lmt_used[i]) begin
                    uid = lmt_uid[i*8 +: 8];
                    iid = lmt_internal_id[i*8 +: 8];
                    sf = lmt_status_flag[i*2 +: 2];
                    wg = lmt_width_gear[i*2 +: 2];
                    dg = lmt_depth_gear[i*3 +: 3];
                    
                    $display("    LMT[%0d]: UMT=%0d, IntID=%0d, Status=%s, WidthGear=%0dx, DepthGear=%0dx",
                             i, uid, iid, 
                             (sf==0)?"SINGLE":(sf==1)?"START":(sf==2)?"MIDDLE":"END",
                             (1 << wg), (1 << dg));
                end
            end
        end
    endtask
    
    // Monitor outputs
    always @(posedge clk) begin
        if (lmt_entry_valid) begin
            $display("[Entry Install] LMT=%0d, Addr=%0d, Data=0x%016h, Mask=0x%016h",
                     lmt_entry_id, lmt_entry_addr, lmt_entry_data, lmt_entry_mask);
        end
    end
    
    // Timeout
    initial begin
        #500000;
        $display("ERROR: Timeout!");
        $finish;
    end
    
    // Waveform dump
    initial begin
        $dumpfile("umt_tb.vcd");
        $dumpvars(0, tb_umt);
    end

endmodule


