`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/17/2026 10:41:18 AM
// Design Name: 
// Module Name: mean_calculator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module mean_calculator(
    input  clk,
    input  [7:0] pixel,
    input  [7:0] x,
    input  [7:0] y,
    output reg [7:0] mean_brightness = 8'd128
);
    // Accumulator needs to hold 256×256×255 = 16,711,680
    // 2^24 = 16,777,216 → 24 bits sufficient
    reg [23:0] accumulator = 24'd0;

    always @(posedge clk) begin
        // Accumulate every pixel
        accumulator <= accumulator + {16'd0, pixel};

        // At last pixel of frame (x=255, y=255)
        // Compute mean = sum / 65536 = sum >> 16
        if(x == 8'd255 && y == 8'd255) begin
            mean_brightness <= accumulator[23:16];  // divide by 65536
            accumulator     <= 24'd0;               // reset for next frame
        end
    end

endmodule
