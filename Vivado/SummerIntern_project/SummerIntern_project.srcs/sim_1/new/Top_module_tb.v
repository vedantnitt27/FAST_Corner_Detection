`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2026 11:23:54 AM
// Design Name: 
// Module Name: Top_module_tb
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



`timescale 1ns/1ps

module Top_module_tb();

    // ═══════════════════════════════════════════════
    // CLOCK
    // ═══════════════════════════════════════════════
    reg clk = 0;
    always #5 clk = ~clk;   // 100MHz

    // ═══════════════════════════════════════════════
    // PIPELINE SIGNALS
    // ═══════════════════════════════════════════════
    wire [5:0]  x, y;
    wire [11:0] address;
    wire [7:0]  pixel;
    wire [7:0]  row0,row1,row2,row3,row4,row5,row6;
    wire        lb_valid;
    wire [7:0]  center;
    wire [7:0]  p0,p1,p2,p3,p4,p5,p6,p7;
    wire [7:0]  p8,p9,p10,p11,p12,p13,p14,p15;
    wire        corner_raw;
    wire        corner_valid;

    // ═══════════════════════════════════════════════
    // PIPELINE COORDINATE DELAY - matches Top_module
    // ═══════════════════════════════════════════════
    parameter PIPE_DEPTH = 392;

    reg [5:0] x_dly [0:PIPE_DEPTH-1];
    reg [5:0] y_dly [0:PIPE_DEPTH-1];
    integer k;

    always @(posedge clk) begin
        x_dly[0] <= x;
        y_dly[0] <= y;
        for(k = 1; k < PIPE_DEPTH; k = k+1) begin
            x_dly[k] <= x_dly[k-1];
            y_dly[k] <= y_dly[k-1];
        end
    end

    wire [5:0] corner_x = x_dly[PIPE_DEPTH-1];
    wire [5:0] corner_y = y_dly[PIPE_DEPTH-1];

    assign address     = {y, x};
    assign corner_valid = corner_raw && lb_valid;

    // ═══════════════════════════════════════════════
    // MODULE INSTANTIATIONS
    // ═══════════════════════════════════════════════

    coordinate_generator uut_coord (
        .clk (clk),
        .x   (x),
        .y   (y)
    );

    image_rom uut_rom (
        .clk     (clk),
        .en      (1'b1),
        .address (address),
        .pixel   (pixel)
    );

    line_buffer uut_lb (
        .clk   (clk),
        .pixel (pixel),
        .x     (x),
        .row0  (row0), .row1(row1), .row2(row2),
        .row3  (row3), .row4(row4), .row5(row5),
        .row6  (row6),
        .valid (lb_valid)
    );

    sliding_window uut_sw (
        .clk    (clk),
        .row0   (row0), .row1(row1), .row2(row2), .row3(row3),
        .row4   (row4), .row5(row5), .row6(row6),
        .center (center),
        .p0(p0),   .p1(p1),   .p2(p2),   .p3(p3),
        .p4(p4),   .p5(p5),   .p6(p6),   .p7(p7),
        .p8(p8),   .p9(p9),   .p10(p10), .p11(p11),
        .p12(p12), .p13(p13), .p14(p14), .p15(p15)
    );

    fast_detector uut_fast (
        .clk    (clk),
        .center (center),
        .p0(p0),   .p1(p1),   .p2(p2),   .p3(p3),
        .p4(p4),   .p5(p5),   .p6(p6),   .p7(p7),
        .p8(p8),   .p9(p9),   .p10(p10), .p11(p11),
        .p12(p12), .p13(p13), .p14(p14), .p15(p15),
        .corner (corner_raw)
    );

    // ═══════════════════════════════════════════════
    // CORNER STORAGE
    // ═══════════════════════════════════════════════
    reg [5:0] detected_x [0:255];
    reg [5:0] detected_y [0:255];
    reg [7:0] corner_count = 0;

    // Expected corners
    reg [5:0] exp_x [0:3];
    reg [5:0] exp_y [0:3];

    // ═══════════════════════════════════════════════
    // CAPTURE CORNERS ON EVERY corner_valid PULSE
    // ═══════════════════════════════════════════════
    always @(posedge clk) begin
        if(corner_valid) begin
            detected_x[corner_count] <= corner_x;
            detected_y[corner_count] <= corner_y;
            corner_count             <= corner_count + 1;

            $display("[CORNER] Detected at X=%0d Y=%0d  (clock %0t)",
                     corner_x, corner_y, $time);
        end
    end

    // ═══════════════════════════════════════════════
    // EXPECTED CORNER CHECK TASK
    // ═══════════════════════════════════════════════
    integer ci, cj;
    integer found;
    integer pass_count;
    integer false_count;
    reg corner_found [0:3];

    task check_corners;
        begin
            $display("");
            $display("══════════════════════════════════════════");
            $display("  CORNER DETECTION RESULTS");
            $display("══════════════════════════════════════════");
            $display("  Total corners detected: %0d", corner_count);
            $display("──────────────────────────────────────────");

            // Check each expected corner was found
            pass_count = 0;
            for(ci = 0; ci < 4; ci = ci+1) begin
                corner_found[ci] = 0;
                for(cj = 0; cj < corner_count; cj = cj+1) begin
                    if(detected_x[cj] == exp_x[ci] &&
                       detected_y[cj] == exp_y[ci]) begin
                        corner_found[ci] = 1;
                    end
                end

                if(corner_found[ci]) begin
                    $display("  Expected (%0d,%0d) → FOUND ✅",
                             exp_x[ci], exp_y[ci]);
                    pass_count = pass_count + 1;
                end
                else begin
                    $display("  Expected (%0d,%0d) → NOT FOUND ❌",
                             exp_x[ci], exp_y[ci]);
                end
            end

            // Check for false positives
            // (corners detected outside expected positions)
            $display("──────────────────────────────────────────");
            false_count = 0;
            for(cj = 0; cj < corner_count; cj = cj+1) begin
                found = 0;
                for(ci = 0; ci < 4; ci = ci+1) begin
                    if(detected_x[cj] == exp_x[ci] &&
                       detected_y[cj] == exp_y[ci])
                        found = 1;
                end
                if(!found) begin
                    $display("  FALSE POSITIVE at (%0d,%0d) ⚠️",
                             detected_x[cj], detected_y[cj]);
                    false_count = false_count + 1;
                end
            end

            if(false_count == 0)
                $display("  No false positives ✅");

            // Final verdict
            $display("══════════════════════════════════════════");
            if(pass_count == 4 && false_count == 0) begin
                $display("  RESULT: ALL 4 CORNERS CORRECT ✅");
                $display("  FAST detector working perfectly!");
            end
            else if(pass_count == 4 && false_count > 0) begin
                $display("  RESULT: 4/4 correct but %0d false positives ⚠️", false_count);
                $display("  Check THRESHOLD value or lb_valid gating");
            end
            else begin
                $display("  RESULT: Only %0d/4 expected corners found ❌", pass_count);
                $display("  Check PIPE_DEPTH, circle pixel mapping,");
                $display("  or THRESHOLD value");
            end
            $display("══════════════════════════════════════════");
        end
    endtask

    // ═══════════════════════════════════════════════
    // PIPELINE STATE MONITOR
    // Prints useful milestones during simulation
    // ═══════════════════════════════════════════════
    always @(posedge clk) begin
        // Print when line buffer becomes valid
        if(lb_valid && $time == 10*(384+PIPE_DEPTH+5))
            $display("[INFO] Line buffer valid at time %0t", $time);

        // Print current pixel being processed every 64 clocks
        if(x == 0 && y[0] == 0 && $time > 100)
            $display("[SCAN] Processing row y=%0d at time %0t", y, $time);
    end

    // ═══════════════════════════════════════════════
    // MAIN TEST SEQUENCE
    // ═══════════════════════════════════════════════
    initial begin

        // Setup expected corners
        exp_x[0] = 6'd16;  exp_y[0] = 6'd16;
        exp_x[1] = 6'd48;  exp_y[1] = 6'd16;
        exp_x[2] = 6'd16;  exp_y[2] = 6'd48;
        exp_x[3] = 6'd48;  exp_y[3] = 6'd48;

        $display("══════════════════════════════════════════");
        $display("  FAST Corner Detection Pipeline Testbench");
        $display("  Image: 64x64 black square on white");
        $display("  Expected corners: (16,16)(48,16)(16,48)(48,48)");
        $display("  PIPE_DEPTH = %0d", PIPE_DEPTH);
        $display("══════════════════════════════════════════");

        // ─────────────────────────────────────
        // Run for enough clocks to process
        // 2 full frames worth of pixels:
        //   Frame 1: pipeline fills up
        //   Frame 2: all corners detected
        //
        // 2 frames = 2 × 64 × 64 = 8192 pixels
        // + pipeline depth = 8192 + 392 = 8584 clocks
        // Add margin: run 10000 clocks
        // ─────────────────────────────────────
        repeat(10000) @(posedge clk);

        // Run check
        check_corners;

        $display("");
        $display("[TB] Simulation complete");
        $finish;
    end

    // ═══════════════════════════════════════════════
    // TIMEOUT WATCHDOG
    // ═══════════════════════════════════════════════
    initial begin
        #200_000; // 200us = 20000 clocks
        $display("WATCHDOG: Simulation timeout!");
        $display("Corners found so far: %0d", corner_count);
        $finish;
    end

endmodule