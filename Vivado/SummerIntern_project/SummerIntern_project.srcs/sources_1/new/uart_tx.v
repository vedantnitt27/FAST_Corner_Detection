`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2026 10:48:46 AM
// Design Name: 
// Module Name: uart_tx
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

module uart_tx(
    input clk,
    input start,
    input [7:0] data_in,
    output reg tx,
    output reg busy
);
    parameter CLKS_PER_BIT = 868;

    reg [15:0] clk_count = 0;
    reg [3:0]  bit_index = 0;
    reg [9:0]  tx_data   = 0;

    initial begin
        tx   = 1;
        busy = 0;
    end

    always @(posedge clk) begin
        if(start && ~busy) begin
            busy      <= 1;
            tx        <= 0;
            tx_data   <= {1'b1, data_in, 1'b0};
            bit_index <= 0;
            clk_count <= 1;
        end
        else if(busy) begin
            tx <= tx_data[bit_index];
            if(clk_count < CLKS_PER_BIT - 1) begin
                clk_count <= clk_count + 1;
            end
            else begin
                clk_count <= 0;
                if(bit_index < 9)
                    bit_index <= bit_index + 1;
                else begin
                    busy      <= 0;
                    tx        <= 1;
                    bit_index <= 0;
                end
            end
        end
        else begin
            tx <= 1;
        end
    end
endmodule