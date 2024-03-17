`timescale 1ns/1ps

module tb_ray_intersect_box;

    // Testbench signals
    reg signed [31:0] i_ray [0:1][0:2];
    reg signed [31:0] pbbox [0:1][0:2];
    wire intersects;

    // Instantiate the module
    ray_intersect_box #(
        .SAT(1),
        .FRA_BITS(16)
    ) uut (
        .i_ray(i_ray),
        .pbbox(pbbox),
        .intersects(intersects)
    );

    // Helper function for displaying results
    task display_results;
        $display("Time: %0t, Intersect: %0d", $time, intersects);
    endtask

    // Test scenario
    initial begin
        // Testcase 1: Ray starts outside and points towards the box
        // Expected Result: Intersect = 1
        i_ray[0][0] = 32'sd0; i_ray[0][1] = 32'sd0; i_ray[0][2] = 32'sd0;
        i_ray[1][0] = 32'sd10; i_ray[1][1] = 32'sd10; i_ray[1][2] = 32'sd10;
        pbbox[0][0] = 32'sd5; pbbox[0][1] = 32'sd5; pbbox[0][2] = 32'sd5;
        pbbox[1][0] = 32'sd15; pbbox[1][1] = 32'sd15; pbbox[1][2] = 32'sd15;
        #1;
        display_results();

        // Testcase 2: Ray starts inside the box
        // Expected Result: Intersect = 1
        i_ray[0][0] = 32'sd10; i_ray[0][1] = 32'sd10; i_ray[0][2] = 32'sd10;
        // Adjusting direction to point outwards
        i_ray[1][0] = 32'sd20; i_ray[1][1] = 32'sd20; i_ray[1][2] = 32'sd20;
        #1;
        display_results();

        // Testcase 3: Ray misses the box (parallel to one face and beside the box)
        // Expected Result: Intersect = 0
        i_ray[0][0] = 32'sd20; i_ray[0][1] = 32'sd0; i_ray[0][2] = 32'sd0;
        i_ray[1][0] = 32'sd0; i_ray[1][1] = 32'sd10; i_ray[1][2] = 32'sd0;
        #1;
        display_results();

        // // Testcase 4: Ray direction towards the box but starts too far away
        // // Expected Result: Intersect = 0
        // i_ray[0][0] = 32'sd-100; i_ray[0][1] = 32'sd-100; i_ray[0][2] = 32'sd-100;
        // i_ray[1][0] = 32'sd5; i_ray[1][1] = 32'sd5; i_ray[1][2] = 32'sd5;
        // #1;
        // display_results();

        // // Testcase 5: Ray barely intersects the box at an edge
        // // Expected Result: Intersect = 1
        // i_ray[0][0] = 32'sd4; i_ray[0][1] = 32'sd4; i_ray[0][2] = 32'sd0;
        // i_ray[1][0] = 32'sd1; i_ray[1][1] = 32'sd1; i_ray[1][2] = 32'sd10;
        // #1;
        // display_results();

        // // Testcase 6: Ray starts at the edge of the box and points away
        // // Expected Result: Intersect = 0
        // i_ray[0][0] = 32'sd5; i_ray[0][1] = 32'sd5; i_ray[0][2] = 32'sd5;
        // i_ray[1][0] = -32'sd1; i_ray[1][1] = -32'sd1; i_ray[1][2] = -32'sd10;
        // #1;
        // display_results();

        // // Testcase 7: Ray and box are coincident at a single point (corner)
        // // Expected Result: Intersect = 0 or 1 depending on interpretation
        // i_ray[0][0] = 32'sd5; i_ray[0][1] = 32'sd5; i_ray[0][2] = 32'sd5;
        // i_ray[1][0] = 32'sd0; i_ray[1][1] = 32'sd0; i_ray[1][2] = 32'sd0;
        // #1;
        // display_results();

        // // Testcase 8: Ray is exactly aligned with one of the box's axes
        // // Expected Result: Intersect = 1
        // i_ray[0][0] = 32'sd0; i_ray[0][1] = 32'sd10; i_ray[0][2] = 32'sd10;
        // i_ray[1][0] = 32'sd10; i_ray[1][1] = 32'sd0; i_ray[1][2] = 32'sd0;
        // #1;
        // display_results();

        $stop; // End the simulation
    end


endmodule