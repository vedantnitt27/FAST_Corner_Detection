`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2026 10:41:06 AM
// Design Name: 
// Module Name: pixel_stream_tb
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


module pixel_stream_tb();
    reg clk;
    wire [7:0] pixel;
    
    Top_module ins (.clk(clk),.pixel(pixel));
    
    initial begin
        clk =0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        #500;
        $finish;
    end
    
    always @(posedge clk)begin 
        $display("Time=%0t  Pixel=%h",$time,pixel);
    end 
    
    
endmodule
