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

module line_buffer(
    input clk,
    input [7:0] pixel,
//    //64*64 image
//    input [5:0] x,
    
//    //128*128 image
//    input [6:0] x,
    
    //128*128 image
    input [7:0] x,
        
    output reg [7:0] row0 = 0,
    output reg [7:0] row1 = 0,
    output reg [7:0] row2 = 0,
    output reg [7:0] row3 = 0,
    output reg [7:0] row4 = 0,
    output reg [7:0] row5 = 0,
    output reg [7:0] row6 = 0,
    output reg valid = 0
);
//    for 64*64
//    reg [7:0] line1 [0:63];
//    reg [7:0] line2 [0:63];
//    reg [7:0] line3 [0:63];
//    reg [7:0] line4 [0:63];
//    reg [7:0] line5 [0:63];
//    reg [7:0] line6 [0:63];
    
    //for 128*128 image
//    reg [7:0] line1 [0:127];    // CHANGE: 63→127
//    reg [7:0] line2 [0:127];    // CHANGE: 63→127
//    reg [7:0] line3 [0:127];    // CHANGE: 63→127
//    reg [7:0] line4 [0:127];    // CHANGE: 63→127
//    reg [7:0] line5 [0:127];    // CHANGE: 63→127
//    reg [7:0] line6 [0:127];    // CHANGE: 63→127

//    for 256*256 image
    reg [7:0] line1 [0:255];    
    reg [7:0] line2 [0:255];   
    reg [7:0] line3 [0:255];  
    reg [7:0] line4 [0:255];   
    reg [7:0] line5 [0:255];    
    reg [7:0] line6 [0:255];    

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

        if(x == 255 && row_count < 15)   //We change x==?  according to image size
            row_count <= row_count + 1;

        valid <= (row_count >= 6);
    end
endmodule