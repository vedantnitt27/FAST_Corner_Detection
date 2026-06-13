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

module Top_module(
    input  clk,
    output tx,
    output corner_out
);

    // ═══════════════════════════════════════════════
    // WIRES
    // ═══════════════════════════════════════════════
    wire [11:0] address;
    wire [7:0]  pixel;
    wire [5:0]  x, y;
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

    // ═══════════════════════════════════════════════
    // PIPELINE COORDINATE DELAY
    //
    // PIPE_DEPTH = 200:
    //   image_rom reg        :   1 clock
    //   line_buffer 3 rows   : 192 clocks (3×64)
    //   line_buffer out reg  :   1 clock
    //   sliding_window col   :   3 clocks
    //   sliding_window reg   :   1 clock
    //   fast_detector stage1 :   1 clock
    //   fast_detector stage2 :   1 clock
    //   Total                : 200 clocks
    // ═══════════════════════════════════════════════
    parameter PIPE_DEPTH = 200;

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

    // ═══════════════════════════════════════════════
    // ASSIGNMENTS
    // ═══════════════════════════════════════════════
    assign address     = {y, x};
    assign corner_valid = corner_raw && lb_valid;
    assign corner_out  = corner_valid;

    // ═══════════════════════════════════════════════
    // CORNER STORE
    // Stores up to 32 detected corners
    // Each entry: {x[5:0], y[5:0]} = 12 bits
    // ═══════════════════════════════════════════════
    reg [5:0] store_x [0:31];
    reg [5:0] store_y [0:31];
    reg [5:0] store_count = 0;    // how many corners stored
    reg       capture_done = 0;   // one full frame captured

    // Frame done detection
    // Fires when coordinate_generator wraps y back to 0
    reg [5:0] y_prev = 0;
    reg       frame_done = 0;

    always @(posedge clk) begin
        y_prev     <= y;
        frame_done <= (y == 0 && y_prev == 63);
    end

    // ═══════════════════════════════════════════════
    // CORNER CAPTURE FSM
    // Runs during first frame only
    // Stores every valid corner into store arrays
    // ═══════════════════════════════════════════════
    always @(posedge clk) begin
        if(!capture_done) begin
            if(corner_valid && store_count < 63) begin
                store_x[store_count] <= corner_x;
                store_y[store_count] <= corner_y;
                store_count          <= store_count + 1;
            end
            // Lock capture after first full frame
            if(frame_done && store_count > 0)
                capture_done <= 1;
        end
    end

    // ═══════════════════════════════════════════════
    // UART TRANSMIT FSM
    // Waits for capture_done then sends all corners
    // Format per corner: 0xFF, X, Y
    // Repeats continuously so Python never misses
    // ═══════════════════════════════════════════════
    reg [2:0]  tx_state  = 3'd0;
    reg [4:0]  tx_idx    = 5'd0;   // which corner we are sending
    reg [1:0]  byte_sel  = 2'd0;   // 0=sync, 1=X, 2=Y
    reg [31:0] gap       = 32'd0;

    always @(posedge clk) begin
        start <= 1'b0;

        case(tx_state)

            // ─────────────────────────────
            // STATE 0: Wait for capture done
            // Then wait a small startup gap
            // ─────────────────────────────
            3'd0: begin
                if(capture_done) begin
                    if(gap < 32'd500_000)
                        gap <= gap + 1;
                    else begin
                        gap      <= 0;
                        tx_idx   <= 0;
                        byte_sel <= 0;
                        tx_state <= 3'd1;
                    end
                end
            end

            // ─────────────────────────────
            // STATE 1: Send next byte
            // byte_sel: 0=0xFF, 1=X, 2=Y
            // ─────────────────────────────
            3'd1: begin
                if(!busy) begin
                    case(byte_sel)
                        2'd0: uart_data <= 8'hFF;
                        2'd1: uart_data <= {2'b0, store_x[tx_idx]};
                        2'd2: uart_data <= {2'b0, store_y[tx_idx]};
                        default: uart_data <= 8'h00;
                    endcase
                    start    <= 1'b1;
                    tx_state <= 3'd2;
                end
            end

            // ─────────────────────────────
            // STATE 2: Wait for TX to finish
            // Then advance byte/corner index
            // ─────────────────────────────
            3'd2: begin
                if(!busy) begin
                    if(byte_sel < 2'd2) begin
                        // More bytes in this corner
                        byte_sel <= byte_sel + 1;
                        tx_state <= 3'd1;
                    end
                    else begin
                        // Corner fully sent
                        byte_sel <= 2'd0;
                        if(tx_idx < store_count - 1) begin
                            // More corners to send
                            tx_idx   <= tx_idx + 1;
                            tx_state <= 3'd1;
                        end
                        else begin
                            // All corners sent - pause then repeat
                            tx_idx   <= 5'd0;
                            gap      <= 32'd0;
                            tx_state <= 3'd3;
                        end
                    end
                end
            end

            // ─────────────────────────────
            // STATE 3: Gap between repeats
            // 2 second gap so Python deduplicates
            // ─────────────────────────────
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

    // ═══════════════════════════════════════════════
    // STAGE 5: FAST DETECTOR
    // ═══════════════════════════════════════════════
    fast_detector stage5 (
        .clk    (clk),
        .center (center),
        .p0(p0),   .p1(p1),   .p2(p2),   .p3(p3),
        .p4(p4),   .p5(p5),   .p6(p6),   .p7(p7),
        .p8(p8),   .p9(p9),   .p10(p10), .p11(p11),
        .p12(p12), .p13(p13), .p14(p14), .p15(p15),
        .corner (corner_raw)
    );

    // ═══════════════════════════════════════════════
    // STAGE 6: UART TX
    // ═══════════════════════════════════════════════
    uart_tx stage6 (
        .clk     (clk),
        .start   (start),
        .data_in (uart_data),
        .tx      (tx),
        .busy    (busy)
    );

endmodule
