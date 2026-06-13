`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2026 04:32:21 PM
// Design Name: 
// Module Name: fast_detector
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

//module fast_detector(

//    input clk,

//    input [7:0] center,

//    input [7:0] p0,
//    input [7:0] p1,
//    input [7:0] p2,
//    input [7:0] p3,
//    input [7:0] p4,
//    input [7:0] p5,
//    input [7:0] p6,
//    input [7:0] p7,
//    input [7:0] p8,
//    input [7:0] p9,
//    input [7:0] p10,
//    input [7:0] p11,
//    input [7:0] p12,
//    input [7:0] p13,
//    input [7:0] p14,
//    input [7:0] p15,

//    output reg corner

//);

//    // FAST Threshold
//    parameter THRESHOLD = 40;

//    // Circle storage
//    reg [7:0] circle [0:15];

//    // Bright/Dark flags
//    reg bright [0:31];
//    reg dark   [0:31];

//    integer i;

//    integer bright_run;
//    integer dark_run;

//    always @(posedge clk) begin

//        // ------------------------------------
//        // STORE CIRCLE PIXELS
//        // ------------------------------------

//        circle[0]  = p0;
//        circle[1]  = p1;
//        circle[2]  = p2;
//        circle[3]  = p3;
//        circle[4]  = p4;
//        circle[5]  = p5;
//        circle[6]  = p6;
//        circle[7]  = p7;
//        circle[8]  = p8;
//        circle[9]  = p9;
//        circle[10] = p10;
//        circle[11] = p11;
//        circle[12] = p12;
//        circle[13] = p13;
//        circle[14] = p14;
//        circle[15] = p15;

//        // ------------------------------------
//        // CREATE BRIGHT/DARK FLAGS
//        // Duplicate circle for wraparound
//        // ------------------------------------

//        for(i=0; i<16; i=i+1) begin

//            bright[i] = 0;
//            bright[i+16] = 0;

//            dark[i] = 0;
//            dark[i+16] = 0;

//            if(circle[i] > center + THRESHOLD) begin

//                bright[i] = 1;
//                bright[i+16] = 1;

//            end

//            else if(circle[i] < center - THRESHOLD) begin

//                dark[i] = 1;
//                dark[i+16] = 1;

//            end

//        end

//        // ------------------------------------
//        // CONTIGUOUS FAST CHECK
//        // ------------------------------------

//        bright_run = 0;
//        dark_run = 0;

//        corner <= 0;

//        for(i=0; i<32; i=i+1) begin

//            // Bright contiguous arc

//            if(bright[i])
//                bright_run = bright_run + 1;
//            else
//                bright_run = 0;

//            // Dark contiguous arc

//            if(dark[i])
//                dark_run = dark_run + 1;
//            else
//                dark_run = 0;

//            // FAST-9 decision

//            if(bright_run >= 9 || dark_run >= 9)
//                corner <= 1;

//        end
//    end
//endmodule

module fast_detector(
    input clk,
    input [7:0] center,
    input [7:0] p0,  input [7:0] p1,  input [7:0] p2,  input [7:0] p3,
    input [7:0] p4,  input [7:0] p5,  input [7:0] p6,  input [7:0] p7,
    input [7:0] p8,  input [7:0] p9,  input [7:0] p10, input [7:0] p11,
    input [7:0] p12, input [7:0] p13, input [7:0] p14, input [7:0] p15,
    output reg corner
);
    parameter THRESHOLD = 40;

    // Stage 1 registers - threshold comparison
    reg bright [0:15];
    reg dark   [0:15];
    reg [7:0]  center_r;

    // Stage 2 registers - arc detection
    reg bright2 [0:31];
    reg dark2   [0:31];

    reg [8:0] upper_thresh;
    reg [8:0] lower_thresh;

    integer i;
    reg corner_comb;

    // ─────────────────────────────────────────
    // STAGE 1: Compute bright/dark flags
    // Registered - breaks timing path in half
    // ─────────────────────────────────────────
    always @(posedge clk) begin
        upper_thresh = {1'b0, center} + THRESHOLD;
        lower_thresh = ({1'b0, center} > THRESHOLD) ?
                       ({1'b0, center} - THRESHOLD) : 9'd0;
        center_r <= center;

        for(i = 0; i < 16; i = i+1) begin
            if({1'b0, (i==0  ? p0  : i==1  ? p1  : i==2  ? p2  :
                       i==3  ? p3  : i==4  ? p4  : i==5  ? p5  :
                       i==6  ? p6  : i==7  ? p7  : i==8  ? p8  :
                       i==9  ? p9  : i==10 ? p10 : i==11 ? p11 :
                       i==12 ? p12 : i==13 ? p13 : i==14 ? p14 : p15)}
                > upper_thresh) begin
                bright[i] <= 1;
                dark[i]   <= 0;
            end
            else if({1'b0, (i==0  ? p0  : i==1  ? p1  : i==2  ? p2  :
                            i==3  ? p3  : i==4  ? p4  : i==5  ? p5  :
                            i==6  ? p6  : i==7  ? p7  : i==8  ? p8  :
                            i==9  ? p9  : i==10 ? p10 : i==11 ? p11 :
                            i==12 ? p12 : i==13 ? p13 : i==14 ? p14 : p15)}
                < lower_thresh) begin
                bright[i] <= 0;
                dark[i]   <= 1;
            end
            else begin
                bright[i] <= 0;
                dark[i]   <= 0;
            end
        end
    end

    // ─────────────────────────────────────────
    // STAGE 2: Arc detection (combinational)
    // then register output
    // ─────────────────────────────────────────
    always @(*) begin
        // Duplicate for wraparound
        for(i = 0; i < 16; i = i+1) begin
            bright2[i]    = bright[i];
            bright2[i+16] = bright[i];
            dark2[i]      = dark[i];
            dark2[i+16]   = dark[i];
        end

        // Contiguous arc check
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
