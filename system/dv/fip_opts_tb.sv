// basic fip operations testbench

`define TRUE 1
`define FALSE 0
`define FIP_MIN 32'sh80000000
`define FIP_MAX 32'sh7fffffff


module fip_32_add_sat_tb();
    logic signed [31:0] x, y, sum;

    fip_32_add_sat dut (
        .i_x(x),
        .i_y(y),
        .o_z(sum)
    );

    initial begin
        $display("\n[%0d]fip_32_add_sat: test begin\n", $time());

        // overflow & underflow cut

        // Test 1: Simple addition
        x = 1 << 16; // 1.0 in Q16.16 (0x00010000)
        y = 1 << 16; // 1.0 in Q16.16 (0x00010000)
        #10;
        // Expected: no overflow, sum = 2.0 in Q16.16 (0x00020000)

        // Test 2: Addition with negative value
        x = -1 << 16; // -1.0 in Q16.16 (0xFFFF0000)
        y = -1;              // Fractional value of -1/65536 in Q16.16 (negative very small fraction)
        #10;
        // Expected: no overflow, sum is slightly less than -1.0 in Q16.16 (0xfffeffff)

        // Test 3: Checking for overflow
        x = `FIP_MAX;
        y = 1 << 16; // 1.0 in Q16.16 (0x00010000)
        #10;
        // Expected: overflow, sum cut to FIP_MAX

        // Test 4: Checking for underflow
        x = `FIP_MIN;
        y = -1 << 16; // -1.0 in Q16.16 (0xFFFF0000)
        #10;
        // Expected: underflow, sum cut to FIP_MIN

        $display("[%0d]fip_32_add_sat: test end\n", $time());
        $stop();
    end

endmodule: fip_32_add_sat_tb


module fip_32_mult_tb();
    localparam FRA_BITS = 16; // For Q16.16 fixed-point format
    logic signed [31:0] x, y, prod;

    fip_32_mult #(
        .FRA_BITS(FRA_BITS)
    ) dut (
        .i_x(x),
        .i_y(y),
        .o_z(prod)
    );

    initial begin
        $display("\n[%0d]fip_32_mult: test begin\n", $time());

        // overflow ignored

        // Test 1: Simple multiplication without overflow
        x = 1 << FRA_BITS; // 1.0 in Q16.16 (0x00010000 or 65536 as signed integer)
        y = 1 << FRA_BITS; // 1.0 in Q16.16 (0x00010000 or 65536 as signed integer)
        #10;
        // Expected: prod = 1.0 in Q16.16 (0x00010000 or 65536 as signed integer), overflow = 0

        // Test 2: Edge case, multiplication by zero
        x = 1 << FRA_BITS; // 1.0 in Q16.16 (0x00010000 or 65536 as signed integer)
        y = 0; // 0 in Q16.16
        #10;
        // Expected: prod = 0 in Q16.16, overflow = 0

        // Test 3: Fractional multiplication without overflow
        x = 0.5 * (1 << FRA_BITS); // 0.5 in Q16.16 (32768 as signed integer)
        y = 0.5 * (1 << FRA_BITS); // 0.5 in Q16.16 (32768 as signed integer)
        #10;
        // Expected: prod = 0.25 in Q16.16 (0x00004000 or 16384 as signed integer), overflow = 0

        // Test 4: Fractional multiplication with one negative operand
        x = -0.5 * (1 << FRA_BITS); // -0.5 in Q16.16 (-32768 as signed integer)
        y = 0.5 * (1 << FRA_BITS); // 0.5 in Q16.16 (32768 as signed integer)
        #10;
        // Expected: prod = -0.25 in Q16.16 (0xFFFFC000 or -16384 as signed integer), overflow = 0

        // Test 5: Small fractional multiplication without overflow
        x = 1; // Very small positive fraction in Q16.16 (1 as signed integer)
        y = 1; // Very small positive fraction in Q16.16 (1 as signed integer)
        #10;
        // Expected: prod is a very small positive fraction in Q16.16 (0x00000000 or 0 as signed integer), overflow = 0

        $display("[%0d]fip_32_mult: test end\n", $time());
        $stop();
    end

endmodule: fip_32_mult_tb


module divider_tb();
    localparam WIDTH = 48;
    logic clk, rst, en, valid;
    logic signed [WIDTH-1:0] dividend, divider, quotient;
    always #10 clk = ~clk;

    divider #(.WIDTH(WIDTH)) dut (clk, rst, en, dividend, divider, quotient, valid);

    initial begin
        clk=1;
        rst=1;
        repeat(10) @(posedge clk);
        rst=0;
        $display("\n[%0d]divider: test begin\n", $time());

        dividend = 48'h300000000;
        divider = 48'h10000;
        en = 1;
        @(posedge clk);
        en = 0;

        dividend = 48'h200000000;
        divider = -48'h10000;
        en = 1;
        @(posedge clk);
        en = 0;

        dividend = 48'h400000000;
        divider = 48'h10000;
        en = 1;
        @(posedge clk);
        en = 0;

        // while(~ready) @(posedge clk);
        repeat(100) @(posedge clk);
        $display("[%0d]divider: test end\n", $time());
        $stop();
    end

