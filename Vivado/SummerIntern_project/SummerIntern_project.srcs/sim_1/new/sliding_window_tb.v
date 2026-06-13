`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2026 12:25:04 PM
// Design Name: 
// Module Name: sliding_window_tb
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

module sliding_window_tb;

    reg clk = 0;

    // Inputs to sliding window
    reg [7:0] row0;
    reg [7:0] row1;
    reg [7:0] row2;
    reg [7:0] row3;
    reg [7:0] row4;
    reg [7:0] row5;
    reg [7:0] row6;

    // Outputs
    wire [7:0] center;

    wire [7:0] p0;
    wire [7:0] p1;
    wire [7:0] p2;
    wire [7:0] p3;
    wire [7:0] p4;
    wire [7:0] p5;
    wire [7:0] p6;
    wire [7:0] p7;
    wire [7:0] p8;
    wire [7:0] p9;
    wire [7:0] p10;
    wire [7:0] p11;
    wire [7:0] p12;
    wire [7:0] p13;
    wire [7:0] p14;
    wire [7:0] p15;

    // DUT
    sliding_window uut (

        .clk(clk),

        .row0(row0),
        .row1(row1),
        .row2(row2),
        .row3(row3),
        .row4(row4),
        .row5(row5),
        .row6(row6),

        .center(center),

        .p0(p0),
        .p1(p1),
        .p2(p2),
        .p3(p3),
        .p4(p4),
        .p5(p5),
        .p6(p6),
        .p7(p7),
        .p8(p8),
        .p9(p9),
        .p10(p10),
        .p11(p11),
        .p12(p12),
        .p13(p13),
        .p14(p14),
        .p15(p15)

    );

    // Clock generation
    always #5 clk = ~clk;

    integer i;

    initial begin

        // Feed known values for multiple cycles

        for(i=0; i<12; i=i+1) begin

            row0 = i;
            row1 = i + 10;
            row2 = i + 20;
            row3 = i + 30;
            row4 = i + 40;
            row5 = i + 50;
            row6 = i + 60;

            @(posedge clk);

            #1;

            $display("------------------------------------------------");

            $display("Cycle = %0d", i);

            $display("CENTER = %d", center);

            $display("p0=%d  p1=%d  p2=%d  p3=%d",
                      p0,p1,p2,p3);

            $display("p4=%d  p5=%d  p6=%d  p7=%d",
                      p4,p5,p6,p7);

            $display("p8=%d  p9=%d  p10=%d p11=%d",
                      p8,p9,p10,p11);

            $display("p12=%d p13=%d p14=%d p15=%d",
                      p12,p13,p14,p15);

        end

        $finish;

    end

endmodule
