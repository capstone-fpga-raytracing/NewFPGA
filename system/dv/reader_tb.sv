module reader_tb();
    localparameter NDWORDS = 1;
    localparameter BLOCKSZ = 32*NDWORDS
    logic clk, rst;
    assign #5 clk = ~clk;
    logic [31:0] i_baseaddr, i_idx;
    logic i_en;

    logic [BLOCKSZ-1:0] o_data;
    logic o_valid, i_ready;

    logic o_ram_rd, drop_wr;
    logic [15:0] drop_wrdata;
    logic [31:0] o_ram_addr;
    logic [15:0] i_ram_data;
    logic i_ram_valid, i_ram_busy;
    logic [1:0] drop_byteenable;

    tri_reader #(
        .NDWORDS(NDWORDS)
    ) dut (
        .clk(clk),
        .reset(rst),
        .baseaddr(i_baseaddr), // const = 0
        .index(i_idx),
        .read(i_en),
        .data(o_data),
        .ovalid(o_valid),
        .iready(o_ready), // !o_busy

        .avm_m0_read(o_ram_rd),
        .avm_m0_write(drop_wr), // ignore
        .avm_m0_writedata(drop_wrdata), // ignore
        .avm_m0_address(o_ram_addr),
        .avm_m0_readdata(i_ram_data), // 2 cyles to return 1 word
        .avm_m0_readdatavalid(i_ram_valid), // 2 cyles to return 1 word
        .avm_m0_byteenable(drop_byteenable), // ignore
        .avm_m0_waitrequest(i_ram_busy) // const = 0
    );

    initial begin
        clk = 'b1;
        rst = 'b1;
        i_en = 'b0;
        i_baseaddr = 'b0;
        i_ram_data = 'b0;
        i_ram_valid = 'b0;
        i_ram_busy = 'b0;
        repeat(4) @(posedge clk);
        rst = 'b0;

        // set i_idx, i_en, i_ram_data, i_ram_valid
        // monitor o_data, o_valid, o_ready, o_ram_rd, o_ram_addr

        // without pipeline
        i_idx = 'd0;
        i_en = 'b1;
        @(posedge clk);
        i_en = 'b0;
        @(posedge clk);
        i_ram_data = 'h000a;
        i_ram_valid = 'b1;
        @(posedge clk);
        i_ram_data = 'h000b;
        i_ram_valid = 'b1;
        @(posedge clk);

        // with pipeline
        i_idx = 'd1;
        i_en = 'b1;
        @(posedge clk);
        i_en = 'b0;

        i_idx = 'd2;
        i_en = 'b1;
        @(posedge clk);
        i_en = 'b0;

        i_idx = 'd3;
        i_en = 'b1;
        @(posedge clk);
        i_en = 'b0;

        i_idx = 'd4;
        @(posedge clk);
        i_en = 'b0;

        i_idx = 'd5;
        i_en = 'b1;
        i_ram_data = 'h0001;
        i_ram_valid = 'b1;
        @(posedge clk);
        i_en = 'b0;

        i_idx = 'd6;
        i_en = 'b1;
        i_ram_data = 'h0002;
        i_ram_valid = 'b1;
        @(posedge clk);
        i_en = 'b0;

        i_idx = 'd7;
        i_ram_data = 'h0003;
        i_ram_valid = 'b1;
        @(posedge clk);
        i_en = 'b0;

        i_idx = 'd8;
        i_ram_data = 'h0004;
        i_ram_valid = 'b1;
        @(posedge clk);
        i_en = 'b0;
        // expect 0a0b in 0, 0102 in 1, 0304 in 2

    end


endmodule: reader_tb
