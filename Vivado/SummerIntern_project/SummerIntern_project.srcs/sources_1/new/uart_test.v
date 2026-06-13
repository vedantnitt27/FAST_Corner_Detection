module uart_corner_test(
    input  clk,
    output tx
);

    parameter CLKS_PER_BIT = 868;

    // UART signals
    reg        start    = 0;
    reg [7:0]  data_in  = 0;
    wire       busy;

    // FSM
    reg [3:0]  state    = 0;
    reg [31:0] gap      = 0;

    // Hardcoded corner data to send
    // Format: FF, X, Y for each corner
    reg [7:0] packet [0:11];

    initial begin
        packet[0]  = 8'hFF; packet[1]  = 8'd16; packet[2]  = 8'd16;
        packet[3]  = 8'hFF; packet[4]  = 8'd48; packet[5]  = 8'd16;
        packet[6]  = 8'hFF; packet[7]  = 8'd16; packet[8]  = 8'd48;
        packet[9]  = 8'hFF; packet[10] = 8'd48; packet[11] = 8'd48;
    end

    reg [3:0] byte_idx = 0;

    uart_tx tx_inst (
        .clk     (clk),
        .start   (start),
        .data_in (data_in),
        .tx      (tx),
        .busy    (busy)
    );

    always @(posedge clk) begin
        start <= 0;

        case(state)

            // Small startup gap
            4'd0: begin
                if(gap < 32'd500000)
                    gap <= gap + 1;
                else begin
                    gap      <= 0;
                    byte_idx <= 0;
                    state    <= 4'd1;
                end
            end

            // Send next byte
            4'd1: begin
                if(!busy) begin
                    data_in  <= packet[byte_idx];
                    start    <= 1;
                    state    <= 4'd2;
                end
            end

            // Wait for transmission to finish
            4'd2: begin
                if(!busy) begin
                    if(byte_idx < 11) begin
                        byte_idx <= byte_idx + 1;
                        state    <= 4'd1;
                    end
                    else begin
                        // All 12 bytes sent
                        // Wait then repeat
                        byte_idx <= 0;
                        gap      <= 0;
                        state    <= 4'd3;
                    end
                end
            end

            // Gap between repetitions
            4'd3: begin
                if(gap < 32'd2000000)
                    gap <= gap + 1;
                else begin
                    gap   <= 0;
                    state <= 4'd1;
                end
            end

        endcase
    end

endmodule