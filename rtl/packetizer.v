module packetizer (
    input i_clk,
    input i_valid,
    input [7:0] i_data,
    output [15:0] o_data,
    output o_valid
);
    reg count = 0;
    reg r_valid;
    reg [15:0] r_data;
    reg [7:0] temp_data;

    always @(posedge i_clk) begin
        r_valid <= 0;
        if(i_valid) begin
            
            if(!count) begin
                temp_data <= i_data;
                count <= count + 1;
            end
            else begin
                r_data <= {temp_data, i_data};
                count <= 0;
                r_valid <= 1;
            end
        end
    end

    assign o_data = r_data;
    assign o_valid = r_valid;

endmodule //packetizer