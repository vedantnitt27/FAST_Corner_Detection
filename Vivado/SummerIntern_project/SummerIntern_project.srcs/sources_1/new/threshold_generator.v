`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/17/2026 10:42:48 AM
// Design Name: 
// Module Name: threshold_generator
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

module threshold_generator(
    input  clk,
    input  [7:0] mean_brightness,
    output reg [7:0] threshold = 8'd40
);
    // Strategy:
    // threshold = mean_brightness × FACTOR / 256
    //
    // FACTOR = 64 → threshold ≈ 25% of mean
    //
    // Examples:
    //   mean=200 (bright) → 200×64/256 = 50
    //   mean=128 (normal) → 128×64/256 = 32
    //   mean=50  (dark)   → 50×64/256  = 12
    //
    // Clamped: MIN=15, MAX=80

    parameter FACTOR  = 8'd64;
    parameter MIN_THR = 8'd15;
    parameter MAX_THR = 8'd80;

    reg [15:0] raw;

    always @(posedge clk) begin
        // multiply then shift right by 8
        raw = ({8'd0, mean_brightness} * {8'd0, FACTOR}) >> 8;

        if(raw[7:0] < MIN_THR)
            threshold <= MIN_THR;
        else if(raw[7:0] > MAX_THR)
            threshold <= MAX_THR;
        else
            threshold <= raw[7:0];
    end

endmodule
