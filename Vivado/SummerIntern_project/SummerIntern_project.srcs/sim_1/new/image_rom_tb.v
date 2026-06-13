`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2026 12:08:48 PM
// Design Name: 
// Module Name: image_rom_tb
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

module image_rom_tb;
    reg clk = 0;
    reg [11:0] address;
    wire [7:0] pixel;

    // DUT
    image_rom uut (
        .clk(clk),
        .address(address),
        .pixel(pixel)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Test addresses
        address = 0;
        #10;
        $display("Address=%d Pixel=%d", address, pixel);

        address = 500;
        #10;
        $display("Address=%d Pixel=%d", address, pixel);

        address = 1040;
        #10;
        $display("Address=%d Pixel=%d", address, pixel);

        address = 2080;
        #10;
        $display("Address=%d Pixel=%d", address, pixel);

        address = 4095;
        #10;
        $display("Address=%d Pixel=%d", address, pixel);

        $finish;
    end
endmodule
