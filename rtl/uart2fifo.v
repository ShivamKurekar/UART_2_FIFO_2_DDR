module uart2fifo (
    input i_clk,
    input data,
    output [3:0] led
);
    localparam DEPTH = 32; // Should always be of 2^N 
    localparam DATA_WIDTH = 256;

    wire valid_in, packet_valid;
    wire [7:0] rx_out_data;
    wire [DATA_WIDTH-1 :0 ] packet_data;
    
    UART_RX UART_RX_inst (
        .i_Clock (i_clk),
        .i_Rx_Serial (data),
        .o_Rx_DV (valid_in),
        .o_Rx_Byte (rx_out_data)
        );


    packetizer #(.DATA_WIDTH(DATA_WIDTH))
        pack(
        .i_clk(i_clk),
        .i_valid(valid_in),
        .i_data(rx_out_data),
        .o_data(packet_data),
        .o_valid(packet_valid)
        );

    
    wire fifo_full, fifo_empty;
    wire led_wave_0, led_wave_1, led_wave_2, led_wave_3;

    async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) fifo (
        .i_wr_clk  (i_clk),
        .i_wr_rstn (1'b1),
        .i_wr_en   (packet_valid),
        .i_wr_data (packet_data),
        .o_full    (fifo_full),

        .i_rd_clk  (i_clk),
        .i_rd_rstn (1'b1),
        .i_rd_en   (),
        .o_rd_data (),
        .o_empty   (fifo_empty)
    );

    /*
    axi_master master #()(
        .
    );
    */


    led_wave
    wave (
        .i_clk(i_clk),
        .en(1),
        .led_1(led_wave_0),
        .led_2(led_wave_1),
        .led_3(led_wave_2),
        .led_4(led_wave_3)
    );

    assign led = (fifo_full)? 4'b1111 : (fifo_empty)? 4'b0001 : {led_wave_3, led_wave_2, led_wave_1, led_wave_0};
    
endmodule //uart2fifo









