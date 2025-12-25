`timescale 1ns/1ps

module traffic_light_tb;

    reg clk;
    reg reset;
    wire [2:0] lights;
    
    traffic_light_controller uut (
        .clk(clk),
        .reset(reset),
        .lights(lights)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        
        $display("Time\tReset\tRed\tYellow\tGreen\tState");
        $display("----\t-----\t---\t------\t-----\t-----");
        
        reset = 1;
        #20;
        reset = 0;
        
        $monitor("%0t\t%b\t%b\t%b\t%b\t%s", 
                 $time, reset, lights[2], lights[1], lights[0],
                 lights == 3'b100 ? "RED   " :
                 lights == 3'b010 ? "YELLOW" :
                 lights == 3'b001 ? "GREEN " : "UNKNOWN");
        
        #800;
        
        $display("\n--- Testing Reset ---");
        reset = 1;
        #20;
        reset = 0;
        #500;
        
        $display("\n--- Test Complete ---");
        $finish;
    end
    
    initial begin
        #2000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule