// Complete RMT System Testbench
// Tests full packet processing pipeline with reconfigurable match tables

`timescale 1ns/1ps

module tb_rmt_system;

    parameter NUM_STAGES = 5;
    parameter PHV_WIDTH = 512;
    parameter MAX_KEY_WIDTH = 64;
    parameter CLK_PERIOD = 4;  // 250 MHz
    
    // Signals
    reg clk, rst_n;
    
    // UMT Configuration
    reg                      umt_cfg_valid;
    reg                      umt_cfg_wr_en;
    reg [2:0]                umt_cfg_id;
    reg [15:0]               umt_cfg_width;
    reg [15:0]               umt_cfg_depth;
    reg                      umt_cfg_type;
    reg                      umt_map_trigger;
    wire                     map_done;
    wire                     map_error;
    
    // Entry Installation
    reg                      entry_valid;
    reg [2:0]                entry_umt_id;
    reg [7:0]                entry_addr;
    reg [MAX_KEY_WIDTH-1:0]  entry_data;
    reg [MAX_KEY_WIDTH-1:0]  entry_mask;
    
    // Key Extractor Configuration
    reg [NUM_STAGES*4-1:0]   key_field_select;
    reg [NUM_STAGES*16-1:0]  key_field_offset;
    reg [NUM_STAGES*8-1:0]   key_field_length;
    
    // Packet Processing
    reg                      pkt_valid_in;
    reg [PHV_WIDTH-1:0]      pkt_phv_in;
    reg [7:0]                pkt_umt_id_in;
    
    wire                     pkt_valid_out;
    wire [PHV_WIDTH-1:0]     pkt_phv_out;
    wire                     pkt_match_found_out;
    wire [7:0]               pkt_match_addr_out;
    wire [63:0]              pkt_action_out;
    
    // Status
    wire [7:0]               total_lmts_used;
    wire [15:0]              total_pmts_needed;
    wire [31:0]              total_searches;
    wire [31:0]              total_matches;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // DUT: Complete RMT Pipeline
    rmt_pipeline #(
        .NUM_STAGES(NUM_STAGES),
        .PHV_WIDTH(PHV_WIDTH),
        .MAX_KEY_WIDTH(MAX_KEY_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        
        // Control plane
        .umt_cfg_valid(umt_cfg_valid),
        .umt_cfg_wr_en(umt_cfg_wr_en),
        .umt_cfg_id(umt_cfg_id),
        .umt_cfg_width(umt_cfg_width),
        .umt_cfg_depth(umt_cfg_depth),
        .umt_cfg_type(umt_cfg_type),
        .umt_map_trigger(umt_map_trigger),
        .map_done(map_done),
        .map_error(map_error),
        
        // Entry installation
        .entry_valid(entry_valid),
        .entry_umt_id(entry_umt_id),
        .entry_addr(entry_addr),
        .entry_data(entry_data),
        .entry_mask(entry_mask),
        
        // Key extraction config
        .key_field_select(key_field_select),
        .key_field_offset(key_field_offset),
        .key_field_length(key_field_length),
        
        // Packet processing
        .pkt_valid_in(pkt_valid_in),
        .pkt_phv_in(pkt_phv_in),
        .pkt_umt_id_in(pkt_umt_id_in),
        .pkt_valid_out(pkt_valid_out),
        .pkt_phv_out(pkt_phv_out),
        .pkt_match_found_out(pkt_match_found_out),
        .pkt_match_addr_out(pkt_match_addr_out),
        .pkt_action_out(pkt_action_out),
        
        // Status
        .total_lmts_used(total_lmts_used),
        .total_pmts_needed(total_pmts_needed),
        .total_searches(total_searches),
        .total_matches(total_matches)
    );
   
    // Task: Configure a UMT
    task configure_umt;
        input [2:0] id;
        input [15:0] width;
        input [15:0] depth;
        input type_tcam;
        begin
            @(posedge clk);
            umt_cfg_valid = 1;
            umt_cfg_wr_en = 1;
            umt_cfg_id = id;
            umt_cfg_width = width;
            umt_cfg_depth = depth;
            umt_cfg_type = type_tcam;
            
            @(posedge clk);
            umt_cfg_valid = 0;
            umt_cfg_wr_en = 0;
            
            #(CLK_PERIOD*2);
        end
    endtask
    
    // Task: Install entry
    task install_entry;
        input [2:0] umt_id;
        input [7:0] addr;
        input [63:0] data;
        input [63:0] mask;
        begin
            @(posedge clk);
            entry_valid = 1;
            entry_umt_id = umt_id;
            entry_addr = addr;
            entry_data = data;
            entry_mask = mask;
            
            @(posedge clk);
            entry_valid = 0;
            
            #(CLK_PERIOD*2);
        end
    endtask
    
    // Task: Send packet
    task send_packet;
        input [47:0] smac;
        input [47:0] dmac;
        input [31:0] sip;
        input [31:0] dip;
        input [7:0] umt_id;
        begin
            @(posedge clk);
            pkt_valid_in = 1;
            pkt_umt_id_in = umt_id;
            
            // Build PHV (simplified packet header)
            pkt_phv_in = {PHV_WIDTH{1'b0}};
            pkt_phv_in[47:0] = smac;       // Source MAC
            pkt_phv_in[95:48] = dmac;      // Dest MAC
            pkt_phv_in[143:112] = sip;     // Source IP
            pkt_phv_in[175:144] = dip;     // Dest IP
            
            @(posedge clk);
            pkt_valid_in = 0;
            
            #(CLK_PERIOD*2);
        end
    endtask
    
    // Test Scenarios
    
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
        
        key_field_select = 0;
        key_field_offset = 0;
        key_field_length = 0;
        
        pkt_valid_in = 0;
        pkt_phv_in = 0;
        pkt_umt_id_in = 0;
        
        #(CLK_PERIOD*10);
        rst_n = 1;
        #(CLK_PERIOD*5);
        
        $display("========================================");
        $display("RMT System Test - Packet Filter Example");
        $display("========================================");
        
        // Scenario: 5-Stage Packet Filter
        // Stage 0: Filter by Source MAC (48b x 64)
        // Stage 1: Filter by Dest MAC (48b x 64)
        // Stage 2: Filter by VLAN (16b x 256)
        // Stage 3: Filter by Source IP (32b x 128)
        // Stage 4: Filter by Dest IP (32b x 128)
        
        $display("\n[Step 1] Configure 5 UMTs for packet filtering");
        
        // UMT 0: Source MAC filter
        configure_umt(3'd0, 16'd48, 16'd64, 1'b0);
        $display("  UMT 0: 48b x 64 (Source MAC)");
        
        // UMT 1: Dest MAC filter
        configure_umt(3'd1, 16'd48, 16'd64, 1'b0);
        $display("  UMT 1: 48b x 64 (Dest MAC)");
        
        // UMT 2: VLAN filter
        configure_umt(3'd2, 16'd16, 16'd256, 1'b0);
        $display("  UMT 2: 16b x 256 (VLAN)");
        
        // UMT 3: Source IP filter
        configure_umt(3'd3, 16'd32, 16'd128, 1'b0);
        $display("  UMT 3: 32b x 128 (Source IP)");
        
        // UMT 4: Dest IP filter
        configure_umt(3'd4, 16'd32, 16'd128, 1'b0);
        $display("  UMT 4: 32b x 128 (Dest IP)");
        
        // Map UMTs to LMTs
        $display("\n[Step 2] Trigger UMT to LMT mapping");
        
        @(posedge clk);
        umt_map_trigger = 1;
        @(posedge clk);
        umt_map_trigger = 0;
        
        wait(map_done);
        #(CLK_PERIOD*5);
        
        $display("  Mapping complete!");
        $display("  Total LMTs used: %0d", total_lmts_used);
        $display("  Total PMTs needed: %0d", total_pmts_needed);
        $display("  Mapping error: %b", map_error);
        
        // Configure Key Extractors
        $display("\n[Step 3] Configure key extractors for each stage");
        
        // Stage 0: Extract Source MAC (field 0)
        key_field_select[3:0] = 4'd0;
        
        // Stage 1: Extract Dest MAC (field 1)
        key_field_select[7:4] = 4'd1;
        
        // Stage 2: Extract VLAN (field 2)
        key_field_select[11:8] = 4'd2;
        
        // Stage 3: Extract Source IP (field 3)
        key_field_select[15:12] = 4'd3;
        
        // Stage 4: Extract Dest IP (field 4)
        key_field_select[19:16] = 4'd4;
        
        $display("  Key extractors configured");
        
        // ====================================================================
        // Install Filter Rules
        // ====================================================================
        $display("\n[Step 4] Install filter rules");
        
        // UMT 0: Allow specific source MACs
        install_entry(3'd0, 8'd0, 64'h001122334455_0000, 64'hFFFFFFFFFFFF_0000);
        $display("  UMT 0[0]: Allow SMAC=00:11:22:33:44:55");
        
        install_entry(3'd0, 8'd1, 64'hAABBCCDDEEFF_0000, 64'hFFFFFFFFFFFF_0000);
        $display("  UMT 0[1]: Allow SMAC=AA:BB:CC:DD:EE:FF");
        
        // UMT 1: Allow specific dest MACs
        install_entry(3'd1, 8'd0, 64'hFFEEDDCCBBAA_0000, 64'hFFFFFFFFFFFF_0000);
        $display("  UMT 1[0]: Allow DMAC=FF:EE:DD:CC:BB:AA");
        
        // UMT 3: Allow specific source IPs
        install_entry(3'd3, 8'd0, 64'h0A000001_00000000, 64'hFFFFFFFF_00000000);
        $display("  UMT 3[0]: Allow SIP=10.0.0.1");
        
        install_entry(3'd3, 8'd1, 64'h0A000002_00000000, 64'hFFFFFFFF_00000000);
        $display("  UMT 3[1]: Allow SIP=10.0.0.2");
        
        // UMT 4: Allow specific dest IPs
        install_entry(3'd4, 8'd0, 64'hC0A80001_00000000, 64'hFFFFFFFF_00000000);
        $display("  UMT 4[0]: Allow DIP=192.168.0.1");
        
        #(CLK_PERIOD*10);
        
        // Send Test Packets
        $display("\n[Step 5] Send test packets through pipeline");
        
        $display("\n  Test 1: Packet with allowed SMAC");
        send_packet(48'h001122334455, 48'hFFEEDDCCBBAA, 
                   32'h0A000001, 32'hC0A80001, 8'd0);
        #(CLK_PERIOD*30);  // Wait for pipeline
        
        $display("\n  Test 2: Packet with blocked SMAC");
        send_packet(48'h999999999999, 48'hFFEEDDCCBBAA,
                   32'h0A000001, 32'hC0A80001, 8'd0);
        #(CLK_PERIOD*30);
        
        $display("\n  Test 3: Packet with allowed SIP");
        send_packet(48'h001122334455, 48'hFFEEDDCCBBAA,
                   32'h0A000002, 32'hC0A80001, 8'd3);
        #(CLK_PERIOD*30);
        
        $display("\n  Test 4: Multiple packets in succession");
        send_packet(48'h001122334455, 48'hFFEEDDCCBBAA,
                   32'h0A000001, 32'hC0A80001, 8'd0);
        send_packet(48'hAABBCCDDEEFF, 48'hFFEEDDCCBBAA,
                   32'h0A000002, 32'hC0A80001, 8'd0);
        send_packet(48'h001122334455, 48'hFFEEDDCCBBAA,
                   32'h0B000001, 32'hC0A80001, 8'd3);
        #(CLK_PERIOD*50);
        
        // Display Statistics
        $display("\n========================================");
        $display("Final Statistics");
        $display("========================================");
        $display("  Total searches: %0d", total_searches);
        $display("  Total matches: %0d", total_matches);
        $display("  Match rate: %0d%%", (total_matches * 100) / total_searches);
        
        $display("\n========================================");
        $display("RMT System Test Complete");
        $display("========================================");
        $finish;
    end
    
    // Monitor Packet Outputs
    always @(posedge clk) begin
        if (pkt_valid_out) begin
            if (pkt_match_found_out) begin
                $display("    [OUTPUT] Packet ALLOWED - Match at addr %0d, Action=0x%02h",
                         pkt_match_addr_out, pkt_action_out[7:0]);
            end else begin
                $display("    [OUTPUT] Packet DROPPED - No match");
            end
        end
    end
    
    // Timeout
    initial begin
        #1000000;
        $display("\nERROR: Timeout!");
        $finish;
    end
    
    // Waveform dump
    initial begin
        $dumpfile("rmt_system.vcd");
        $dumpvars(0, tb_rmt_system);
    end

endmodule


// ============================================================================
// Application Example: ACL (Access Control List) Filter
// Demonstrates practical usage of RMT system
// ============================================================================

module acl_filter_example;
    
    // This is a conceptual example showing how to use the RMT system
    // for building an ACL filter in a real application
    
    /*
    Configuration Sequence:
    
    1. Define UMTs for each filtering stage:
       - UMT 0: Source MAC whitelist (48b x 1024)
       - UMT 1: Dest IP blacklist (32b x 2048)
       - UMT 2: Protocol/Port rules (48b x 512)
    
    2. Map UMTs to hardware:
       - Trigger mapper
       - Wait for map_done
       - Check for errors
    
    3. Install ACL rules:
       for each rule:
           - Determine which UMT
           - Calculate entry address
           - Write entry data and mask
    
    4. Process packets:
       - Parser extracts headers into PHV
       - PHV enters RMT pipeline
       - Each stage matches against configured table
       - Action engine executes rule (allow/deny)
       - Packet forwarded or dropped based on action
    
    5. Runtime reconfiguration:
       - Add/remove rules without stopping pipeline
       - Reconfigure table sizes if needed
       - Remap if major changes required
    
    Performance:
       - 100 Gbps throughput (250 MHz, 512-bit datapath)
       - ~1 μs latency for 5-stage pipeline
       - Line-rate packet processing
    */

endmodule