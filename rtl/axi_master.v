module axi_master #(parameter DATA_WIDTH = 256,
                    parameter ADDR_WIDTH = 32,
                    parameter BURST_LEN  = 16)(


    /* Global Signals */
    input i_axi_clk, i_rstn,

    /* FIFO ports */
    input [DATA_WIDTH-1 : 0] i_fifo_data;
    input i_fifo_empty,
    input i_fifo_full, 
    output  o_rd_en,
    
    /* AXI Write channel */
    output     [7:0]   o_aid,
    output reg [31:0]  o_aaddr,
    output reg [7:0]   o_alen,
    output reg [2:0]   o_asize,
    output reg [1:0]   o_aburst,
    output reg [1:0]   o_alock,
    output reg         o_avalid,
    input              i_aready,
    output reg         o_atype,      // 1 = write, 0 = read
    
    /* AXI Write Data Channel */
    output     [7:0]   o_wid,
    output reg [255:0] o_wdata,
    output     [31:0]  o_wstrb,
    output reg         o_wlast,
    output reg         o_wvalid,
    input              i_wready,

);

    /*---BUFFER LOGIC---*/
    reg [$clog2(BURST_LEN)-1 : 0] idx = 0;
    reg buffer_en, fifo_full_d;
    reg [DATA_WIDTH-1 : 0 ] buffer [0: BURST_LEN - 1];

    always @(posedge i_axi_clk or negedge i_rstn) begin
        if (!i_rstn)
            fifo_full_d <= 1'b0;
        else
            fifo_full_d <= i_fifo_full;
    end

    wire fifo_full_pulse = i_fifo_full & ~fifo_full_d;

    always @(posedge i_axi_clk or negedge i_rstn) begin

        if(!i_rstn)begin
            idx <= 1'b0;
            buffer_en <= 1'b0;
            o_rd_en <= 1'b0;
        end
        else begin

            if (fifo_full_pulse && ~buffer_en) begin
                o_rd_en <= 1'b1;
                buffer_en <= 1'b1;
            end 
            
            if (buffer_en && idx < BURST_LEN && ~i_fifo_empty) begin

                buffer[idx] <= i_fifo_data;
                
                if (idx == BURST_LEN - 1) begin
                    idx <= 0;
                    buffer_en <= 0;
                    o_rd_en <= 0;
                end
                else
                    idx <= idx + 1;
            end

        end
    end
    


    /* For starting the axi on fifo full condition */
    wire start;
    assign start = (i_fifo_full);


    reg [2:0] state, nxt_state;
    reg [8:0] wr_count;

    parameter START_ADDR = 32'h00000000,//whatever will be the addr after reading datasheet;
              TRANSACTION_ID = 8'h00,
              ALEN = BURST_LEN - 1,
              ASIZE = $clog2(DATA_WIDTH/8); // 2^ASIZE = 2^5 = 32 bytes per beat in each burst for 256 bits data width

    localparam IDLE       = 3'd0,
               WRITE_ADDR = 3'd1,
               PRE_WRITE  = 3'd2,
               WRITE_DATA = 3'd3; 

    assign o_aid = TRANSACTION_ID; // In this case (UART2DDR) transaction id is fixed
    assign -o_wid = TRANSACTION_ID; // Transaction id for write operation

    always @(posedge i_axi_clk or negedge i_rstn) begin
        if (!i_rstn)
            state <= IDLE;
        else
            state <= nxt_state;
    end
    
    always @(posedge i_axi_clk or negedge i_rstn) begin

        if(!i_rstn) begin
            o_aaddr  <= START_ADDR;
            o_alen   <= 8'd0;
            o_asize  <= 3'b000;
            o_aburst <= 2'b00;
            o_alock  <= 2'b00;
            o_avalid <= 1'b0;
            o_atype  <= 1'b0;
        end
        else begin
            
            case (state)
                IDLE: begin
                    /* Address channel */
                    o_aaddr <= START_ADDR;
                    o_avalid <= 1'b0;
                end

                WRITE_ADDR: begin
                    o_avalid <= 1'b1; // saying write address is valid and ready to send
                    o_atype <= 1'b1; // write type of operation
                    o_alen <= ALEN; // length of burst
                    o_asize <= ASIZE; // size of each beat in burst
                    o_aburst <= 2'b01; //Incrementing addrs burst
                    wr_cnt <= ALEN;
                end

                // PRE_WRITE: begin
                //     o_avalid <= 1'b0;
                    
                // end
            endcase
        end
    end

    always @(*) begin
        case (next)
            IDLE:
                nxt_state = (start) ? WRITE_ADDR : IDLE;

            WRITE_ADDR:
                nxt_state = (i_aready) ? PRE_WRITE : WRITE_ADDR;

            PRE_WRITE:
                nxt_state = WRITE_DATA;
             
            default: state <= nxt_state;
        endcase
    end


endmodule // axi_master