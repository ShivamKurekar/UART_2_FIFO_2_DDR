module led_wave (
    input  wire i_clk,   // 100 MHz
    input  wire en,
    output wire led_1,
    output wire led_2,
    output wire led_3,
    output wire led_4
);

    // --------------------------------------------------
    // Global time base
    // --------------------------------------------------
    reg [27:0] counter;
    wire [27:0] c1 = counter + 28'd0;
    wire [27:0] c2 = counter + 28'd1_000_000;
    wire [27:0] c3 = counter + 28'd2_000_000;
    wire [27:0] c4 = counter + 28'd3_000_000;


    // --------------------------------------------------
    // Per-LED PWM accumulators
    // --------------------------------------------------
    reg [6:0] pwm_w1;
    reg [6:0] pwm_w2;
    reg [6:0] pwm_w3;
    reg [6:0] pwm_w4;

    // --------------------------------------------------
    // Envelope values (phase shifted)
    // --------------------------------------------------
    wire [5:0] env_1;
    wire [5:0] env_2;
    wire [5:0] env_3;
    wire [5:0] env_4;

    // Phase offsets create the wave
    assign env_1 = c1[27] ?  c1[26:21] : ~c1[26:21];
    assign env_2 = c2[27] ?  c2[26:21] : ~c2[26:21];
    assign env_3 = c3[27] ?  c3[26:21] : ~c3[26:21];
    assign env_4 = c4[27] ?  c4[26:21] : ~c4[26:21];


    // --------------------------------------------------
    // Sequential logic
    // --------------------------------------------------
    always @(posedge i_clk) begin
        if (!en) begin
            counter <= 28'd0;
            pwm_w1  <= 7'd0;
            pwm_w2  <= 7'd0;
            pwm_w3  <= 7'd0;
            pwm_w4  <= 7'd0;
        end
        else begin
            counter <= counter + 1'b1;

            // Sigma-delta PWM accumulation
            pwm_w1 <= pwm_w1[5:0] + env_1;
            pwm_w2 <= pwm_w2[5:0] + env_2;
            pwm_w3 <= pwm_w3[5:0] + env_3;
            pwm_w4 <= pwm_w4[5:0] + env_4;
        end
    end

    // --------------------------------------------------
    // LED outputs
    // --------------------------------------------------
    assign led_1 = pwm_w1[6];
    assign led_2 = pwm_w2[6];
    assign led_3 = pwm_w3[6];
    assign led_4 = pwm_w4[6];

endmodule
