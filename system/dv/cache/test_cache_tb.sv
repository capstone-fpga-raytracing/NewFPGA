`timescale 1ns/1ns

module cache_ro_tb();
    localparam SIZE_BLOCK = 32; // block size, in bits
    localparam BIT_TOTAL = 24; // addr length, MAX_INDEX = 1 << BIT_TOTAL
    localparam BIT_INDEX = 8; // index length
    localparam WAY = 1; // # block in a set (set-associate)

    logic clk;
    always #10 clk = ~clk;
    logic rst;
    logic en;
    logic wrt;
    logic [BIT_TOTAL-1:0] i_addr;
    logic [SIZE_BLOCK-1:0] i_data;
    logic [SIZE_BLOCK-1:0] o_data;
    logic o_success;
    cache_ro #(.SIZE_BLOCK(SIZE_BLOCK), .BIT_TOTAL(BIT_TOTAL), .BIT_INDEX(BIT_INDEX), .WAY(WAY)) cache_ro_inst (clk, rst, en, wrt, i_addr, i_data, o_data, o_success);

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
        en = 0;

        if (o_success !== success) begin
            $display("[%0d]Test %0d ERROR! Got o_success: %0d from %h, should be %h", $time(), test_index, o_success, dut_addr, success);
            error_flag = 1'b1;
        end
        if (!dut_wrt && o_data !== correct_data) begin
            $display("[%0d]Test %0d ERROR! Got o_data: %h from %h, should be %h", $time(), test_index, o_data, dut_addr, correct_data);
            error_flag = 1'b1;
        end

        /*if (error_flag) begin
            $stop();
        end*/
    end endtask: test


    initial begin
        clk = 0;
        rst = 1;
        #100;
        rst = 0;

        test(1, 'd3, 'hf);
        test(0, 'd3, 'h0);
        test(1, 'd4, 'hf);
        test(0, 'd4, 'h0);
        test(1, 'd5, 'hf);
        test(0, 'd5, 'h0);
        test(1, 'd5, 'hd);
        test(0, 'd5, 'h0);
        test(1, 'd0, 'hd);
        test(0, 'd0, 'h0);
        test(1, 'd0, 'hc);
        test(0, 'd0, 'h0);

        // end
        $display("All %0d test(s) passed!", test_index);
        $stop();
    end

endmodule: cache_ro_tb