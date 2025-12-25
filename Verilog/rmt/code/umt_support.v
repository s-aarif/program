`timescale 1ns / 1ps
module umt_csr_interface #(
    parameter CSR_ADDR_WIDTH = 16,
    parameter CSR_DATA_WIDTH = 32
) (
    input  wire                          clk,
    input  wire                          rst_n,
    
    // CSR Bus Interface (from PCIe/host)
    input  wire                          csr_valid,
    input  wire                          csr_write,
    input  wire [CSR_ADDR_WIDTH-1:0]     csr_addr,
    input  wire [CSR_DATA_WIDTH-1:0]     csr_wdata,
    output reg  [CSR_DATA_WIDTH-1:0]     csr_rdata,
    output reg                           csr_ready,
    
    // UMT Configuration Outputs
    output reg                           umt_cfg_valid,
    output reg                           umt_cfg_wr_en,
    output reg  [2:0]                    umt_cfg_id,
    output reg  [15:0]                   umt_cfg_width,
    output reg  [15:0]                   umt_cfg_depth,
    output reg                           umt_cfg_type,
    output reg                           umt_map_trigger,
    
    // Entry Write Outputs
    output reg                           entry_valid,
    output reg  [2:0]                    entry_umt_id,
    output reg  [8:0]                    entry_addr,
    output reg  [63:0]                   entry_data,
    output reg  [63:0]                   entry_mask,
    
    // Status Inputs
    input  wire                          map_done,
    input  wire                          map_error,
    input  wire [7:0]                    total_lmts_used,
    input  wire [15:0]                   total_pmts_needed
);

    // CSR Address Map
    localparam ADDR_UMT_CTRL        = 16'h0000;
    localparam ADDR_UMT_CONFIG_ID   = 16'h0004;
    localparam ADDR_UMT_CONFIG_SIZE = 16'h0008;
    localparam ADDR_UMT_CONFIG_TYPE = 16'h000C;
    localparam ADDR_UMT_MAP_TRIGGER = 16'h0010;
    localparam ADDR_UMT_STATUS      = 16'h0014;
    localparam ADDR_ENTRY_CTRL      = 16'h0020;
    localparam ADDR_ENTRY_ADDR      = 16'h0024;
    localparam ADDR_ENTRY_DATA_LO   = 16'h0028;
    localparam ADDR_ENTRY_DATA_HI   = 16'h002C;
    localparam ADDR_ENTRY_MASK_LO   = 16'h0030;
    localparam ADDR_ENTRY_MASK_HI   = 16'h0034;
    
    // CSR Registers
    reg [31:0] reg_umt_ctrl;
    reg [31:0] reg_umt_config_id;
    reg [31:0] reg_umt_config_size;
    reg [31:0] reg_umt_config_type;
    reg [31:0] reg_entry_ctrl;
    reg [31:0] reg_entry_addr;
    reg [31:0] reg_entry_data_lo;
    reg [31:0] reg_entry_data_hi;
    reg [31:0] reg_entry_mask_lo;
    reg [31:0] reg_entry_mask_hi;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            csr_rdata <= 32'd0;
            csr_ready <= 1'b0;
            reg_umt_ctrl <= 32'd0;
            reg_umt_config_id <= 32'd0;
            reg_umt_config_size <= 32'd0;
            reg_umt_config_type <= 32'd0;
            reg_entry_ctrl <= 32'd0;
            reg_entry_addr <= 32'd0;
            reg_entry_data_lo <= 32'd0;
            reg_entry_data_hi <= 32'd0;
            reg_entry_mask_lo <= 32'd0;
            reg_entry_mask_hi <= 32'd0;
            
            umt_cfg_valid <= 1'b0;
            umt_cfg_wr_en <= 1'b0;
            umt_map_trigger <= 1'b0;
            entry_valid <= 1'b0;
        end else begin
            // Default values
            csr_ready <= 1'b0;
            umt_cfg_valid <= 1'b0;
            umt_cfg_wr_en <= 1'b0;
            umt_map_trigger <= 1'b0;
            entry_valid <= 1'b0;
            
            if (csr_valid) begin
                csr_ready <= 1'b1;
                
                if (csr_write) begin
                    // Write operations
                    case (csr_addr)
                        ADDR_UMT_CTRL: begin
                            reg_umt_ctrl <= csr_wdata;
                            if (csr_wdata[0]) begin  // Config enable
                                umt_cfg_valid <= 1'b1;
                                umt_cfg_wr_en <= 1'b1;
                            end
                        end
                        ADDR_UMT_CONFIG_ID:   reg_umt_config_id <= csr_wdata;
                        ADDR_UMT_CONFIG_SIZE: reg_umt_config_size <= csr_wdata;
                        ADDR_UMT_CONFIG_TYPE: reg_umt_config_type <= csr_wdata;
                        ADDR_UMT_MAP_TRIGGER: begin
                            if (csr_wdata[0]) umt_map_trigger <= 1'b1;
                        end
                        ADDR_ENTRY_CTRL: begin
                            reg_entry_ctrl <= csr_wdata;
                            if (csr_wdata[0]) entry_valid <= 1'b1;
                        end
                        ADDR_ENTRY_ADDR:     reg_entry_addr <= csr_wdata;
                        ADDR_ENTRY_DATA_LO:  reg_entry_data_lo <= csr_wdata;
                        ADDR_ENTRY_DATA_HI:  reg_entry_data_hi <= csr_wdata;
                        ADDR_ENTRY_MASK_LO:  reg_entry_mask_lo <= csr_wdata;
                        ADDR_ENTRY_MASK_HI:  reg_entry_mask_hi <= csr_wdata;
                    endcase
                end else begin
                    // Read operations
                    case (csr_addr)
                        ADDR_UMT_CTRL:        csr_rdata <= reg_umt_ctrl;
                        ADDR_UMT_CONFIG_ID:   csr_rdata <= reg_umt_config_id;
                        ADDR_UMT_CONFIG_SIZE: csr_rdata <= reg_umt_config_size;
                        ADDR_UMT_CONFIG_TYPE: csr_rdata <= reg_umt_config_type;
                        ADDR_UMT_STATUS:      csr_rdata <= {map_error, map_done, 6'd0, 
                                                             total_lmts_used, total_pmts_needed};
                        ADDR_ENTRY_CTRL:      csr_rdata <= reg_entry_ctrl;
                        ADDR_ENTRY_ADDR:      csr_rdata <= reg_entry_addr;
                        ADDR_ENTRY_DATA_LO:   csr_rdata <= reg_entry_data_lo;
                        ADDR_ENTRY_DATA_HI:   csr_rdata <= reg_entry_data_hi;
                        ADDR_ENTRY_MASK_LO:   csr_rdata <= reg_entry_mask_lo;
                        ADDR_ENTRY_MASK_HI:   csr_rdata <= reg_entry_mask_hi;
                        default:              csr_rdata <= 32'hDEADBEEF;
                    endcase
                end
            end
            
            // Update outputs from registers
            umt_cfg_id <= reg_umt_config_id[2:0];
            umt_cfg_width <= reg_umt_config_size[15:0];
            umt_cfg_depth <= reg_umt_config_size[31:16];
            umt_cfg_type <= reg_umt_config_type[0];
            
            entry_umt_id <= reg_entry_ctrl[10:8];
            entry_addr <= reg_entry_addr[8:0];
            entry_data <= {reg_entry_data_hi, reg_entry_data_lo};
            entry_mask <= {reg_entry_mask_hi, reg_entry_mask_lo};
        end
    end

endmodule