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


//module image_rom(

//    input clk,
//    input [11:0] address,
//    output reg [7:0] pixel

//);
//    //Memory of 1 byte to 64*64=4096 PIXELS
//    reg [7:0] memory [0:4095];


//    // Load HEX file into memory
//    initial begin
//        $readmemh("square64.hex", memory);
//    end

//    // Output pixel on clock edge
//    always @(posedge clk) begin
//        pixel <= memory[address];
//    end

//endmodule

module image_rom(
    input clk,
    input en,
    input [11:0] address,
    output reg [7:0] pixel
);

    reg [7:0] memory [0:4095];

    initial begin
        $readmemh("D:/Vedant/NIT/Electronics/Summer_Intern_CSoC/Vivado/SummerIntern_project/SummerIntern_project.srcs/sources_1/new/rhombus64.hex", memory);
    end

    always @(posedge clk) begin
        if(en)
            pixel <= memory[address];
    end

endmodule