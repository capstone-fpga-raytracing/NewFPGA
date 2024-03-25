module reader_tb();
    localparam NDWORDS = 1;
    localparam BLOCKSZ = 32*NDWORDS;
    logic clk, rst;
    always #10 clk = ~clk;
    logic [31:0] i_baseaddr, i_idx;
    logic en;

    logic [BLOCKSZ-1:0] o_data;
    logic valid, o_ready;

    logic o_ram_rd;
    logic [31:0] o_ram_addr;
    logic [15:0] i_ram_data;
    logic i_ram_valid, i_ram_busy;
    logic [1:0] drop_byteenable;

    reader #(
        .NDWORDS(NDWORDS)
    ) dut (
        .clk(clk),
        .reset(rst),
        .baseaddr(i_baseaddr), // const = 0
        .index(i_idx),
        .read(en),
        .data(o_data),
        .ovalid(valid),
        .iready(o_ready), // ~o_busy

        .avm_m0_read(o_ram_rd),
        .avm_m0_address(o_ram_addr),
        .avm_m0_readdata(i_ram_data), // 2 cyles to return 1 word
        .avm_m0_readdatavalid(i_ram_valid), // 2 cyles to return 1 word
        .avm_m0_byteenable(drop_byteenable), // ignore
        .avm_m0_waitrequest(i_ram_busy) // const = 0
    );

    initial begin

        repeat(19) @(posedge clk);
        i_ram_data = 'h0001;
        i_ram_valid = 'b1;
        @(posedge clk);
        i_ram_data = 'h0002;
        i_ram_valid = 'b1;
        @(posedge clk)
        i_ram_valid = 1'b0;

        repeat(10) @(posedge clk);
        i_ram_data = 'h0003;
        i_ram_valid = 'b1;
        @(posedge clk);
        i_ram_data = 'h0004;
        i_ram_valid = 'b1;
        @(posedge clk)
        i_ram_valid = 1'b0;

    end

    initial begin
        clk = 'b1;
        rst = 'b1;
        en = 'b0;
        i_baseaddr = 'b0;
        i_ram_data = 'b0;
        i_ram_valid = 'b0;
        i_ram_busy = 'b0;
        repeat(6) @(posedge clk);
        rst = 'b0;
        $display("\n[%0d]reader: test begin\n", $time());

        // set i_idx, en, i_ram_data, i_ram_valid
        // monitor o_data, valid, o_ready, o_ram_rd, o_ram_addr

        // without pipeline
        i_idx = 'd0;
        en = 'b1;
        @(posedge clk);
        en = 'b0;
        repeat (4) @(posedge clk);
        i_ram_data = 'h000a;
        i_ram_valid = 'b1;
        @(posedge clk);
        i_ram_data = 'h000b;
        i_ram_valid = 'b1;
        @(posedge clk);
        i_ram_valid = 'b0;

        // with pipeline
        repeat(2) @(posedge clk);
        i_idx = 'd1;
        en = 'b1;
        @(posedge clk);
        en = 'b0;

        i_idx = 'd2;
        en = 'b1;
        @(posedge clk);
        en = 'b0;

        i_idx = 'd3;
        @(posedge clk);

        i_idx = 'd4;
        @(posedge clk);

        i_idx = 'd5;
        @(posedge clk);

        i_idx = 'd6;
        @(posedge clk);

        i_idx = 'd7;   
        @(posedge clk);

        i_idx = 'd8;
        @(posedge clk);

        // expect 0b0a in 0, 0201 in 1, 0403 in 2
        repeat(11) @(posedge clk);
        i_idx= 'd0;
        //@(posedge o_ready);
        en = 'b1;
        @(posedge clk);
        en = 'b0;

        i_idx= 'd1;
       // @(posedge o_ready);
        en = 'b1;
        @(posedge clk);
        en = 'b0;

        i_idx= 'd2;
        //@(posedge o_ready);
        en = 'b1;
        @(posedge clk);
        en = 'b0;

        repeat(20) @(posedge clk);
        $display("[%0d]reader: test end\n", $time());
        $stop();
    end

endmodule: reader_tb
