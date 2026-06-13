`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2026 11:45:12 AM
// Design Name: 
// Module Name: line_buffer
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


//module line_buffer(
//    input clk,
//    input [7:0] pixel,
//    input [5:0] x,
    
//    output reg [7:0] row0,
//    output reg [7:0] row1,
//    output reg [7:0] row2,
//    output reg [7:0] row3,
//    output reg [7:0] row4,
//    output reg [7:0] row5,
//    output reg [7:0] row6
//    );
    
//    //6 line buffers
//    reg [7:0] line1 [0:63];
//    reg [7:0] line2 [0:63];
//    reg [7:0] line3 [0:63];
//    reg [7:0] line4 [0:63];
//    reg [7:0] line5 [0:63];
//    reg [7:0] line6 [0:63];
    
//    always @(posedge clk)begin
//        //Shifting the rows down
//        line6[x] <= line5[x];
//        line5[x] <= line4[x];
//        line4[x] <= line3[x];
//        line3[x] <= line2[x];
//        line2[x] <= line1[x];
//        line1[x] <= pixel;
        
//        //Output column
//        row0 <= pixel;
//        row1 <= line1[x];
//        row2 <= line2[x];
//        row3 <= line3[x];
//        row4 <= line4[x];
//        row5 <= line5[x];
//        row6 <= line6[x];
//    end

//endmodule
module line_buffer(
    input clk,
    input [7:0] pixel,
    input [5:0] x,
    output reg [7:0] row0 = 0,
    output reg [7:0] row1 = 0,
    output reg [7:0] row2 = 0,
    output reg [7:0] row3 = 0,
    output reg [7:0] row4 = 0,
    output reg [7:0] row5 = 0,
    output reg [7:0] row6 = 0,
    output reg valid = 0
);
    reg [7:0] line1 [0:63];
    reg [7:0] line2 [0:63];
    reg [7:0] line3 [0:63];
    reg [7:0] line4 [0:63];
    reg [7:0] line5 [0:63];
    reg [7:0] line6 [0:63];

    reg [3:0] row_count = 0;

    always @(posedge clk) begin
        line6[x] <= line5[x];
        line5[x] <= line4[x];
        line4[x] <= line3[x];
        line3[x] <= line2[x];
        line2[x] <= line1[x];
        line1[x] <= pixel;

        row0 <= pixel;
        row1 <= line1[x];
        row2 <= line2[x];
        row3 <= line3[x];
        row4 <= line4[x];
        row5 <= line5[x];
        row6 <= line6[x];

        if(x == 63 && row_count < 15)
            row_count <= row_count + 1;

        valid <= (row_count >= 6);
    end
endmodule