endmodule: divider_tb


module fip_32_div_tb();
    localparam SAT = `TRUE; // For saturation against overflow/underflow
    localparam FRA_BITS = 16; // For Q16.16 fixed-point format
    logic clk, rst, en, valid;
    logic signed [31:0] x, y, quotient;
    always #10 clk = ~clk;

    fip_32_div #(
        .SAT(SAT),
        .FRA_BITS(FRA_BITS)
    ) dut (
        .i_clk(clk),
        .i_rst(rst),
        .i_en(en),
        .i_x(x),
        .i_y(y),
        .o_z(quotient),
        .o_valid(valid)
    );

    initial begin
        clk=1;
        rst=1;
        repeat(10) @(posedge clk);
        rst=0;
        $display("\n[%0d]fip_32_div: test begin\n", $time());

        // no overflow or underflow

        // Test 1: Division of integer numbers without overflow
        x = 2 << FRA_BITS; // 2.0 in Q16.16 (131072)    
        y = 2 << FRA_BITS; // 2.0 in Q16.16 (131072)
        en = 1;
        @(posedge clk);
        en = 0;
        // Expected: quotient = 1.0 in Q16.16 (65536) with no overflow

        // Test 2: Division of fractional numbers
        x = 0.5 * (1 << FRA_BITS); // 0.5 in Q16.16 (32768)
        y = 0.25 * (1 << FRA_BITS); // 0.25 in Q16.16 (16384)
        en = 1;
        @(posedge clk);
        en = 0;
        // Expected: quotient = 2.0 in Q16.16 (131072) with no overflow

        // Test 3: Division of small numbers
        x = 2;  // 2/65536 in Q16.16 (2)
        y = 3;  // 3/65536 in Q16.16 (3)
        en = 1;
        @(posedge clk);
        en = 0;
        // Expected: quotient = 2/3 in Q16.16 (43708) with no underflow/overflow
        // RESULT: 43690, which is an error of 0.0002746582. Negligible.

        // Test 4: Division with negative numbers
        x = -1 << FRA_BITS; // -1.0 in Q16.16 (-65536)
        y = 0.5 * (1 << FRA_BITS); // 0.5 in Q16.16 (32768)
        en = 1;
        @(posedge clk);
        en = 0;
        // Expected: quotient = -2.0 in Q16.16 (-131072) with no overflow

        // overflow & underflow cut
        // enabled when SAT = `TRUE
        
        // Test 5: Division leading to overflow
        x = `FIP_MAX; // fip max value
        y = 0.25 * (1 << FRA_BITS); // 0.25 in Q16.16 (16384)
        en = 1;
        @(posedge clk);
        en = 0;
        // Expected: overflow, quotient cut to FIP_MAX

        // Test 6: Division leading to underflow
        x = `FIP_MIN; // fip min value
        y = 0.25 * (1 << FRA_BITS); // 0.25 in Q16.16 (16384)
        en = 1;
        @(posedge clk);
        en = 0;
        // Expected: underflow, quotient cut to FIP_MIN

        repeat(60) @(posedge clk);
        $display("[%0d]fip_32_div: test end\n", $time());
        $stop();
    end

endmodule: fip_32_div_tb


module fip_32_vector_cross_tb();
    logic signed [31:0] i_array [0:1][0:2];
    logic signed [31:0] o_cross [0:2];
    logic valid;
    logic clk, rstn, en;
    always #10 clk = ~clk;

    fip_32_vector_cross dut (
        .i_clk(clk),
        .i_rstn(rstn),
        .i_en(en),
        .i_array(i_array),
        .o_cross(o_cross),
        .o_valid(valid)
    );

    initial begin
        clk = 1'b1;
        rstn = 1'b0;
        en = 1'b0;
        repeat(3) @(posedge clk);
        rstn = 1'b1;
        $display("\n[%0d]fip_32_vector_cross: test begin\n", $time());

        // TO DO: add test cases here

        repeat(3) @(posedge clk);
        $display("[%0d]fip_32_vector_cross: test end\n", $time());
        $stop();
    end

endmodule: fip_32_vector_cross_tb


