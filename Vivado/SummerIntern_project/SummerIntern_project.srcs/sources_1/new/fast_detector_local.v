`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/17/2026 01:33:28 PM
// Design Name: 
// Module Name: fast_detector_local
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

//LOCAL ADAPTIVE THRESHOLD VALUE ALGORITHM
module fast_detector_local(
    input clk,
    input [7:0] center,
    input [7:0] p0,  input [7:0] p1,  input [7:0] p2,  input [7:0] p3,
    input [7:0] p4,  input [7:0] p5,  input [7:0] p6,  input [7:0] p7,
    input [7:0] p8,  input [7:0] p9,  input [7:0] p10, input [7:0] p11,
    input [7:0] p12, input [7:0] p13, input [7:0] p14, input [7:0] p15,
    output reg corner
);
    // ─────────────────────────────────────
    // LOCAL ADAPTIVE THRESHOLD PARAMETERS
    // threshold = local_range × FACTOR / 256
    // local_range = max(circle,center) - min(circle,center)
    // ─────────────────────────────────────
    parameter FACTOR  = 8'd80;   // ≈31% of local contrast range
    parameter MIN_THR = 8'd8;    // floor - avoids noise triggering
    parameter MAX_THR = 8'd80;   // ceiling - avoids over-sensitivity

    // Circle pixels as indexable array
    wire [7:0] circ [0:15];
    assign circ[0]=p0;  assign circ[1]=p1;  assign circ[2]=p2;
    assign circ[3]=p3;  assign circ[4]=p4;  assign circ[5]=p5;
    assign circ[6]=p6;  assign circ[7]=p7;  assign circ[8]=p8;
    assign circ[9]=p9;  assign circ[10]=p10; assign circ[11]=p11;
    assign circ[12]=p12; assign circ[13]=p13; assign circ[14]=p14;
    assign circ[15]=p15;

    // Stage 1 registers
    reg bright [0:15];
    reg dark   [0:15];

    // Stage 2
    reg bright2 [0:31];
    reg dark2   [0:31];

    reg [8:0] upper_thresh;
    reg [8:0] lower_thresh;

    integer i;
    reg corner_comb;

    // ─────────────────────────────────────
    // STAGE 1a: Compute local threshold (combinational)
    // ─────────────────────────────────────
    reg [7:0] local_threshold;
    reg [7:0] max_val;
    reg [7:0] min_val;
    reg [7:0] raw_thr;    

    always @(*) begin

        max_val = center;
        min_val = center;

        for(i = 0; i < 16; i = i+1) begin
            if(circ[i] > max_val) max_val = circ[i];
            if(circ[i] < min_val) min_val = circ[i];
        end

        raw_thr = ((max_val - min_val) * FACTOR) >> 8;

        if(raw_thr < MIN_THR)
            local_threshold = MIN_THR;
        else if(raw_thr > MAX_THR)
            local_threshold = MAX_THR;
        else
            local_threshold = raw_thr;
    end

    // ─────────────────────────────────────
    // STAGE 1b: Threshold compare (registered)
    // Uses SAME-cycle combinational threshold
    // ─────────────────────────────────────
    always @(posedge clk) begin
        upper_thresh = {1'b0, center} + {1'b0, local_threshold};
        lower_thresh = ({1'b0, center} > {1'b0, local_threshold}) ?
                       ({1'b0, center} - {1'b0, local_threshold}) : 9'd0;

        for(i = 0; i < 16; i = i+1) begin
            if({1'b0, circ[i]} > upper_thresh) begin
                bright[i] <= 1;
                dark[i]   <= 0;
            end
            else if({1'b0, circ[i]} < lower_thresh) begin
                bright[i] <= 0;
                dark[i]   <= 1;
            end
            else begin
                bright[i] <= 0;
                dark[i]   <= 0;
            end
        end
    end
    // ─────────────────────────────────────
    // STAGE 2: Arc detection (unchanged)
    // ─────────────────────────────────────
    always @(*) begin
        for(i = 0; i < 16; i = i+1) begin
            bright2[i]    = bright[i];
            bright2[i+16] = bright[i];
            dark2[i]      = dark[i];
            dark2[i+16]   = dark[i];
        end

        corner_comb = 0;
        begin : arc_check
            integer bright_run;
            integer dark_run;
            bright_run = 0;
            dark_run   = 0;
            for(i = 0; i < 32; i = i+1) begin
                if(bright2[i]) bright_run = bright_run + 1;
                else            bright_run = 0;
                if(dark2[i])   dark_run   = dark_run + 1;
                else            dark_run   = 0;
                if(bright_run >= 9 || dark_run >= 9)
                    corner_comb = 1;
            end
        end
    end

    always @(posedge clk) begin
        corner <= corner_comb;
    end

endmodule
