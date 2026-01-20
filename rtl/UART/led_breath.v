module led_breath (
    input  i_clk,
    input  en,
    output led_1,
    output led_2,
    output led_3,
    output led_4
);

    // --------------------------------------------------
    // PWM generator (8-bit, ~390 kHz @ 100 MHz clock)
    // --------------------------------------------------
    reg [7:0] pwm_cnt = 8'd0;

    // --------------------------------------------------
    // Brightness level (0 → 255 → 0)
    // --------------------------------------------------
    reg [7:0] duty = 8'd0;
    reg       dir  = 1'b1;   // 1 = fade up, 0 = fade down

    // --------------------------------------------------
    // Breathing speed controller
    // 100 MHz / 150,000 ≈ 1.5 ms per step
    // --------------------------------------------------
    reg [17:0] breathe_cnt = 18'd0;

    always @(posedge i_clk) begin
        if (!en) begin
            // Clean disabled state
            pwm_cnt     <= 8'd0;
            breathe_cnt <= 18'd0;
            duty        <= 8'd0;
            dir         <= 1'b1;
        end
        else begin
            // PWM counter
            pwm_cnt <= pwm_cnt + 8'd1;

            // Breathing envelope timing
            if (breathe_cnt == 18'd150000) begin
                breathe_cnt <= 18'd0;

                if (dir) begin
                    if (duty < 8'd255)
                        duty <= duty + 8'd1;
                    else
                        dir <= 1'b0;
                end
                else begin
                    if (duty > 8'd0)
                        duty <= duty - 8'd1;
                    else
                        dir <= 1'b1;
                end
            end
            else begin
                breathe_cnt <= breathe_cnt + 18'd1;
            end
        end
    end

    // --------------------------------------------------
    // PWM compare
    // --------------------------------------------------
    wire pwm_out = en && (pwm_cnt < duty);

    assign led_1 = pwm_out;
    assign led_2 = pwm_out;
    assign led_3 = pwm_out;
    assign led_4 = pwm_out;

endmodule