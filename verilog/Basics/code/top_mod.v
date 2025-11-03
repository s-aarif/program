`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.09.2025 12:52:05
// Design Name: 
// Module Name: mux_dmux_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Top module integrating 4:1 MUX and 1:4 DMUX with demonstration logic
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module mux_dmux_top(
    // Inputs
    input wire        clk,
    input wire        rst_n,
    input wire [3:0]  mux_inputs,
    input wire [1:0]  mux_select,
    input wire        dmux_data_in,
    input wire [1:0]  dmux_select,
    input wire        dmux_enable,
    
    // Outputs
    output wire       mux_output,
    output wire [3:0] dmux_outputs,
    
    // Status indicators
    output wire [1:0] status_led
);

    // =========================================================================
    // Signal Declarations
    // =========================================================================
    wire mux_out;
    wire [3:0] dmux_out;
    
    // =========================================================================
    // Module Instantiations
    // =========================================================================
    
    // Fix: Remove duplicate assignment in mux module by using only one implementation
    mux i_mux (
        .I(mux_inputs),
        .S(mux_select),
        .Y(mux_out)
    );
    
    dmux i_dmux (
        .Data_in(dmux_data_in),
        .S(dmux_select),
        .Enable(dmux_enable),
        .O(dmux_out)
    );
    
    // =========================================================================
    // Output Assignments
    // =========================================================================
    assign mux_output = mux_out;
    assign dmux_outputs = dmux_out;
    
    // =========================================================================
    // Status Logic
    // =========================================================================
    assign status_led[0] = mux_out;           // MUX output status
    assign status_led[1] = |dmux_out;         // Any DMUX output active

endmodule

// =============================================================================
// Corrected MUX Module (fixed duplicate assignment)
// =============================================================================

