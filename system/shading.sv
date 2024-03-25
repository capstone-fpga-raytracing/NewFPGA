// shading module

`define FIP_AMB 32'sh00002000 // 0.125
`define FIP_ALMOST_ONE 32'sh0000ffff // largest below 1
`define MAX_LIGHT_SRC 8


// TO DO:
// implement and test bs / pl sqrt
// test and add bs_bp_shading_light to bs_bp_shading
// test bs_bp_shading
// pileline and test bs_bp_shading_light and bs_bp_shading


// basic bs_bp_shading (without pipeline)
module bs_bp_shading #(
    parameter AMB = `FIP_AMB,
    parameter MAX_L = `MAX_LIGHT_SRC, // max light sources allowed
    localparam LEN_L = $clog2(MAX_L) // light id length
)(
    input i_clk,
    input i_rstn,
    input i_en,
    input signed [31:0] i_tri [0:2][0:2], // i_tri[0]: vertex 0
    input signed [31:0] i_mat [0:2][0:2], // i_mat[0]: ka, i_mat[1]: kd, i_mat[2]: ks
    input signed [31:0] i_ray [0:1][0:2], // i_ray[0]: origin(E), i_ray[1]: direction(D)
    input [LEN_L-1:0] i_num_lights, // number of light sources
    input signed [31:0] i_dist, // hit distance
    output logic signed [31:0] o_light [0:2], // RGB in fip, in range [0, 1)
    output logic o_busy,
    output logic o_valid
);

    // normal
    logic signed [31:0] edges [0:1][0:2];
    assign edges = '{
        '{i_tri[1][0] - i_tri[0][0], i_tri[1][1] - i_tri[0][1], i_tri[1][2] - i_tri[0][2]},
        '{i_tri[2][0] - i_tri[0][0], i_tri[2][1] - i_tri[0][1], i_tri[2][2] - i_tri[0][2]}
    };

    logic signed [31:0] normal_temp [0:2][0:1];
    fip_32_mult mult_n00_inst (.i_x(edges[0][1]), .i_y(edges[1][2]), .o_z(normal_temp[0][0]));
    fip_32_mult mult_n01_inst (.i_x(edges[0][2]), .i_y(edges[1][1]), .o_z(normal_temp[0][1]));
    fip_32_mult mult_n10_inst (.i_x(edges[0][2]), .i_y(edges[1][0]), .o_z(normal_temp[1][0]));
    fip_32_mult mult_n11_inst (.i_x(edges[0][0]), .i_y(edges[1][2]), .o_z(normal_temp[1][1]));
    fip_32_mult mult_n20_inst (.i_x(edges[0][0]), .i_y(edges[1][1]), .o_z(normal_temp[2][0]));
    fip_32_mult mult_n21_inst (.i_x(edges[0][1]), .i_y(edges[1][0]), .o_z(normal_temp[2][1]));
    logic signed [31:0] normal_raw [0:2];
    assign normal_raw[0] = normal_temp[0][0] - normal_temp[0][1];
    assign normal_raw[1] = normal_temp[1][0] - normal_temp[1][1];
    assign normal_raw[2] = normal_temp[2][0] - normal_temp[2][1];

    logic signed [31:0] normal [0:2];
    logic [0:1] normal_tri_drop; // not using pipeline
    fip_32_vector_normal normal_tri_inst (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(i_en), .i_vector(normal_raw),
                                          .o_vector(normal), .o_busy(normal_tri_drop[0]), .o_valid(normal_tri_drop[1]));

    // hit point
    logic signed [31:0] hit_point_temp [0:2];
    fip_32_mult mult_hit0_inst (.i_x(i_dist), .i_y(i_ray[1][0]), .o_z(hit_point_temp[0]));
    fip_32_mult mult_hit1_inst (.i_x(i_dist), .i_y(i_ray[1][1]), .o_z(hit_point_temp[1]));
    fip_32_mult mult_hit2_inst (.i_x(i_dist), .i_y(i_ray[1][2]), .o_z(hit_point_temp[2]));
    logic signed [31:0] hit_point [0:2];
    assign hit_point[0] = hit_point_temp[0] + i_ray[0][0];
    assign hit_point[1] = hit_point_temp[1] + i_ray[0][1];
    assign hit_point[2] = hit_point_temp[2] + i_ray[0][2];

    // ambient
    logic [31:0] amb_light [0:2];
    fip_32_mult mult_amb0_inst (.i_x(AMB), .i_y(i_mat[0][0]), .o_z(amb_light[0]));
    fip_32_mult mult_amb1_inst (.i_x(AMB), .i_y(i_mat[0][1]), .o_z(amb_light[1]));
    fip_32_mult mult_amb2_inst (.i_x(AMB), .i_y(i_mat[0][2]), .o_z(amb_light[2]));

    // shadow, diffuse and specular
    logic signed [31:0] light [0:2];
    // TO DO: add bs_bp_shading_light inst here

    // sum with amb, chop off light >= 1
    always_comb begin
        o_light[0] = amb_light[0] + light[0];
        if (o_light[0] > `FIP_ALMOST_ONE) o_light[0] = `FIP_ALMOST_ONE;
        o_light[1] = amb_light[1] + light[1];
        if (o_light[1] > `FIP_ALMOST_ONE) o_light[1] = `FIP_ALMOST_ONE;
        o_light[2] = amb_light[2] + light[2];
        if (o_light[2] > `FIP_ALMOST_ONE) o_light[2] = `FIP_ALMOST_ONE;
    end

endmodule: bs_bp_shading


// basic bs_bp_shading_light (without pipeline)
module bs_bp_shading_light(
    input i_clk,
    input i_rstn,
    input i_en,
    input signed [31:0] normal [0:2], // normal of triangle
    input signed [31:0] hit_point [0:2], // hit point of ray
    input signed [31:0] i_mat [0:2][0:2], // i_mat[0]: ka, i_mat[1]: kd, i_mat[2]: ks
    input signed [31:0] i_light [0:1][0:2], // i_light[0]: source, i_light[1]: color
    output logic signed [31:0] o_light [0:2], // RGB in fip, not cut
    output logic o_busy,
    output logic o_valid
);

    // direction
    logic signed [31:0] dir_raw [0:2];
    assign dir_raw = '{
        i_light[0][0] - hit_point[0],
        i_light[0][1] - hit_point[1],
        i_light[0][2] - hit_point[2]
    };

    logic signed [31:0] dir;
    logic [0:1] normal_dir_drop; // not using pipeline
    fip_32_vector_normal normal_tri_inst (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(i_en), .i_vector(dir_raw),
                                          .o_vector(dir), .o_busy(normal_dir_drop[0]), .o_valid(normal_dir_drop[1]));

    // shadow: ignored for now

    // diffuse
    logic signed [31:0] diff_light_term_raw;
    logic dot_drop; // not using pipeline
    fip_32_vector_dot dot_inst (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(i_en),
                                .i_array('{normal, dir}), .o_dot(diff_light_term_raw), .o_valid(dot_drop));

    logic signed [31:0] diff_light_term;
    always_comb begin
        if (diff_light_term_raw[31] == 1'b0) diff_light_term = diff_light_term_raw;
        else diff_light_term = 32'sb0;
    end

    logic signed [31:0] diff_light_raw [0:2];
    fip_32_mult mult_lr0_inst (.i_x(i_mat[1][0]), .i_y(i_light[1][0]), .o_z(diff_light_raw[0]));
    fip_32_mult mult_lr1_inst (.i_x(i_mat[1][1]), .i_y(i_light[1][1]), .o_z(diff_light_raw[1]));
    fip_32_mult mult_lr2_inst (.i_x(i_mat[1][2]), .i_y(i_light[1][2]), .o_z(diff_light_raw[2]));

    logic signed [31:0] diff_light [0:2];
    fip_32_mult mult_l0_inst (.i_x(diff_light_term), .i_y(diff_light_raw[0]), .o_z(diff_light[0]));
    fip_32_mult mult_l1_inst (.i_x(diff_light_term), .i_y(diff_light_raw[1]), .o_z(diff_light[1]));
    fip_32_mult mult_l2_inst (.i_x(diff_light_term), .i_y(diff_light_raw[2]), .o_z(diff_light[2]));

    // specular: ignored for now

    // update total_light
    // unused for now

endmodule: bs_bp_shading_light
