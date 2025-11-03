`timescale 1ns / 1ps

// Traffic Light Controller Module
module traffic_light_controller (
    input wire clk,
    input wire reset,
    output reg [2:0] lights  
);

    // State encoding
    parameter GREEN  = 2'b00;
    parameter YELLOW = 2'b01;
    parameter RED    = 2'b10;
    
    // Timing parameters (in clock cycles)
    parameter GREEN_TIME  = 30; 
    parameter YELLOW_TIME = 5;  
    parameter RED_TIME    = 30; 
    
    reg [1:0] current_state, next_state;
    reg [5:0] counter;
    
    // State register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= RED;
            counter <= 0;
        end else begin
            current_state <= next_state;
            if (current_state != next_state)
                counter <= 0;
            else
                counter <= counter + 1;
        end
    end
    
    // Next state logic
    always @(*) begin
        case (current_state)
            GREEN: begin
                if (counter >= GREEN_TIME - 1)
                    next_state = YELLOW;
                else
                    next_state = GREEN;
            end
            
            YELLOW: begin
                if (counter >= YELLOW_TIME - 1)
                    next_state = RED;
                else
                    next_state = YELLOW;
            end
            
            RED: begin
                if (counter >= RED_TIME - 1)
                    next_state = GREEN;
                else
                    next_state = RED;
            end
            
            default: next_state = RED;
        endcase
    end
    
    // Output logic
    always @(*) begin
        case (current_state)
            GREEN:  lights = 3'b001;  
            YELLOW: lights = 3'b010; 
            RED:    lights = 3'b100; 
            default: lights = 3'b000;
        endcase
    end

endmodule

