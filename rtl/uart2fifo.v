module uart2fifo (
    input i_clk,
    input data,
    output [3:0] led
);
    localparam DEPTH = 8;
    localparam DATA_WIDTH = 16;

    wire valid_in, packet_valid;
    wire [7:0] out_data, packet_data;
    
    UART_RX 
        UART_RX_inst (
        .i_Clock (i_clk),
        .i_Rx_Serial (data),
        .o_Rx_DV (valid_in),
        .o_Rx_Byte (out_data)
        );


    packetizer
        pack(
        .i_clk(i_clk),
        .i_valid(valid_in),
        .i_data(out_data),
        .o_data(packet_data),
        .o_valid(packet_valid)
        );

    
    async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) fifo (
        .i_wr_clk  (i_clk),
        .i_wr_rstn (1),
        .i_wr_en   (packet_valid),
        .i_wr_data (packet_data),
        .o_full    (led[3]),

        .i_rd_clk  (),
        .i_rd_rstn (),
        .i_rd_en   (),
        .o_rd_data (),
        .o_empty   ()
    );
endmodule //uart2fifo









