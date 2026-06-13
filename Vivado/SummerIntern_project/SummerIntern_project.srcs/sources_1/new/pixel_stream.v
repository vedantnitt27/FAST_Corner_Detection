`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2026 10:31:52 AM
// Design Name: 
// Module Name: pixel_stream
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


module pixel_stream(
    input clk,
    output [7:0] pixel
    );
    
    //Address counter 
    reg [11:0] address=0;
    
    //Incrementer
    always @(posedge clk)begin
        address <= address+1;
    end
    
    image_rom ins (.clk(clk),.pixel(pixel),.address(address));
    
endmodule
