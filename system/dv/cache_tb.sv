module cache_ro_tb();
    localparam SIZE_BLOCK = 32; // block size, in bits
    localparam BIT_TOTAL = 24; // addr length, MAX_INDEX = 1 << BIT_TOTAL
    localparam BIT_INDEX = 5; // index length

    logic clk;
    always #10 clk = ~clk;
    logic rst;
    logic en;
    logic wrt;
    logic [BIT_TOTAL-1:0] i_addr;
    logic [SIZE_BLOCK-1:0] i_data;
    logic [SIZE_BLOCK-1:0] o_data;
    logic o_success;
    cache_ro #(.SIZE_BLOCK(SIZE_BLOCK), .BIT_TOTAL(BIT_TOTAL), .BIT_INDEX(BIT_INDEX))
               dut (clk, rst, en, wrt, i_addr, i_data, o_data, o_success);

    // TO DO: replace with data structure
    logic [SIZE_BLOCK-1:0] correct_data;
    logic success;

    int test_index;
    logic error_flag;

    task automatic test(
        input dut_wrt,
        input [BIT_TOTAL-1:0] dut_addr,
        input [SIZE_BLOCK-1:0] dut_data
    ); begin

        test_index += 'd1;
        error_flag = 1'b0;

        en = 1;
        wrt = dut_wrt;
        i_addr = dut_addr;
        i_data = dut_data;
        @(posedge clk);
        #1; // avoid delta cycle
        en = 0;

        if (o_success !== success) begin
            $display("[%0d]Test %0d ERROR! Got o_success: %0d from %h, should be %h", $time(), test_index, o_success, dut_addr, success);
            error_flag = 1'b1;
        end
        if (o_data !== correct_data) begin
            $display("[%0d]Test %0d ERROR! Got o_data: %h from %h, should be %h", $time(), test_index, o_data, dut_addr, correct_data);
            error_flag = 1'b1;
        end

        /*if (error_flag) begin
            $stop();
        end*/
    end endtask: test

    initial begin
        clk = 1;
        rst = 1;
        en = 0;
        wrt = 0;
        i_addr = 'b0;
        i_data = 'b0;
        repeat(5) @(posedge clk);
        rst = 0;
        $display("\n[%0d]cache_ro: test begin\n", $time());
        $display("TO DO: reference not implemented. all outputs are treated as errors");

        test(1, 'd3, 'ha);
        test(0, 'd3, 'h0);
        test(1, 'd4, 'hb);
        test(0, 'd4, 'h0);
        test(1, 'd5, 'hc);
        test(0, 'd5, 'h0);
        test(1, 'd0, 'he);
        test(0, 'd0, 'h0);
        test(1, 'd32, 'h1);
        test(0, 'd32, 'h0);
        test(1, 'd64, 'h2);
        test(0, 'd64, 'h0);
        test(1, 'd96, 'h3);
        test(0, 'd96, 'h0);
        test(1, 'd64, 'h2);
        test(0, 'd64, 'h0);

        repeat(2) @(posedge clk);
        $display("[%0d]cache_ro: test end\n", $time());
        $stop();
    end

endmodule: cache_ro_tb


module cache_ro_multi_tb();
    localparam SIZE_BLOCK = 32; // block size, in bits
    localparam BIT_TOTAL = 24; // addr length, MAX_INDEX = 1 << BIT_TOTAL
    localparam BIT_INDEX = 5; // index length
    localparam WAY = 3; // # block in a set (set-associate)

    logic clk;
    always #10 clk = ~clk;
    logic rst;
    logic en;
    logic wrt;
    logic [BIT_TOTAL-1:0] i_addr;
    logic [SIZE_BLOCK-1:0] i_data;
    logic [SIZE_BLOCK-1:0] o_data;
    logic o_success;
    cache_ro_multi #(.SIZE_BLOCK(SIZE_BLOCK), .BIT_TOTAL(BIT_TOTAL), .BIT_INDEX(BIT_INDEX), .WAY(WAY))
               dut (clk, rst, en, wrt, i_addr, i_data, o_data, o_success);

    // TO DO: replace with data structure
    logic [SIZE_BLOCK-1:0] correct_data;
    logic success;

    int test_index;
    logic error_flag;

    task automatic test(
        input dut_wrt,
        input [BIT_TOTAL-1:0] dut_addr,
        input [SIZE_BLOCK-1:0] dut_data
    ); begin

        test_index += 'd1;
        error_flag = 1'b0;

        en = 1;
        wrt = dut_wrt;
        i_addr = dut_addr;
        i_data = dut_data;
        @(posedge clk);
        #1; // avoid delta cycle
        en = 0;

        if (o_success !== success) begin
            $display("[%0d]Test %0d ERROR! Got o_success: %0d from %h, should be %h", $time(), test_index, o_success, dut_addr, success);
            error_flag = 1'b1;
        end
        if (o_data !== correct_data) begin
            $display("[%0d]Test %0d ERROR! Got o_data: %h from %h, should be %h", $time(), test_index, o_data, dut_addr, correct_data);
            error_flag = 1'b1;
        end

        /*if (error_flag) begin
            $stop();
        end*/
    end endtask: test

    initial begin
        clk = 1;
        rst = 1;
        en = 0;
        wrt = 0;
        i_addr = 'b0;
        i_data = 'b0;
        repeat(5) @(posedge clk);
        rst = 0;
        $display("\n[%0d]cache_ro_multi: test begin\n", $time());
        $display("TO DO: reference not implemented. all outputs are treated as errors");

        test(1, 'd3, 'ha);
        test(0, 'd3, 'h0);
        test(1, 'd4, 'hb);
        test(0, 'd4, 'h0);
        test(1, 'd5, 'hc);
        test(0, 'd5, 'h0);
        test(1, 'd0, 'he);
        test(0, 'd0, 'h0);
        test(1, 'd32, 'h1);
        test(0, 'd32, 'h0);
        test(1, 'd64, 'h2);
        test(0, 'd64, 'h0);
        test(1, 'd96, 'h3);
        test(0, 'd96, 'h0);
        test(1, 'd64, 'h2);
        test(0, 'd64, 'h0);
        test(1, 'd128, 'h4);
        test(0, 'd128, 'h0);
        test(1, 'd256, 'h8);
        test(0, 'd256, 'h0);

        repeat(2) @(posedge clk);
        $display("[%0d]cache_ro_multi: test end\n", $time());
        $stop();
    end

endmodule: cache_ro_multi_tb
