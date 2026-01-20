module packetizer #(parameter DATA_WIDTH = 16) (
    input               i_clk,
    input               i_valid,
    input       [7:0]   i_data,

    output reg  [DATA_WIDTH-1:0] o_data,
    output reg          o_valid
);

    // Assumptions:
    // - DATA_WIDTH is a multiple of 8
    // - Input is always 8-bit wide

    localparam integer BYTES_COUNT = DATA_WIDTH / 8;
    localparam integer COUNT_WIDTH = $clog2(BYTES_COUNT);

    reg [DATA_WIDTH-1:0]  shift_reg;
    reg [COUNT_WIDTH-1:0] byte_count;

    always @(posedge i_clk) begin
        o_valid <= 1'b0;

        if (i_valid) begin
            shift_reg <= {shift_reg[DATA_WIDTH-9:0], i_data};

            if (byte_count == BYTES_COUNT - 1) begin
                o_data     <= {shift_reg[DATA_WIDTH-9:0], i_data};
                byte_count <= {COUNT_WIDTH{1'b0}};
                o_valid    <= 1'b1;
            end else begin
                byte_count <= byte_count + 1'b1;
            end
        end
    end

endmodule
