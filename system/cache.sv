// read-only cache

// block-addresesable read-only cache
// addr used here is data array index, no offset
// uses NMRU on write (MRU updates on success read and write)
module cache_ro #(
    parameter SIZE_BLOCK = 32, // block size, in bits
    parameter BIT_TOTAL = 24, // addr length, MAX_INDEX = 1 << BIT_TOTAL
    parameter BIT_INDEX = 8, // index length
    parameter WAY = 1 // # block in a set (set-associate)
)(
    input i_clk,
    input i_rst,
    input i_en,
    input i_wrt,
    input [BIT_TOTAL-1:0] i_addr, // data array index
    input [SIZE_BLOCK-1:0] i_data,
    output logic [SIZE_BLOCK-1:0] o_data,
    output logic o_success // cache hit
);
    localparam BIT_TAG = BIT_TOTAL - BIT_INDEX; // tag length
    localparam LENGTH = 1 << BIT_INDEX; // # set
    localparam BIT_WAY = ($clog2(WAY) > 0) ? $clog2(WAY) : 1;

    // SIZE_TOTAL = LENGTH * WAY * (SIZE_BLOCK + BIT_TAG + 2), in bits
    logic [SIZE_BLOCK-1:0] cache [LENGTH-1:0][WAY-1:0];
    logic [BIT_TAG-1:0] tag [LENGTH-1:0][WAY-1:0];
    logic valid [LENGTH-1:0][WAY-1:0];
    logic [BIT_WAY-1:0] mru [LENGTH-1:0]; // most recent used

    logic [BIT_WAY-1:0] selected_way;
    logic write, read;

    always_comb begin
        selected_way = 'b0;
        write = 1'b0;
        read = 1'b0;
        if (i_en) begin
            if (i_wrt) begin: parse_write
                write = 1'b1;
                for (int way = 0; way < WAY; way += 1) begin: find_not_exist
                    if (tag [i_addr[BIT_INDEX-1:0]][way] == i_addr[BIT_TOTAL-1:BIT_INDEX] && 
                        valid [i_addr[BIT_INDEX-1:0]][way]) begin
                        write = 1'b0;
                    end
                end
                if (write) begin
                    for (int way = 0; way < WAY; way += 1) begin: find_nmru
                        if (way != mru[i_addr[BIT_INDEX-1:0]]) begin
                            selected_way = way;
                        end
                    end
                    for (int way = 0; way < WAY; way += 1) begin: find_invalid
                        if (!valid [i_addr[BIT_INDEX-1:0]][way]) begin
                            selected_way = way;
                        end
                    end
                end

            end else begin: parse_read
                for (int way = 0; way < WAY; way += 1) begin: find_exist
                    if (tag [i_addr[BIT_INDEX-1:0]][way] == i_addr[BIT_TOTAL-1:BIT_INDEX] && 
                        valid [i_addr[BIT_INDEX-1:0]][way]) begin
                        selected_way = way;
                        read = 1'b1;
                    end
                end
            end
        end
    end

    always_ff @(posedge i_clk) begin
        o_data <= 'b0;
        o_success <= 1'b0;
        if (i_rst) begin: do_reset
            for (int i = 0; i < LENGTH; i += 1) begin
                mru[i] <= 'b0; // no need
                for (int j = 0; j < WAY; j += 1) begin
                    cache [i][j][SIZE_BLOCK-1:0] <= 'b0; // no need
                    tag [i][j][BIT_TAG-1:0] <= 'b0; // no need
                    valid[i][j] <= 1'b0;
                end
            end
        end else if (write) begin: do_write
            mru[i_addr[BIT_INDEX-1:0]] <= selected_way;
            cache [i_addr[BIT_INDEX-1:0]][selected_way] <= i_data;
            tag [i_addr[BIT_INDEX-1:0]][selected_way] <= i_addr[BIT_TOTAL-1:BIT_INDEX];
            valid [i_addr[BIT_INDEX-1:0]][selected_way] <= 1'b1;
            o_data <= i_data; // reflect on write
            o_success <= 1'b1;
        end else if (read) begin: do_read
            mru[i_addr[BIT_INDEX-1:0]] <= selected_way;
            valid [i_addr[BIT_INDEX-1:0]][selected_way] <= 1'b1;
            o_data <= cache [i_addr[BIT_INDEX-1:0]][selected_way];
            o_success <= 1'b1;
        end
    end

endmodule: cache_ro


// delete mru
// create a new oneway module