module fip_32_vector_dot_tb();
    logic signed [31:0] i_array [0:1][0:2];
    logic signed [31:0] o_dot;
    logic valid;
    logic clk, rstn, en;
    always #10 clk = ~clk;

    fip_32_vector_dot dut (
        .i_clk(clk),
        .i_rstn(rstn),
        .i_en(en),
        .i_array(i_array),
        .o_dot(o_dot),
        .o_valid(valid)
    );

    initial begin
        clk = 1'b1;
        rstn = 1'b0;
        en = 1'b0;
        repeat(3) @(posedge clk);
        rstn = 1'b1;
        $display("\n[%0d]fip_32_vector_dot: test begin\n", $time());

        // TO DO: add test cases here

        repeat(3) @(posedge clk);
        $display("[%0d]fip_32_vector_dot: test end\n", $time());
        $stop();
    end

endmodule: fip_32_vector_dot_tb


module fip_32_sqrt_tb();
    localparam FRA_BITS = 16; // For Q16.16 fixed-point format
    logic [31:0] rad, root;
    logic valid, busy;
    logic clk, rstn, en;
    always #10 clk = ~clk;

    fip_32_sqrt #(
        .FRA_BITS(FRA_BITS)
    ) dut (
        .i_clk(clk),
        .i_rstn(rstn),
        .i_en(en),
        .i_rad(rad),
        .o_root(root),
        .o_busy(busy),
        .o_valid(valid)
    );

    initial begin
        clk = 1'b1;
        rstn = 1'b0;
        en = 1'b0;
        repeat(5) @(posedge clk);
        rstn = 1'b1;
        $display("\n[%0d]fip_32_sqrt: test begin\n", $time());

        // TO DO: add test cases here

        repeat(30) @(posedge clk);
        $display("[%0d]fip_32_sqrt: test end\n", $time());
        $stop();
    end

endmodule: fip_32_sqrt_tb


module fip_32_3b3_det_tb();
    logic signed [31:0] i_array [0:2][0:2];
    logic signed [31:0] o_det;
    logic valid;
    logic clk, rstn, en;
    always #10 clk = ~clk;

    fip_32_3b3_det dut (
        .i_clk(clk),
        .i_rstn(rstn),
        .i_en(en),
        .i_array(i_array),
        .o_det(o_det),
        .o_valid(valid)
    );

    initial begin
        clk = 1'b1;
        rstn = 1'b0;
        en = 1'b0;
        repeat(5) @(posedge clk);
        rstn = 1'b1;
        $display("\n[%0d]fip_32_3b3_det: test begin\n", $time());
        
        en = 1'b1;

        // Test 1: Determinant of an identity matrix
        i_array[0] = '{1 << 16, 'b0, 'b0};
        i_array[1] = '{'b0, 1 << 16, 'b0};
        i_array[2] = '{'b0, 'b0, 1 << 16};
        @(posedge clk);
        // Expected: o_det = 1 in Q16.16 (65536) with no overflow

        // Test 2: Enable off
        en = 1'b0;
        @(posedge clk);
        // Expected: one invalid cycle
        en = 1'b1;

        // Test 3: Determinant with random values
        i_array[0] = '{1 << 16, 2 << 16, 3 << 16};
        i_array[1] = '{4 << 16, 5 << 16, 6 << 16};
        i_array[2] = '{7 << 16, 8 << 16, 9 << 16};
        @(posedge clk);
        // Expected: o_det = 0 with no overflow (since the matrix is singular)

        // Test 4: Determinant with some negative values
        i_array[0] = '{1 << 16, -1 << 16, 3 << 16};
        i_array[1] = '{4 << 16, 5 << 16, 6 << 16};
        i_array[2] = '{7 << 16, 8 << 16, 9 << 16};
        @(posedge clk);
        // Expected: o_det = -18 in Q16.16 (-1179648) with no overflow

        en = 1'b0;

        repeat(5) @(posedge clk);
        $display("[%0d]fip_32_3b3_det: test end\n", $time());
        $stop();
    end

endmodule: fip_32_3b3_det_tb


module fip_32_vector_normal_tb();
    logic signed [31:0] i_vector [0:2];
    logic signed [31:0] o_vector [0:2];
    logic valid, busy;
    logic clk, rstn, en;
    always #10 clk = ~clk;

    fip_32_vector_normal dut (
        .i_clk(clk),
        .i_rstn(rstn),
        .i_en(en),
        .i_vector(i_vector),
        .o_vector(o_vector),
        .o_busy(busy),
        .o_valid(valid)
    );

    initial begin
        clk = 1'b1;
        rstn = 1'b0;
        en = 1'b0;
        repeat(5) @(posedge clk);
        rstn = 1'b1;
        $display("\n[%0d]fip_32_vector_normal: test begin\n", $time());

        // TO DO: add test cases here

        repeat(40) @(posedge clk);
        $display("[%0d]fip_32_vector_normal: test end\n", $time());
        $stop();
    end

endmodule: fip_32_vector_normal_tb
