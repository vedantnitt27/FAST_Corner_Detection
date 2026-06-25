`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2026 10:12:28 AM
// Design Name: 
// Module Name: image_rom
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

module image_rom(
    input clk,
    input en,
    //input [11:0] address, 64*64
    //input [13:0] address, 128*128
    input [15:0] address, //256*256
    output reg [7:0] pixel
);
    //64*64 image
    //reg [7:0] memory [0:4095];
    
    //128*128 image
    //reg [7:0] memory [0:16383];
    
    //256*256 image
    reg [7:0] memory [0:65535];

    initial begin
        $readmemh("D:/Vedant/NIT/Electronics/Summer_Intern_CSoC/Vivado/SummerIntern_project/SummerIntern_project.srcs/sources_1/new/test_image1_256.hex", memory);
    end

    always @(posedge clk) begin
        if(en)
            pixel <= memory[address];
    end

endmodule