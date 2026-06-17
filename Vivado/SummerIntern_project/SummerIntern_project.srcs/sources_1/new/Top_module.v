`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2026 11:19:10 AM
// Design Name: 
// Module Name: Top_module
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

//FOR 256*256 IMAGE SIZE
module Top_module(
    input  clk,
    output tx,
    output corner_out
);

    // ═══════════════════════════════════════════════
    // WIRES
    // 256×256 = 65536 pixels = 2^16 → 16-bit address
    // x, y range 0-255 → 8-bit
    // ═══════════════════════════════════════════════
    wire [15:0] address;        // CHANGED: 13:0 → 15:0 (256×256=65536=2^16)
    wire [7:0]  pixel;
    wire [7:0]  x, y;           // CHANGED: 6:0 → 7:0 (0 to 255)
    wire [7:0]  row0,row1,row2,row3,row4,row5,row6;
    wire        lb_valid;
    wire [7:0]  center;
    wire [7:0]  p0,p1,p2,p3,p4,p5,p6,p7;
    wire [7:0]  p8,p9,p10,p11,p12,p13,p14,p15;
    wire        corner_raw;
    wire        corner_valid;
    wire        busy;

    // ═══════════════════════════════════════════════
    // UART SIGNALS
    // ═══════════════════════════════════════════════
    reg        start     = 1'b0;
    reg [7:0]  uart_data = 8'd0;
    
    // GLOBAL Adaptive threshold wires ──────────
    wire [7:0]  mean_brightness;       // output of mean_calculator
    wire [7:0]  adaptive_threshold;    // output of threshold_generator
    // ───────────────────────────────────────────

    // ═══════════════════════════════════════════════
    // PIPELINE COORDINATE DELAY
    //
    // PIPE_DEPTH = 776 for 256×256:
    //   image_rom reg        :   1 clock
    //   line_buffer 3 rows   : 768 clocks (3×256)  ← CHANGED from 384
    //   line_buffer out reg  :   1 clock
    //   sliding_window col   :   3 clocks
    //   sliding_window reg   :   1 clock
    //   fast_detector stage1 :   1 clock
    //   fast_detector stage2 :   1 clock
    //   Total                : 776 clocks           ← CHANGED from 392
    // ═══════════════════════════════════════════════
    parameter PIPE_DEPTH = 776;             // CHANGED: 392 → 776

    reg [7:0] x_dly [0:PIPE_DEPTH-1];      // CHANGED: 6:0 → 7:0
    reg [7:0] y_dly [0:PIPE_DEPTH-1];      // CHANGED: 6:0 → 7:0

    integer k;

    always @(posedge clk) begin
        x_dly[0] <= x;
        y_dly[0] <= y;
        for(k = 1; k < PIPE_DEPTH; k = k+1) begin
            x_dly[k] <= x_dly[k-1];
            y_dly[k] <= y_dly[k-1];
        end
    end

    wire [7:0] corner_x = x_dly[PIPE_DEPTH-1];   // CHANGED: 6:0 → 7:0
    wire [7:0] corner_y = y_dly[PIPE_DEPTH-1];   // CHANGED: 6:0 → 7:0

    // ═══════════════════════════════════════════════
    // ASSIGNMENTS
    // {8-bit y, 8-bit x} = 16-bit address 
    // ═══════════════════════════════════════════════
    assign address      = {y, x};          // auto 16-bit from 8+8
    assign corner_valid = corner_raw && lb_valid;
    assign corner_out   = corner_valid;

    // ═══════════════════════════════════════════════
    // CORNER STORE
    // 256 entries, 8-bit coords for 256×256
    // ═══════════════════════════════════════════════
    reg [7:0] store_x [0:1023];             // CHANGED: 6:0 → 7:0 and [0:127] -> [0:255] -> [0:511]
    reg [7:0] store_y [0:1023];             // CHANGED: 6:0 → 7:0 and [0:127] -> [0:255] -> [0:511]
    reg [9:0] store_count = 10'd0;          // stays 9-bit (counts 0-511) we change this as per req
    reg       capture_done = 1'b0;

    // ═══════════════════════════════════════════════
    // FRAME DONE DETECTION
    // y wraps 255 → 0 for 256×256
    // ═══════════════════════════════════════════════
    reg [7:0] y_prev     = 8'd0;           // CHANGED: 6:0 → 7:0
    reg       frame_done = 1'b0;

    always @(posedge clk) begin
        y_prev     <= y;
        frame_done <= (y == 8'd0 && y_prev == 8'd255);  // CHANGED: 127→255
    end

    // ═══════════════════════════════════════════════
    // CORNER CAPTURE FSM
    // Border guard: 4 to 251 for 256×256
    // ═══════════════════════════════════════════════
    always @(posedge clk) begin
        if(!capture_done) begin
            if(corner_valid
               && store_count < 10'd1023                      // CHANGED: 127->255->511->1023
               && corner_x >= 8'd4   && corner_x <= 8'd251  // CHANGED: 123→251
               && corner_y >= 8'd4   && corner_y <= 8'd251) // CHANGED: 123→251
            begin
                store_x[store_count] <= corner_x;
                store_y[store_count] <= corner_y;
                store_count          <= store_count + 1;
            end
            if(frame_done && store_count > 0)
                capture_done <= 1'b1;
        end
    end

    // ═══════════════════════════════════════════════
    // UART TRANSMIT FSM
    // coords are now full 8-bit so no padding needed
    // ═══════════════════════════════════════════════
    reg [2:0]  tx_state = 3'd0;
    reg [9:0]  tx_idx   = 10'd0;   // we change size based on storage of corners now 10(as 1023 is used)
    reg [1:0]  byte_sel = 2'd0;
    reg [31:0] gap      = 32'd0;

    always @(posedge clk) begin
        start <= 1'b0;

        case(tx_state)

            3'd0: begin
                if(capture_done) begin
                    if(gap < 32'd500_000)
                        gap <= gap + 1;
                    else begin
                        gap      <= 0;
                        tx_idx   <= 10'd0; //changing the bits size
                        byte_sel <= 2'd0;
                        tx_state <= 3'd1;
                    end
                end
            end

            3'd1: begin
                if(!busy) begin
                    case(byte_sel)
                        2'd0: uart_data <= 8'hFF;
                        2'd1: uart_data <= store_x[tx_idx];  // CHANGED: no padding needed
                        2'd2: uart_data <= store_y[tx_idx];  // CHANGED: no padding needed
                        default: uart_data <= 8'h00;
                    endcase
                    start    <= 1'b1;
                    tx_state <= 3'd2;
                end
            end

            3'd2: begin
                if(!busy) begin
                    if(byte_sel < 2'd2) begin
                        byte_sel <= byte_sel + 1;
                        tx_state <= 3'd1;
                    end
                    else begin
                        byte_sel <= 2'd0;
                        if(tx_idx < store_count - 1) begin
                            tx_idx   <= tx_idx + 1;
                            tx_state <= 3'd1;
                        end
                        else begin
                            tx_idx   <= 10'd0;  //changing the bits size
                            gap      <= 32'd0;
                            tx_state <= 3'd3;
                        end
                    end
                end
            end

            3'd3: begin
                if(gap < 32'd200_000_000)
                    gap <= gap + 1;
                else begin
                    gap      <= 0;
                    tx_state <= 3'd1;
                end
            end

            default: tx_state <= 3'd0;

        endcase
    end

    // ═══════════════════════════════════════════════
    // STAGE 1: IMAGE ROM
    // ═══════════════════════════════════════════════
    image_rom stage1 (
        .clk     (clk),
        .en      (1'b1),
        .address (address),
        .pixel   (pixel)
    );

    // ═══════════════════════════════════════════════
    // STAGE 2: COORDINATE GENERATOR
    // ═══════════════════════════════════════════════
    coordinate_generator stage2 (
        .clk (clk),
        .x   (x),
        .y   (y)
    );

    // ═══════════════════════════════════════════════
    // STAGE 3: LINE BUFFER
    // ═══════════════════════════════════════════════
    line_buffer stage3 (
        .clk   (clk),
        .pixel (pixel),
        .x     (x),
        .row0  (row0), .row1(row1), .row2(row2),
        .row3  (row3), .row4(row4), .row5(row5),
        .row6  (row6),
        .valid (lb_valid)
    );

    // ═══════════════════════════════════════════════
    // STAGE 4: SLIDING WINDOW
    // ═══════════════════════════════════════════════
    sliding_window stage4 (
        .clk    (clk),
        .row0   (row0), .row1(row1), .row2(row2), .row3(row3),
        .row4   (row4), .row5(row5), .row6(row6),
        .center (center),
        .p0(p0),   .p1(p1),   .p2(p2),   .p3(p3),
        .p4(p4),   .p5(p5),   .p6(p6),   .p7(p7),
        .p8(p8),   .p9(p9),   .p10(p10), .p11(p11),
        .p12(p12), .p13(p13), .p14(p14), .p15(p15)
    );
    
    //--------------------------------------FOR GLOBAL THRESHOLD VALUE GENERATOR---------------------------
    // ═══════════════════════════════════════════════
    // STAGE 5: MEAN CALCULATOR
    // Takes raw pixel stream from image_rom
    // Computes mean brightness per frame
    // Updates once at end of every frame
    // ═══════════════════════════════════════════════
    mean_calculator stage5 (
        .clk             (clk),
        .pixel           (pixel),      // raw pixel from ROM
        .x               (x),          // current x coordinate
        .y               (y),          // current y coordinate
        .mean_brightness (mean_brightness)
    );

    // ═══════════════════════════════════════════════
    // STAGE 6: THRESHOLD GENERATOR
    // Converts mean brightness to adaptive threshold
    // threshold = mean × 25% clamped to 15-80
    // ═══════════════════════════════════════════════
    threshold_generator stage6 (
        .clk             (clk),
        .mean_brightness (mean_brightness),
        .threshold       (adaptive_threshold)
    );
    //--------------------------------------FOR GLOBAL THRESHOLD VALUE GENERATOR---------------------------

    // ═══════════════════════════════════════════════
    // STAGE 7: FAST DETECTOR GLOBAL ADAPTIVE THRESHOLD
    // ═══════════════════════════════════════════════
    fast_detector stage7 (
        .clk    (clk),
        .center (center),
        .threshold (adaptive_threshold),
        .p0(p0),   .p1(p1),   .p2(p2),   .p3(p3),
        .p4(p4),   .p5(p5),   .p6(p6),   .p7(p7),
        .p8(p8),   .p9(p9),   .p10(p10), .p11(p11),
        .p12(p12), .p13(p13), .p14(p14), .p15(p15),
        .corner (corner_raw)
    );
    
//    // ═══════════════════════════════════════════════
//    // STAGE Alternate: FAST DETECTOR LOCAL ADAPTIVE THRESHOLD 
//    // ═══════════════════════════════════════════════
//    fast_detector_local alt_stage (
//        .clk    (clk),
//        .center (center),
//        .p0(p0),   .p1(p1),   .p2(p2),   .p3(p3),
//        .p4(p4),   .p5(p5),   .p6(p6),   .p7(p7),
//        .p8(p8),   .p9(p9),   .p10(p10), .p11(p11),
//        .p12(p12), .p13(p13), .p14(p14), .p15(p15),
//        .corner (corner_raw)
//    );

    // ═══════════════════════════════════════════════
    // STAGE 8: UART TX
    // ═══════════════════════════════════════════════
    uart_tx stage8 (
        .clk     (clk),
        .start   (start),
        .data_in (uart_data),
        .tx      (tx),
        .busy    (busy)
    );

endmodule



////FOR 128*128 image
//module Top_module(
//    input  clk,
//    output tx,
//    output corner_out
//);

//    // ═══════════════════════════════════════════════
//    // WIRES
//    // CHANGE: address 12→14 bit, x/y 6→7 bit
//    // ═══════════════════════════════════════════════
//    wire [13:0] address;        // CHANGED: 11:0 → 13:0 (128×128=16384=2^14)
//    wire [7:0]  pixel;
//    wire [6:0]  x, y;           // CHANGED: 5:0 → 6:0 (0 to 127)
//    wire [7:0]  row0,row1,row2,row3,row4,row5,row6;
//    wire        lb_valid;
//    wire [7:0]  center;
//    wire [7:0]  p0,p1,p2,p3,p4,p5,p6,p7;
//    wire [7:0]  p8,p9,p10,p11,p12,p13,p14,p15;
//    wire        corner_raw;
//    wire        corner_valid;
//    wire        busy;

//    // ═══════════════════════════════════════════════
//    // UART SIGNALS
//    // ═══════════════════════════════════════════════
//    reg        start     = 1'b0;
//    reg [7:0]  uart_data = 8'd0;

//    // ═══════════════════════════════════════════════
//    // PIPELINE COORDINATE DELAY
//    //
//    // PIPE_DEPTH = 392 for 128×128:
//    //   image_rom reg        :   1 clock
//    //   line_buffer 3 rows   : 384 clocks (3×128)  ← CHANGED from 192
//    //   line_buffer out reg  :   1 clock
//    //   sliding_window col   :   3 clocks
//    //   sliding_window reg   :   1 clock
//    //   fast_detector stage1 :   1 clock
//    //   fast_detector stage2 :   1 clock
//    //   Total                : 392 clocks           ← CHANGED from 200
//    // ═══════════════════════════════════════════════
//    parameter PIPE_DEPTH = 392;             // CHANGED: 200 → 392

//    reg [6:0] x_dly [0:PIPE_DEPTH-1];      // CHANGED: 5:0 → 6:0
//    reg [6:0] y_dly [0:PIPE_DEPTH-1];      // CHANGED: 5:0 → 6:0

//    integer k;

//    always @(posedge clk) begin
//        x_dly[0] <= x;
//        y_dly[0] <= y;
//        for(k = 1; k < PIPE_DEPTH; k = k+1) begin
//            x_dly[k] <= x_dly[k-1];
//            y_dly[k] <= y_dly[k-1];
//        end
//    end

//    wire [6:0] corner_x = x_dly[PIPE_DEPTH-1];   // CHANGED: 5:0 → 6:0
//    wire [6:0] corner_y = y_dly[PIPE_DEPTH-1];   // CHANGED: 5:0 → 6:0

//    // ═══════════════════════════════════════════════
//    // ASSIGNMENTS
//    // {7-bit y, 7-bit x} = 14-bit address ✅
//    // ═══════════════════════════════════════════════
//    assign address      = {y, x};          // auto 14-bit from 7+7
//    assign corner_valid = corner_raw && lb_valid;
//    assign corner_out   = corner_valid;

//    // ═══════════════════════════════════════════════
//    // CORNER STORE
//    // 128 entries for larger image
//    // ═══════════════════════════════════════════════
//    reg [6:0] store_x [0:127];             // CHANGED: 5:0→6:0, 31→127
//    reg [6:0] store_y [0:127];             // CHANGED: 5:0→6:0, 31→127
//    reg [6:0] store_count = 7'd0;          // CHANGED: 5:0 → 6:0
//    reg       capture_done = 1'b0;

//    // ═══════════════════════════════════════════════
//    // FRAME DONE DETECTION
//    // y wraps 127 → 0 for 128×128
//    // ═══════════════════════════════════════════════
//    reg [6:0] y_prev    = 7'd0;            // CHANGED: 5:0 → 6:0
//    reg       frame_done = 1'b0;

//    always @(posedge clk) begin
//        y_prev     <= y;
//        frame_done <= (y == 7'd0 && y_prev == 7'd127);  // CHANGED: 63→127
//    end

//    // ═══════════════════════════════════════════════
//    // CORNER CAPTURE FSM
//    // Border guard: 4 to 123 for 128×128
//    // ═══════════════════════════════════════════════
//    always @(posedge clk) begin
//        if(!capture_done) begin
//            if(corner_valid
//               && store_count < 7'd127
//               && corner_x >= 7'd4  && corner_x <= 7'd123   // CHANGED: 59→123
//               && corner_y >= 7'd4  && corner_y <= 7'd123)  // CHANGED: 59→123
//            begin
//                store_x[store_count] <= corner_x;
//                store_y[store_count] <= corner_y;
//                store_count          <= store_count + 1;
//            end
//            if(frame_done && store_count > 0)
//                capture_done <= 1'b1;
//        end
//    end

//    // ═══════════════════════════════════════════════
//    // UART TRANSMIT FSM
//    // tx_idx now 7-bit for 128 entries
//    // ═══════════════════════════════════════════════
//    reg [2:0]  tx_state = 3'd0;
//    reg [6:0]  tx_idx   = 7'd0;            // CHANGED: 4:0 → 6:0
//    reg [1:0]  byte_sel = 2'd0;
//    reg [31:0] gap      = 32'd0;

//    always @(posedge clk) begin
//        start <= 1'b0;

//        case(tx_state)

//            3'd0: begin
//                if(capture_done) begin
//                    if(gap < 32'd500_000)
//                        gap <= gap + 1;
//                    else begin
//                        gap      <= 0;
//                        tx_idx   <= 7'd0;
//                        byte_sel <= 2'd0;
//                        tx_state <= 3'd1;
//                    end
//                end
//            end

//            3'd1: begin
//                if(!busy) begin
//                    case(byte_sel)
//                        2'd0: uart_data <= 8'hFF;
//                        2'd1: uart_data <= {1'b0, store_x[tx_idx]};  // CHANGED: 2'b0→1'b0
//                        2'd2: uart_data <= {1'b0, store_y[tx_idx]};  // CHANGED: 2'b0→1'b0
//                        default: uart_data <= 8'h00;
//                    endcase
//                    start    <= 1'b1;
//                    tx_state <= 3'd2;
//                end
//            end

//            3'd2: begin
//                if(!busy) begin
//                    if(byte_sel < 2'd2) begin
//                        byte_sel <= byte_sel + 1;
//                        tx_state <= 3'd1;
//                    end
//                    else begin
//                        byte_sel <= 2'd0;
//                        if(tx_idx < store_count - 1) begin
//                            tx_idx   <= tx_idx + 1;
//                            tx_state <= 3'd1;
//                        end
//                        else begin
//                            tx_idx   <= 7'd0;
//                            gap      <= 32'd0;
//                            tx_state <= 3'd3;
//                        end
//                    end
//                end
//            end

//            3'd3: begin
//                if(gap < 32'd200_000_000)
//                    gap <= gap + 1;
//                else begin
//                    gap      <= 0;
//                    tx_state <= 3'd1;
//                end
//            end

//            default: tx_state <= 3'd0;

//        endcase
//    end

//    // ═══════════════════════════════════════════════
//    // STAGE 1: IMAGE ROM
//    // ═══════════════════════════════════════════════
//    image_rom stage1 (
//        .clk     (clk),
//        .en      (1'b1),
//        .address (address),
//        .pixel   (pixel)
//    );

//    // ═══════════════════════════════════════════════
//    // STAGE 2: COORDINATE GENERATOR
//    // ═══════════════════════════════════════════════
//    coordinate_generator stage2 (
//        .clk (clk),
//        .x   (x),
//        .y   (y)
//    );

//    // ═══════════════════════════════════════════════
//    // STAGE 3: LINE BUFFER
//    // ═══════════════════════════════════════════════
//    line_buffer stage3 (
//        .clk   (clk),
//        .pixel (pixel),
//        .x     (x),
//        .row0  (row0), .row1(row1), .row2(row2),
//        .row3  (row3), .row4(row4), .row5(row5),
//        .row6  (row6),
//        .valid (lb_valid)
//    );

//    // ═══════════════════════════════════════════════
//    // STAGE 4: SLIDING WINDOW
//    // ═══════════════════════════════════════════════
//    sliding_window stage4 (
//        .clk    (clk),
//        .row0   (row0), .row1(row1), .row2(row2), .row3(row3),
//        .row4   (row4), .row5(row5), .row6(row6),
//        .center (center),
//        .p0(p0),   .p1(p1),   .p2(p2),   .p3(p3),
//        .p4(p4),   .p5(p5),   .p6(p6),   .p7(p7),
//        .p8(p8),   .p9(p9),   .p10(p10), .p11(p11),
//        .p12(p12), .p13(p13), .p14(p14), .p15(p15)
//    );

//    // ═══════════════════════════════════════════════
//    // STAGE 5: FAST DETECTOR
//    // ═══════════════════════════════════════════════
//    fast_detector stage5 (
//        .clk    (clk),
//        .center (center),
//        .p0(p0),   .p1(p1),   .p2(p2),   .p3(p3),
//        .p4(p4),   .p5(p5),   .p6(p6),   .p7(p7),
//        .p8(p8),   .p9(p9),   .p10(p10), .p11(p11),
//        .p12(p12), .p13(p13), .p14(p14), .p15(p15),
//        .corner (corner_raw)
//    );

//    // ═══════════════════════════════════════════════
//    // STAGE 6: UART TX
//    // ═══════════════════════════════════════════════
//    uart_tx stage6 (
//        .clk     (clk),
//        .start   (start),
//        .data_in (uart_data),
//        .tx      (tx),
//        .busy    (busy)
//    );

//endmodule

// FOR 64*64 image
//module Top_module(
//    input  clk,
//    output tx,
//    output corner_out
//);

//    // ═══════════════════════════════════════════════
//    // WIRES
//    // ═══════════════════════════════════════════════
//    wire [11:0] address;
//    wire [7:0]  pixel;
//    wire [5:0]  x, y;
//    wire [7:0]  row0,row1,row2,row3,row4,row5,row6;
//    wire        lb_valid;
//    wire [7:0]  center;
//    wire [7:0]  p0,p1,p2,p3,p4,p5,p6,p7;
//    wire [7:0]  p8,p9,p10,p11,p12,p13,p14,p15;
//    wire        corner_raw;
//    wire        corner_valid;
//    wire        busy;

//    // ═══════════════════════════════════════════════
//    // UART SIGNALS
//    // ═══════════════════════════════════════════════
//    reg        start     = 1'b0;
//    reg [7:0]  uart_data = 8'd0;
    
//    // ═══════════════════════════════════════════════
//    // PIPELINE COORDINATE DELAY
//    //
//    // PIPE_DEPTH = 200:
//    //   image_rom reg        :   1 clock
//    //   line_buffer 3 rows   : 192 clocks (3×64)
//    //   line_buffer out reg  :   1 clock
//    //   sliding_window col   :   3 clocks
//    //   sliding_window reg   :   1 clock
//    //   fast_detector stage1 :   1 clock
//    //   fast_detector stage2 :   1 clock
//    //   Total                : 200 clocks
//    // ═══════════════════════════════════════════════
//    parameter PIPE_DEPTH = 200;
    
//    reg [5:0] x_dly [0:PIPE_DEPTH-1]; 
//    reg [5:0] y_dly [0:PIPE_DEPTH-1]; 
       

//    integer k;

//    always @(posedge clk) begin
//        x_dly[0] <= x;
//        y_dly[0] <= y;
//        for(k = 1; k < PIPE_DEPTH; k = k+1) begin
//            x_dly[k] <= x_dly[k-1];
//            y_dly[k] <= y_dly[k-1];
//        end
//    end

//    wire [5:0] corner_x = x_dly[PIPE_DEPTH-1];
//    wire [5:0] corner_y = y_dly[PIPE_DEPTH-1];

//    // ═══════════════════════════════════════════════
//    // ASSIGNMENTS
//    // ═══════════════════════════════════════════════
//    assign address     = {y, x};
//    assign corner_valid = corner_raw && lb_valid;
//    assign corner_out  = corner_valid;

//    // ═══════════════════════════════════════════════
//    // CORNER STORE
//    // Stores up to 32 detected corners
//    // Each entry: {x[5:0], y[5:0]} = 12 bits
//    // ═══════════════════════════════════════════════
//    reg [5:0] store_x [0:31];
//    reg [5:0] store_y [0:31];
//    reg [5:0] store_count = 0;    // how many corners stored
//    reg       capture_done = 0;   // one full frame captured

//    // Frame done detection
//    // Fires when coordinate_generator wraps y back to 0
//    reg [5:0] y_prev = 0;
//    reg       frame_done = 0;

//    always @(posedge clk) begin
//        y_prev     <= y;
//        frame_done <= (y == 0 && y_prev == 63);
//    end

//    // ═══════════════════════════════════════════════
//    // CORNER CAPTURE FSM
//    // Runs during first frame only
//    // Stores every valid corner into store arrays
//    // ═══════════════════════════════════════════════
//    always @(posedge clk) begin
//        if(!capture_done) begin
//            if(corner_valid && store_count < 63) begin
//                store_x[store_count] <= corner_x;
//                store_y[store_count] <= corner_y;
//                store_count          <= store_count + 1;
//            end
//            // Lock capture after first full frame
//            if(frame_done && store_count > 0)
//                capture_done <= 1;
//        end
//    end

//    // ═══════════════════════════════════════════════
//    // UART TRANSMIT FSM
//    // Waits for capture_done then sends all corners
//    // Format per corner: 0xFF, X, Y
//    // Repeats continuously so Python never misses
//    // ═══════════════════════════════════════════════
//    reg [2:0]  tx_state  = 3'd0;
//    reg [4:0]  tx_idx    = 5'd0;   // which corner we are sending
//    reg [1:0]  byte_sel  = 2'd0;   // 0=sync, 1=X, 2=Y
//    reg [31:0] gap       = 32'd0;

//    always @(posedge clk) begin
//        start <= 1'b0;

//        case(tx_state)

//            // ─────────────────────────────
//            // STATE 0: Wait for capture done
//            // Then wait a small startup gap
//            // ─────────────────────────────
//            3'd0: begin
//                if(capture_done) begin
//                    if(gap < 32'd500_000)
//                        gap <= gap + 1;
//                    else begin
//                        gap      <= 0;
//                        tx_idx   <= 0;
//                        byte_sel <= 0;
//                        tx_state <= 3'd1;
//                    end
//                end
//            end

//            // ─────────────────────────────
//            // STATE 1: Send next byte
//            // byte_sel: 0=0xFF, 1=X, 2=Y
//            // ─────────────────────────────
//            3'd1: begin
//                if(!busy) begin
//                    case(byte_sel)
//                        2'd0: uart_data <= 8'hFF;
//                        2'd1: uart_data <= {2'b0, store_x[tx_idx]};
//                        2'd2: uart_data <= {2'b0, store_y[tx_idx]};
//                        default: uart_data <= 8'h00;
//                    endcase
//                    start    <= 1'b1;
//                    tx_state <= 3'd2;
//                end
//            end

//            // ─────────────────────────────
//            // STATE 2: Wait for TX to finish
//            // Then advance byte/corner index
//            // ─────────────────────────────
//            3'd2: begin
//                if(!busy) begin
//                    if(byte_sel < 2'd2) begin
//                        // More bytes in this corner
//                        byte_sel <= byte_sel + 1;
//                        tx_state <= 3'd1;
//                    end
//                    else begin
//                        // Corner fully sent
//                        byte_sel <= 2'd0;
//                        if(tx_idx < store_count - 1) begin
//                            // More corners to send
//                            tx_idx   <= tx_idx + 1;
//                            tx_state <= 3'd1;
//                        end
//                        else begin
//                            // All corners sent - pause then repeat
//                            tx_idx   <= 5'd0;
//                            gap      <= 32'd0;
//                            tx_state <= 3'd3;
//                        end
//                    end
//                end
//            end

//            // ─────────────────────────────
//            // STATE 3: Gap between repeats
//            // 2 second gap so Python deduplicates
//            // ─────────────────────────────
//            3'd3: begin
//                if(gap < 32'd200_000_000)
//                    gap <= gap + 1;
//                else begin
//                    gap      <= 0;
//                    tx_state <= 3'd1;
//                end
//            end

//            default: tx_state <= 3'd0;

//        endcase
//    end

//    // ═══════════════════════════════════════════════
//    // STAGE 1: IMAGE ROM
//    // ═══════════════════════════════════════════════
//    image_rom stage1 (
//        .clk     (clk),
//        .en      (1'b1),
//        .address (address),
//        .pixel   (pixel)
//    );

//    // ═══════════════════════════════════════════════
//    // STAGE 2: COORDINATE GENERATOR
//    // ═══════════════════════════════════════════════
//    coordinate_generator stage2 (
//        .clk (clk),
//        .x   (x),
//        .y   (y)
//    );

//    // ═══════════════════════════════════════════════
//    // STAGE 3: LINE BUFFER
//    // ═══════════════════════════════════════════════
//    line_buffer stage3 (
//        .clk   (clk),
//        .pixel (pixel),
//        .x     (x),
//        .row0  (row0), .row1(row1), .row2(row2),
//        .row3  (row3), .row4(row4), .row5(row5),
//        .row6  (row6),
//        .valid (lb_valid)
//    );

//    // ═══════════════════════════════════════════════
//    // STAGE 4: SLIDING WINDOW
//    // ═══════════════════════════════════════════════
//    sliding_window stage4 (
//        .clk    (clk),
//        .row0   (row0), .row1(row1), .row2(row2), .row3(row3),
//        .row4   (row4), .row5(row5), .row6(row6),
//        .center (center),
//        .p0(p0),   .p1(p1),   .p2(p2),   .p3(p3),
//        .p4(p4),   .p5(p5),   .p6(p6),   .p7(p7),
//        .p8(p8),   .p9(p9),   .p10(p10), .p11(p11),
//        .p12(p12), .p13(p13), .p14(p14), .p15(p15)
//    );

//    // ═══════════════════════════════════════════════
//    // STAGE 5: FAST DETECTOR
//    // ═══════════════════════════════════════════════
//    fast_detector stage5 (
//        .clk    (clk),
//        .center (center),
//        .p0(p0),   .p1(p1),   .p2(p2),   .p3(p3),
//        .p4(p4),   .p5(p5),   .p6(p6),   .p7(p7),
//        .p8(p8),   .p9(p9),   .p10(p10), .p11(p11),
//        .p12(p12), .p13(p13), .p14(p14), .p15(p15),
//        .corner (corner_raw)
//    );

//    // ═══════════════════════════════════════════════
//    // STAGE 6: UART TX
//    // ═══════════════════════════════════════════════
//    uart_tx stage6 (
//        .clk     (clk),
//        .start   (start),
//        .data_in (uart_data),
//        .tx      (tx),
//        .busy    (busy)
//    );

//endmodule
