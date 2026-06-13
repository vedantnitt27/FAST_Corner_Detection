`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2026 02:34:58 PM
// Design Name: 
// Module Name: sliding_window
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


//module sliding_window(
//    input clk,
    
//    input [7:0] row0,
//    input [7:0] row1,
//    input [7:0] row2,
//    input [7:0] row3,
//    input [7:0] row4,
//    input [7:0] row5,
//    input [7:0] row6,
    
//    //scope for improvement by using single array in some way
//    output [7:0] center,
//    output [7:0] p0,
//    output [7:0] p1,
//    output [7:0] p2,
//    output [7:0] p3,
//    output [7:0] p4,
//    output [7:0] p5,
//    output [7:0] p6,
//    output [7:0] p7,
//    output [7:0] p8,
//    output [7:0] p9,
//    output [7:0] p10,
//    output [7:0] p11,
//    output [7:0] p12,
//    output [7:0] p13,
//    output [7:0] p14,
//    output [7:0] p15
//    );
    
//    //2-D matrix used as a sliding window of 7*7 each index storing a 8bit number
//    reg [7:0] window [6:0][6:0]; 
    
//    integer i;
    
//    always @(posedge clk) begin
    
//        //shifting the input pixels to the left
//        for(i=0;i<6;i=i+1) begin
//            window[0][i] <= window[0][i+1];
//            window[1][i] <= window[1][i+1];
//            window[2][i] <= window[2][i+1];
//            window[3][i] <= window[3][i+1];
//            window[4][i] <= window[4][i+1];
//            window[5][i] <= window[5][i+1];
//            window[6][i] <= window[6][i+1];
//        end
        
//        //getting new pixels
//        window[0][6] <= row0;
//        window[1][6] <= row1;
//        window[2][6] <= row2;
//        window[3][6] <= row3;
//        window[4][6] <= row4;
//        window[5][6] <= row5;
//        window[6][6] <= row6;
//    end
    
//    //Hardcoding can be avoided by loops and some algorithm to determine the circlular pixels
//    assign center = window[3][3];
//    assign p0  = window[0][3];
//    assign p1  = window[1][4];
//    assign p2  = window[2][5];
//    assign p3  = window[3][6];
//    assign p4  = window[4][6];
//    assign p5  = window[5][6];
//    assign p6  = window[6][5];
//    assign p7  = window[6][4];
//    assign p8  = window[6][3];
//    assign p9  = window[5][2];
//    assign p10 = window[4][1];
//    assign p11 = window[3][0];
//    assign p12 = window[2][0];
//    assign p13 = window[1][0];
//    assign p14 = window[0][1];
//    assign p15 = window[0][2];
//endmodule

module sliding_window(
    input clk,
    input [7:0] row0,
    input [7:0] row1,
    input [7:0] row2,
    input [7:0] row3,
    input [7:0] row4,
    input [7:0] row5,
    input [7:0] row6,

    output [7:0] center,

    // FAST circle pixels - corrected Bresenham radius-3 circle
    output [7:0] p0,
    output [7:0] p1,
    output [7:0] p2,
    output [7:0] p3,
    output [7:0] p4,
    output [7:0] p5,
    output [7:0] p6,
    output [7:0] p7,
    output [7:0] p8,
    output [7:0] p9,
    output [7:0] p10,
    output [7:0] p11,
    output [7:0] p12,
    output [7:0] p13,
    output [7:0] p14,
    output [7:0] p15
);

    reg [7:0] window [6:0][6:0];
    integer i;

    always @(posedge clk) begin
        // Shift window left
        for(i = 0; i < 6; i = i+1) begin
            window[0][i] <= window[0][i+1];
            window[1][i] <= window[1][i+1];
            window[2][i] <= window[2][i+1];
            window[3][i] <= window[3][i+1];
            window[4][i] <= window[4][i+1];
            window[5][i] <= window[5][i+1];
            window[6][i] <= window[6][i+1];
        end
        // Insert new pixels from line buffers
        window[0][6] <= row0;
        window[1][6] <= row1;
        window[2][6] <= row2;
        window[3][6] <= row3;
        window[4][6] <= row4;
        window[5][6] <= row5;
        window[6][6] <= row6;
    end

    // Center pixel
    assign center = window[3][3];

    // --------------------------------------------------
    // FAST circle - Bresenham radius 3
    // Offsets (row, col) from center at window[3][3]:
    // --------------------------------------------------
    assign p0  = window[0][3];   // (-3,  0)
    assign p1  = window[0][4];   // (-3, +1)
    assign p2  = window[1][5];   // (-2, +2)
    assign p3  = window[2][6];   // (-1, +3)
    assign p4  = window[3][6];   // ( 0, +3)
    assign p5  = window[4][6];   // (+1, +3)
    assign p6  = window[5][5];   // (+2, +2)
    assign p7  = window[6][4];   // (+3, +1)
    assign p8  = window[6][3];   // (+3,  0)
    assign p9  = window[6][2];   // (+3, -1)
    assign p10 = window[5][1];   // (+2, -2)
    assign p11 = window[4][0];   // (+1, -3)
    assign p12 = window[3][0];   // ( 0, -3)
    assign p13 = window[2][0];   // (-1, -3)
    assign p14 = window[1][1];   // (-2, -2)
    assign p15 = window[0][2];   // (-3, -1)

endmodule

