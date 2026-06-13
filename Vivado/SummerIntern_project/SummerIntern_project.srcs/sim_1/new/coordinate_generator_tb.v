`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2026 12:13:58 PM
// Design Name: 
// Module Name: coordinate_generator_tb
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


module coordinate_generator_tb;
    reg clk = 0;
    wire [5:0] x;
    wire [5:0] y;

    // DUT
    coordinate_generator uut (
        .clk(clk),
        .x(x),
        .y(y)
    );

    // Clock
    always #5 clk = ~clk;

    initial begin
        #10;
        repeat(133) begin
            @(posedge clk);
            $display("x=%d y=%d", x, y);
        end
        $finish;
    end
endmodule
