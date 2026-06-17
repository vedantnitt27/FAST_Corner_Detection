`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2026 11:13:28 AM
// Design Name: 
// Module Name: coordinate_generator
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

module coordinate_generator(
    input clk,
//    64*64
//    output reg [5:0] x = 0,
//    output reg [5:0] y = 0

//    128*128
//    output reg [6:0] x = 0,
//    output reg [6:0] y = 0

//    256*256
    output reg [7:0] x = 0,
    output reg [7:0] y = 0
); 
    always @(posedge clk) begin 
        if(x == 255) begin   //x==63 for 64*64 and x==127 for 128*128 and x==255 for 256*256
            x <= 0;
            if(y == 255) y <= 0;  //y==63 for 64*64 and y==127 for 128*128 and y==255 for 256*256
            else        y <= y + 1;
        end
        else begin
            x <= x + 1;
        end
    end
endmodule