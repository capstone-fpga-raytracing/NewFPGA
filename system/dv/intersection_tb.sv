module intersection_tb();
    localparam signed MIN_T = 0;
    logic signed [31:0] i_tri [0:2][0:2]; // i_tri[0] for vertex 0
    logic signed [31:0] i_ray [0:1][0:2]; // i_ray[0] for origin(E), i_ray[1] for direction(D)
    logic signed [31:0] o_t;
    logic o_result, valid;
    logic clk, rstn, en;
    always #10 clk = ~clk;

    intersection #(
        .MIN_T(MIN_T)
    ) dut (
        .i_clk(clk),
        .i_rstn(rstn),
        .i_en(en),
        .i_tri(i_tri),
        .i_ray(i_ray),
        .o_t(o_t),
        .o_result(o_result),
        .o_valid(valid)
    );

    int test_index;
    logic error_flag;
    task automatic test(); begin
        en = 'b1;
        test_index += 'd1;
        error_flag = 1'b0;
        $display("[%0d]Test %0d begin", $time(), test_index);
        @(posedge clk);
        en = 'b0;

        /*
        if (o_normal !== ref_normal) begin
            $display("ERROR (normal): expect %h %h %h, get %h %h %h", ref_normal[0], ref_normal[1], ref_normal[2]
                    , o_normal[0], o_normal[1], o_normal[2]);
            error_flag = 1'b1;
        end

        if (o_result !== ref_result) begin
            $display("ERROR (result): expect %d, get %d", o_result, ref_result);
            error_flag = 1'b1;
        end

        if (error_flag) begin
            $stop();
        end

        $display("Test %0d end\n", test_index);
        */

    end
    endtask

    initial begin
        clk = 1'b1;
        rstn = 1'b0;
        en = 1'b0;
        repeat(10) @(posedge clk);
        rstn = 1'b1;
        test_index = 'd0;
        $display("\n[%0d]intersection: test begin\n", $time());

        i_tri[0] = '{1 << 16, 1 << 16, 1 << 16};
        i_tri[1] = '{2 << 16, 3 << 16, 2 << 16};
        i_tri[2] = '{1 << 16, 1 << 16, 3 << 16};
        i_ray[0] = '{'b0, 1 << 16, 1 << 16};
        i_ray[1] = '{3 << 16, 0.5 * (1 << 16), 1.5 * (1 << 16)};
        test();
        // expects result = 1, t = 23831 (4/11)

        @(posedge clk);
        // expects one invalid cycle

        i_tri[0] = '{'b0, 2 << 16, 'b0};
        i_tri[1] = '{-2 << 16, -2 << 16, 'b0};
        i_tri[2] = '{2 << 16, 2 << 16, 'b0};
        i_ray[0] = '{'b0, 'b0, 1 << 16};
        i_ray[1] = '{'b0, 'b0, -1 << 16};
        test();
        // expects result = 1, t = 65536 (1)

        i_tri[0] = '{'b0, 2 << 16, 'b0};
        i_tri[1] = '{-2 << 16, -2 << 16, 'b0};
        i_tri[2] = '{2 << 16, -2 << 16, 'b0};
        i_ray[0] = '{'b0, 'b0, 1 << 16};
        i_ray[1] = '{'b0, 'b0, -1 << 16};
        test();
        // expects result = 1, t = 65536 (1)

        i_tri[0] = '{'b0, 2 << 16, 'b0};
        i_tri[1] = '{-2 << 16, 2 << 16, 'b0};
        i_tri[2] = '{2 << 16, 2 << 16, 'b0};
        i_ray[0] = '{'b0, 'b0, 1 << 16};
        i_ray[1] = '{'b0, 'b0, -1 << 16};
        test();
        // expects result = 0, t = x (default in simulation of div by 0)

        i_tri[0] = '{'b0, 2 << 16, 'b0};
        i_tri[1] = '{-2 << 16, -2 << 16, 'b0};
        i_tri[2] = '{2 << 16, -2 << 16, 'b0};
        i_ray[0] = '{'b0, 'b0, 1 << 16};
        i_ray[1] = '{'b0, 'b0, -1 << 16};
        test();
        // expects result = 1, t = 65536 (1)

        repeat(100) @(posedge clk);
        $display("[%0d]intersection: test end\n", $time());
        $stop();
    end

endmodule: intersection_tb


