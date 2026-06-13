`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2026 12:22:29 PM
// Design Name: 
// Module Name: line_buffer_tb
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

module line_buffer_tb;

    reg clk = 0;

    reg [7:0] pixel;
    reg [5:0] x;

    wire [7:0] row0,row1,row2,row3,row4,row5,row6;

    // DUT
    line_buffer uut (
        .clk(clk),
        .pixel(pixel),
        .x(x),
        .row0(row0),
        .row1(row1),
        .row2(row2),
        .row3(row3),
        .row4(row4),
        .row5(row5),
        .row6(row6)
    );

    // Clock
    always #5 clk = ~clk;

    integer i;

    initial begin

        x = 10;

        // Feed pixels

        for(i=1; i<=10; i=i+1) begin

            pixel = i;

            @(posedge clk);

            #1;

            $display(
            "pixel=%d row0=%d row1=%d row2=%d row3=%d row4=%d row5=%d row6=%d",
            pixel,row0,row1,row2,row3,row4,row5,row6);

        end

        $finish;

    end

endmodule
