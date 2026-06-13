`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/12/2026 11:23:29 AM
// Design Name: 
// Module Name: corner_score
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

module corner_score(
    input  clk,
    input  [7:0] center,
    input  [7:0] p0,  input [7:0] p1,  input [7:0] p2,  input [7:0] p3,
    input  [7:0] p4,  input [7:0] p5,  input [7:0] p6,  input [7:0] p7,
    input  [7:0] p8,  input [7:0] p9,  input [7:0] p10, input [7:0] p11,
    input  [7:0] p12, input [7:0] p13, input [7:0] p14, input [7:0] p15,
    input  [7:0] threshold,
    output reg [7:0] score
);
    // Score = sum of |circle_pixel - center| for all 16 pixels
    // Higher score = stronger corner
    reg [11:0] sum;
    wire [7:0] circ [0:15];
    assign circ[0]=p0;  assign circ[1]=p1;  assign circ[2]=p2;
    assign circ[3]=p3;  assign circ[4]=p4;  assign circ[5]=p5;
    assign circ[6]=p6;  assign circ[7]=p7;  assign circ[8]=p8;
    assign circ[9]=p9;  assign circ[10]=p10; assign circ[11]=p11;
    assign circ[12]=p12; assign circ[13]=p13; assign circ[14]=p14;
    assign circ[15]=p15;

    integer i;
    always @(posedge clk) begin
        sum = 0;
        for(i = 0; i < 16; i = i+1) begin
            if(circ[i] > center)
                sum = sum + (circ[i] - center);
            else
                sum = sum + (center - circ[i]);
        end
        // Clamp to 8 bits
        score <= (sum > 255) ? 8'd255 : sum[7:0];
    end
endmodule