module tri_insector_tb();
    logic clk, reset, en;
    always #10 clk = ~clk;

    logic [31:0] baseaddr;
    logic [32*6-1:0] i_ray;
    logic [31:0] i_tri_cnt;

    logic o_hit;
    logic signed [31:0] o_t;
    logic [31:0] o_tri_index;
    logic finish;

    logic o_ram_rd;
    logic [31:0] o_ram_addr;
    logic [15:0] i_ram_data;
    logic i_ram_valid, i_ram_busy;
    logic [1:0] drop_byteenable;

    tri_insector dut (
        .clk(clk),
        .reset(reset),
        .ivalid(en),
        .baseaddr(baseaddr),
        .i_ray(i_ray),
        .i_tri_cnt(i_tri_cnt),

        .o_hit(o_hit),
        .o_t(o_t),
        .o_tri_index(o_tri_index),
        .o_finish(finish),

        .avm_m0_read(o_ram_rd),
        .avm_m0_address(o_ram_addr),
        .avm_m0_readdata(i_ram_data), // 2 cyles to return 1 word
        .avm_m0_readdatavalid(i_ram_valid), // 2 cyles to return 1 word
        .avm_m0_byteenable(drop_byteenable), // ignore
        .avm_m0_waitrequest(i_ram_busy) // const = 0
    );

    // tri[0:2]
    logic signed [31:0] i_tri [0:2][0:2][0:2];
    always_comb begin
        // tri
        i_tri[0][0] = '{'b0, 2 << 16, 'b0};
        i_tri[0][1] = '{-2 << 16, -2 << 16, 'b0};
        i_tri[0][2] = '{2 << 16, 2 << 16, 'b0};
        // expects result = 1, t = 65536 (1)

        i_tri[1][0] = '{'b0, 2 << 16, 'b0};
        i_tri[1][1] = '{-2 << 16, -2 << 16, 'b0};
        i_tri[1][2] = '{2 << 16, -2 << 16, 'b0};
        // expects result = 1, t = 65536 (1)

        i_tri[2][0] = '{'b0, 2 << 16, 'b0};
        i_tri[2][1] = '{-2 << 16, 2 << 16, 'b0};
        i_tri[2][2] = '{2 << 16, 2 << 16, 'b0};
        // expects result = 0, t = x (default in simulation of div by 0)
    end

    task automatic pass_tri(
        input int tri_num); begin

        for(int i = 0; i < tri_num; i+=1) begin
            while(~o_ram_rd) @(posedge clk);
            i_ram_valid = 'b1;
            $display("[%0d]starting tri: %0d", $time(), i);
            for(int j = 0; j < 3; j+=1) begin
                for(int k = 0; k < 3; k+=1) begin
                    i_ram_data = i_tri[i][j][k][15:0];
                    @(posedge clk);
                    i_ram_data = i_tri[i][j][k][31:16];
                    @(posedge clk);
                end
            end
            $display("[%0d]finished tri: %0d", $time(), i);
            i_ram_valid = 'b0;
        end

    end endtask

    initial begin
        clk = 'b1;
        reset = 'b1;
        en = 'b0;
        i_ram_data = 'b0;
        i_ram_valid = 'b0;
        i_ram_busy = 'b0;
        repeat(6) @(posedge clk);
        reset = 'b0;
        repeat(6) @(posedge clk);
        $display("\n[%0d]tri_insector: test begin\n", $time());

        // set en, baseaddr, i_ray, i_tri_cnt, i_ram_data, i_ram_valid
        // monitor o_hit, o_t, o_tri_index, finish, o_ram_rd, o_ram_addr

        // start
        //ray[0] = '{'b0, 'b0, 1 << 16};
        ///ray[1] = '{'b0, 'b0, -1 << 16};
        i_ray = 'b0;
        i_ray[95:64] = 1 << 16;
        i_ray[191:160] = -1 << 16;

        baseaddr = 'h1000;
        i_tri_cnt = 'd3;
        en = 'b1;
        @(posedge clk);
        $display("[%0d]enabled", $time());
        en = 'b0;

        repeat (4) @(posedge clk);
        $display("[%0d]starting passing tri", $time());
        pass_tri(3);
        $display("[%0d]passing tri end", $time());

        repeat(10) @(posedge clk);
        $display("[%0d]tri_insector: test end\n", $time());
        $stop();
    end

endmodule: tri_insector_tb
