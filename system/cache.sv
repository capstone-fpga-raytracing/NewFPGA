// cache arch:

// data read cache controller (one per pixel core)
// one-cycle cache (one read port, one for each data type)
// avalon slave to accept read request from computing modules
// avalon master to send read request to sdram if not cached
// and send write request to sdram

// intersection module (multiple per pixel core)
// avalon master to send read request to cache controller

// shading module (one per pixel core)
// avalon master to send read request to cache controller

// rw queues are in avalon agents



// block-addresesable read-only cache (no offset)
// addr used here is data array index
// uses NMRU on write (MRU updates on rw)
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
    output logic o_success
);
    localparam BIT_TAG = BIT_TOTAL - BIT_INDEX; // tag length
    localparam LENGTH = 1 << BIT_INDEX; // # set

    // cache
    // SIZE_TOTAL = LENGTH * WAY * (SIZE_BLOCK + BIT_TAG + 2)
    logic [SIZE_BLOCK-1:0] cache [LENGTH-1:0][WAY-1:0];
    logic [BIT_TAG-1:0] tag [LENGTH-1:0][WAY-1:0];
    logic valid [LENGTH-1:0][WAY-1:0];
    logic mru [LENGTH-1:0][WAY-1:0]; // most recently used

    int mru_way, selected_way;
    bit exist, invalid, write, read;

    always_comb begin
        mru_way = 'b0;
        selected_way = 'b0;
        exist = 0;
        invalid = 0;
        write = 0;
        read = 0;
        if (i_en) begin
            if (i_wrt) begin: parse_write
                for (int way = 0; way < WAY; way += 1) begin: find_not_exist
                    if (tag [i_addr[BIT_INDEX-1:0]][way] == i_addr[BIT_TOTAL-1:BIT_INDEX] && 
                        valid [i_addr[BIT_INDEX-1:0]][way]) begin
                        exist = 1;
                    end
                end
                if (!exist) begin: find_invalid
                    for (int way = 0; way < WAY; way += 1) begin
                        if (!valid [i_addr[BIT_INDEX-1:0]][way]) begin
                            selected_way = way;
                            invalid = 1;
                        end
                    end
                end
                if (!invalid) begin: find_NMRU
                    for (int way = 0; way < WAY; way += 1) begin
                        if (!mru [i_addr[BIT_INDEX-1:0]][way]) begin
                            selected_way = way;
                        end
                    end
                end

                if (!exist) write = 1;

            end else begin: parse_read
                for (int way = 0; way < WAY; way += 1) begin: find_exist
                    if (tag [i_addr[BIT_INDEX-1:0]][way] == i_addr[BIT_TOTAL-1:BIT_INDEX] && 
                        valid [i_addr[BIT_INDEX-1:0]][way]) begin
                        selected_way = way;
                        exist = 1;
                    end
                end
                if (exist) begin: find_MRU
                    for (int way = 0; way < WAY; way += 1) begin
                        if (mru [i_addr[BIT_INDEX-1:0]][way]) begin
                            mru_way = way;
                        end
                    end
                end

                if (exist) read = 1;
            end
        end
    end

    always_ff @(posedge i_clk) begin
        o_data <= 'b0;
        o_success <= 0;
        if (i_rst) begin: do_reset
            for (int i = 0; i < LENGTH; i += 1) begin
                for (int j = 0; j < WAY; j += 1) begin
                    cache[i][j][SIZE_BLOCK-1:0] <= 'b0;
                    tag[i][j][BIT_TAG-1:0] <= 'b0;
                    valid[i][j] <= 0;
                    mru[i][j] <= 0;
                end
            end
        end else if (write) begin: do_write
            cache [i_addr[BIT_INDEX-1:0]][selected_way] <= i_data;
            tag [i_addr[BIT_INDEX-1:0]][selected_way] <= i_addr[BIT_TOTAL-1:BIT_INDEX];
            valid [i_addr[BIT_INDEX-1:0]][selected_way] <= 1;
				o_data <= i_data; // reflect
            o_success <= 1;
        end else if (read) begin: do_read
            if (mru_way != selected_way) mru [i_addr[BIT_INDEX-1:0]][mru_way] <= 0;
            mru [i_addr[BIT_INDEX-1:0]][selected_way] <= 1;
            valid [i_addr[BIT_INDEX-1:0]][selected_way] <= 1;
            o_data <= cache [i_addr[BIT_INDEX-1:0]][selected_way];
            o_success <= 1;
        end
    end

endmodule: cache_ro

