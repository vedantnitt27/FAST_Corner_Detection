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

//module coordinate_generator(
//    input clk,    
//    output reg [5:0]x=0,
//    output reg [5:0]y=0
//);
//    always @(posedge clk) begin   
//        if(x==63)begin
//            x<=0;
//            if(y==63)
//                y<=0;
//            else 
//                y<=y+1;
//        end
        
//        else begin
//            x<=x+1;
//        end       
//    end
//endmodule
module coordinate_generator(
    input clk,
    output reg [5:0] x = 0,
    output reg [5:0] y = 0
);
    always @(posedge clk) begin
        if(x == 63) begin
            x <= 0;
            if(y == 63) y <= 0;
            else        y <= y + 1;
        end
        else begin
            x <= x + 1;
        end
    end
endmodule