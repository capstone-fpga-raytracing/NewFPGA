module ray_intersect_box#(
    parameter SAT = 1,
    parameter FRA_BITS = 16
)(  
    input i_clk,
    input i_rst,
    input i_en,
    input signed [31:0] i_ray [0:1][0:2], // i_ray[0] for origin(E), i_ray[1] for direction(D)
    input signed [31:0] pbbox [0:1][0:2], // pbbox[0] for min, pbbox[1] for max
    output logic intersects
);

    localparam int FIP_MIN = 32'sh80000000;
    localparam int FIP_MAX = 32'sh7fffffff;

    logic [31:0] t_entry;
    logic [31:0] t_exit;

    // Intermediate signals for division operation results
    wire signed [31:0] div_result1;
    wire signed [31:0] div_result2;
    wire signed [31:0] div_result3;
    wire signed [31:0] div_result4;
    wire signed [31:0] div_result5;
    wire signed [31:0] div_result6;
    logic div_valid[0:5]; // pipeline stage valid from div modules

    // Instantiate division modules for each axis and boundary
    // Instantiating division modules for X-axis min and max
    fip_32_div #(.SAT(SAT), .FRA_BITS(FRA_BITS)) div_x_min(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(i_en),
        .i_x(pbbox[0][0] - i_ray[0][0]), 
        .i_y(i_ray[1][0]), 
        .o_z(div_result1),
        .o_valid(div_valid[0])
    );

    fip_32_div #(.SAT(SAT), .FRA_BITS(FRA_BITS)) div_x_max(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(i_en),
        .i_x(pbbox[1][0] - i_ray[0][0]), 
        .i_y(i_ray[1][0]), 
        .o_z(div_result2),
        .o_valid(div_valid[1])
    );

    // Instantiating division modules for Y-axis min and max
    fip_32_div #(.SAT(SAT), .FRA_BITS(FRA_BITS)) div_y_min(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(i_en),
        .i_x(pbbox[0][1] - i_ray[0][1]), 
        .i_y(i_ray[1][1]), 
        .o_z(div_result3),
        .o_valid(div_valid[2])
    );

    fip_32_div #(.SAT(SAT), .FRA_BITS(FRA_BITS)) div_y_max(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(i_en),
        .i_x(pbbox[1][1] - i_ray[0][1]), 
        .i_y(i_ray[1][1]), 
        .o_z(div_result4),
        .o_valid(div_valid[3])
    );

    // Instantiating division modules for Z-axis min and max
    fip_32_div #(.SAT(SAT), .FRA_BITS(FRA_BITS)) div_z_min(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(i_en),
        .i_x(pbbox[0][2] - i_ray[0][2]), 
        .i_y(i_ray[1][2]), 
        .o_z(div_result5),
        .o_valid(div_valid[4])
    );

    fip_32_div #(.SAT(SAT), .FRA_BITS(FRA_BITS)) div_z_max(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(i_en),
        .i_x(pbbox[1][2] - i_ray[0][2]), 
        .i_y(i_ray[1][2]), 
        .o_z(div_result6),
        .o_valid(div_valid[5])
    );

    // No pipeline stages yet, just wait for all div modules to be valid before computing t_entry and t_exit
    logic div_valid_en;

    always_ff@(posedge i_clk) begin
        if(i_rst) begin
            div_valid_en <= 0;
        end else if(i_en) begin
            if(div_valid[0] && div_valid[1] && div_valid[2] && div_valid[3] && div_valid[4] && div_valid[5]) begin
                div_valid_en <= 1;
            end
        end
    end


    always_comb begin
        t_entry = FIP_MIN;
        t_exit = FIP_MAX;

        if(div_valid_en) begin
            // For i = 0
            if(i_ray[1][0] > 0) begin
                // set t_entry to be the max between itself and the result of the corresponding division
                t_entry = (div_result1 > t_entry) ? div_result1 : t_entry;
                t_exit = (div_result2 < t_exit) ? div_result2 : t_exit;
            end else begin
                t_entry = (div_result2 > t_entry) ? div_result2 : t_entry;
                t_exit = (div_result1 < t_exit) ? div_result1 : t_exit;
            end

            // For i = 1
            if(i_ray[1][1] > 0) begin
                t_entry = (div_result3 > t_entry) ? div_result3 : t_entry;
                t_exit = (div_result4 < t_exit) ? div_result4 : t_exit;
            end else begin
                t_entry = (div_result4 > t_entry) ? div_result4 : t_entry;
                t_exit = (div_result3 < t_exit) ? div_result3 : t_exit;
            end

            // For i = 2
            if(i_ray[1][2] > 0) begin
                t_entry = (div_result5 > t_entry) ? div_result5 : t_entry;
                t_exit = (div_result6 < t_exit) ? div_result6 : t_exit;
            end else begin
                t_entry = (div_result6 > t_entry) ? div_result6 : t_entry;
                t_exit = (div_result5 < t_exit) ? div_result5 : t_exit;
            end

            intersects = (t_exit >= t_entry) && (t_entry >= 0);
        end
    end

endmodule: ray_intersect_box
