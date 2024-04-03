`timescale 1ns / 1ps

module ray_intersect_box_tb();

    parameter SAT = 1;
    parameter FRA_BITS = 16;

    reg i_clk;
    reg i_rst;
    reg i_en;
    reg signed [31:0] i_ray [0:1][0:2];
    reg signed [31:0] pbbox [0:1][0:2];
    wire intersects;

    // Instantiate the Unit Under Test (UUT)
    ray_intersect_box #(
        .SAT(SAT),
        .FRA_BITS(FRA_BITS)
    ) dut (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(i_en),
        .i_ray(i_ray),
        .pbbox(pbbox),
        .intersects(intersects)
    );

    // Clock generation
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk; // 100MHz clock
    end

    // Test sequence
    initial begin
        // Initialize inputs
        i_rst = 0; i_en = 0;
        i_ray[0][0] = 0; i_ray[0][1] = 0; i_ray[0][2] = 0;
        i_ray[1][0] = 0; i_ray[1][1] = 0; i_ray[1][2] = 0;
        pbbox[0][0] = 0; pbbox[0][1] = 0; pbbox[0][2] = 0;
        pbbox[1][0] = 0; pbbox[1][1] = 0; pbbox[1][2] = 0;

        // Reset sequence
        #10;
        i_rst = 1; // Come out of reset
        #10;
        i_rst = 0;
        // Test case 1: Ray perfectly aligned with a box
        #10
        i_en = 1;
        i_ray[0][0] = 32'sd0; i_ray[0][1] = 32'sd0; i_ray[0][2] = 32'sd0;
        i_ray[1][0] = 32'sd1000; i_ray[1][1] = 32'sd0; i_ray[1][2] = 32'sd0;
        pbbox[0][0] = 32'sd500; pbbox[0][1] = -32'sd500; pbbox[0][2] = -32'sd500;
        pbbox[1][0] = 32'sd1500; pbbox[1][1] = 32'sd500; pbbox[1][2] = 32'sd500;
        #10000; // Wait for operation

        // Add additional test cases here...

        // Disable for next test case setup
        // i_en = 0;
        #10;

        // Test case 2: Ray does not intersect with the box
        // Re-configure `i_ray` and `pbbox` as needed
        // Remember to set `i_en = 1;` for every new test case

        // Finish simulation
        // #1000000;
        $stop();
    end

endmodule
