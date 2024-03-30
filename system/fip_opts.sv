// basic fip operations, rtl

`define TRUE 1
`define FALSE 0
`define FIP_MIN 32'sh80000000
`define FIP_MAX 32'sh7fffffff


// overflow cut
module fip_32_add_sat (
    input signed [31:0] i_x,
    input signed [31:0] i_y,
    output logic signed [31:0] o_z
);
    logic signed [32:0] temp_z;
    always_comb begin
        temp_z = i_x + i_y;
        o_z = temp_z[31:0];
        if (temp_z < `FIP_MIN) o_z = `FIP_MIN;
        else if (temp_z > `FIP_MAX) o_z = `FIP_MAX;
    end
endmodule: fip_32_add_sat


// overflow ignored
module fip_32_mult #(
    parameter FRA_BITS = 16
)(
    input signed [31:0] i_x,
    input signed [31:0] i_y,
    output logic signed [31:0] o_z
);
    logic signed [63:0] temp_z;
    assign temp_z = i_x * i_y;
    assign o_z = temp_z[FRA_BITS+31:FRA_BITS];

endmodule: fip_32_mult


module sub_divider #(
    parameter WIDTH = 48
)(
    input i_clk,
    input i_rst,
    input i_en,
    input [WIDTH-1:0] i_quotient_temp,
    input [WIDTH*2-1:0] i_dividend_copy,
    input [WIDTH*2-1:0] i_divider_copy,
    output logic [WIDTH-1:0] o_quotient_temp,
    output logic [WIDTH*2-1:0] o_dividend_copy,
    output logic [WIDTH*2-1:0] o_divider_copy,
    output logic o_valid
);

    logic [WIDTH*2-1:0] diff;
    assign diff = i_dividend_copy - i_divider_copy;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o_quotient_temp <= 'b0;
            o_dividend_copy <= 'b0;
            o_divider_copy <= 'b0;
            o_valid <= 1'b0;
        end else begin
            o_quotient_temp <= i_quotient_temp << 1;
            if(!diff[WIDTH*2-1]) begin
                o_dividend_copy <= diff;
                o_quotient_temp[0] <= 1'b1;
            end else begin
                o_dividend_copy <= i_dividend_copy;
            end
            o_divider_copy <= i_divider_copy >> 1;
            o_valid <= i_en;
        end
    end

endmodule: sub_divider


module divider #(
    parameter WIDTH = 48
)(
    input i_clk,
    input i_rst,
    input i_en,
    input [WIDTH-1:0] i_x,
    input [WIDTH-1:0] i_y,
    output logic [WIDTH-1:0] o_z,
    output logic o_valid
);

    logic [0:WIDTH-1] valid;
    logic valid_f;
    logic [0:WIDTH-1][WIDTH-1:0] quotient_temp;
    logic [0:WIDTH-1][WIDTH*2-1:0] dividend_copy;
    logic [0:WIDTH-1][WIDTH*2-1:0] divider_copy;

    logic [WIDTH*2-1:0] dividend_copy_f, divider_copy_f;

    sub_divider #(.WIDTH(WIDTH)) inst_first (i_clk, i_rst, valid_f, WIDTH'('b0), dividend_copy_f, divider_copy_f,
                                             quotient_temp[0], dividend_copy[0], divider_copy[0], valid[0]);
    genvar i;
    generate begin: sub_dividers
        for (i = 1; i < WIDTH; i+=1) begin: sub_divide
            sub_divider #(.WIDTH(WIDTH)) inst (i_clk, i_rst, valid[i-1], quotient_temp[i-1], dividend_copy[i-1], divider_copy[i-1],
                                               quotient_temp[i], dividend_copy[i], divider_copy[i], valid[i]);
        end
    end endgenerate

    logic [0:WIDTH] negative_output;
    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            dividend_copy_f <= 'b0;
            divider_copy_f <= 'b0;
            negative_output <= 1'b0;
            valid_f <= 1'b0;
            o_z <= 'b0;
        end else begin
            valid_f <= i_en;
            o_valid <= valid[WIDTH-1];
            for (int j=0; j<WIDTH;j+=1) begin
                negative_output[j+1] <= negative_output[j];
            end

            o_z <= (~negative_output[WIDTH]) ? quotient_temp[WIDTH-1] : ~quotient_temp[WIDTH-1] + 1'b1;

            if (i_en) begin
                dividend_copy_f <= (~i_x[WIDTH-1]) ? {WIDTH'('b0),i_x} : {WIDTH'('b0),~i_x + 1'b1};
                divider_copy_f <= (~i_y[WIDTH-1]) ? {1'b0,i_y,(WIDTH-1)'('b0)} : {1'b0,~i_y + 1'b1,(WIDTH-1)'('b0)};
                negative_output[0] <= ((i_y[WIDTH-1] && ~i_x[WIDTH-1]) || (~i_y[WIDTH-1] && i_x[WIDTH-1]));
            end
        end
    end

endmodule: divider


// overflow & underflow ignored if !SAT, else cut
module fip_32_div #(
    parameter SAT = `FALSE,
    parameter FRA_BITS = 16
)(
    input i_clk,
    input i_rst,
    input i_en,
    input signed [31:0] i_x,
    input signed [31:0] i_y,
    output logic signed [31:0] o_z,
    output logic o_valid
);
    localparam EXT_BITS = 32 + FRA_BITS;
    logic [EXT_BITS-1:0] temp_z;

    divider #(
        .WIDTH(EXT_BITS)
    ) pipediv (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_en(i_en),
        .i_x({i_x, FRA_BITS'('d0)}),
        .i_y({FRA_BITS'('d0), i_y}),
        .o_z(temp_z),
        .o_valid(o_valid)
    );

    assign o_z = temp_z[31:0];
    /*
    always_comb begin
        o_z = temp_z[31:0];
        if(SAT == `TRUE) begin
            if (temp_z < `FIP_MIN) o_z <= `FIP_MIN;
            else if (temp_z > `FIP_MAX) o_z <= `FIP_MAX;
        end
    end
    */

endmodule: fip_32_div


// TO DO: pipeline
module fip_32_vector_cross(
    input i_clk,
    input i_rstn,
    input i_en,
    input signed [31:0] i_array [0:1][0:2], // i_array[0] for vector 0
    output logic signed [31:0] o_cross [0:2],
    output logic o_valid
);
    // i_array[0]: |a b c|
    // i_array[1]: |d e f|
    // o_cross = |bf-ce cd-af ae-bd|

    logic signed [31:0] bf, ce, cd, af, ae, bd;
    fip_32_mult mult_bf_inst (.i_x(i_array[0][1]), .i_y(i_array[1][2]), .o_z(bf));
    fip_32_mult mult_ce_inst (.i_x(i_array[0][2]), .i_y(i_array[1][1]), .o_z(ce));
    fip_32_mult mult_cd_inst (.i_x(i_array[0][2]), .i_y(i_array[1][0]), .o_z(cd));
    fip_32_mult mult_af_inst (.i_x(i_array[0][0]), .i_y(i_array[1][2]), .o_z(af));
    fip_32_mult mult_ae_inst (.i_x(i_array[0][0]), .i_y(i_array[1][1]), .o_z(ae));
    fip_32_mult mult_bd_inst (.i_x(i_array[0][1]), .i_y(i_array[1][0]), .o_z(bd));

    assign o_cross = '{bf - ce, cd - af, ae - bd};

endmodule: fip_32_vector_cross


// TO DO: pipeline
module fip_32_vector_dot(
    input i_clk,
    input i_rstn,
    input i_en,
    input signed [31:0] i_array [0:1][0:2], // i_array[0] for vector 0
    output logic signed [31:0] o_dot,
    output logic o_valid
);
    // i_array[0]: |a b c|
    // i_array[1]: |d e f|
    // o_dot = a*d + b*e + c*f

    logic signed [31:0] ad, be, cf;
    fip_32_mult mult_ad_inst (.i_x(i_array[0][1]), .i_y(i_array[1][2]), .o_z(ad));
    fip_32_mult mult_be_inst (.i_x(i_array[0][2]), .i_y(i_array[1][1]), .o_z(be));
    fip_32_mult mult_cf_inst (.i_x(i_array[0][2]), .i_y(i_array[1][0]), .o_z(cf));

    logic signed [31:0] sum1;
    assign sum1 = ad + be;
    assign o_dot = sum1 + cf;

endmodule: fip_32_vector_dot


// TO DO: finish (pipeline)
module fip_32_sqrt #(
    parameter FRA_BITS = 16
)(
    input i_clk,
    input i_rstn,
    input i_en,
    input [31:0] i_rad, // radicand
    output logic [31:0] o_root,
    output logic o_busy,
    output logic o_valid
);

endmodule: fip_32_sqrt


// TO DO: pipeline
// accepts new inputs every cycle
module fip_32_3b3_det(
    input i_clk,
    input i_rstn,
    input i_en,
    input signed [31:0] i_array [0:2][0:2], // could be row or column vectors
    output logic signed [31:0] o_det,
    output logic o_valid
);

    /*
    assume inputs are row vectors (actually doesn't matter)
    |a b c|
    |d e f|
    |g h i|
    det = a(ei-fh) + b(fg-di) + c(dh-eg)
    o_det = part1 + part2 + part3
    */

    // procedure of det:
    // mult -> sub -> mult -> add -> add
    // {mult, sub} -> {mult, add, add}
    logic [0:1] valid; // stage valid bit

    // stage1
    logic signed [31:0] ei, fh, fg, di, dh, eg;
    fip_32_mult mult_ei_inst (.i_x(i_array[1][1]), .i_y(i_array[2][2]), .o_z(ei));
    fip_32_mult mult_fh_inst (.i_x(i_array[1][2]), .i_y(i_array[2][1]), .o_z(fh));
    fip_32_mult mult_fg_inst (.i_x(i_array[1][2]), .i_y(i_array[2][0]), .o_z(fg));
    fip_32_mult mult_di_inst (.i_x(i_array[1][0]), .i_y(i_array[2][2]), .o_z(di));
    fip_32_mult mult_dh_inst (.i_x(i_array[1][0]), .i_y(i_array[2][1]), .o_z(dh));
    fip_32_mult mult_eg_inst (.i_x(i_array[1][1]), .i_y(i_array[2][0]), .o_z(eg));

    logic signed [31:0] inter [0:2];
    assign inter = '{ei - fh, fg - di, dh - eg};

    // stage1 reg
    logic signed [31:0] rout_inter [0:2];
    logic signed [31:0] rout_array0 [0:2];

    // stage2
    logic signed [31:0] part1, part2, part3;
    fip_32_mult mult_inter1_inst (.i_x(rout_array0[0]), .i_y(rout_inter[0]), .o_z(part1));
    fip_32_mult mult_inter2_inst (.i_x(rout_array0[1]), .i_y(rout_inter[1]), .o_z(part2));
    fip_32_mult mult_inter3_inst (.i_x(rout_array0[2]), .i_y(rout_inter[2]), .o_z(part3));
    logic signed [31:0] det;
    assign det = part1 + part2 + part3;

    // stage2 reg
    logic signed [31:0] rout_det;

    // stage control
    always_ff@(posedge i_clk) begin: pipeline
        if (~i_rstn) begin
            rout_inter <= '{3{32'b0}};
            rout_array0 <= '{3{32'b0}};
            rout_det <= 'b0;
            valid <= 'b0;
        end else begin
            rout_inter <= inter;
            rout_array0 <= i_array[0];
            rout_det <= det;

            valid[1] <= valid[0];
        end
        if (i_en) valid[0] <= 1'b1;
        else valid[0] <= 1'b0;
    end

    // output
    assign o_det = rout_det;
    assign o_valid = valid[1];

endmodule: fip_32_3b3_det


// TO DO: pipeline
module fip_32_vector_normal(
    input i_clk,
    input i_rstn,
    input i_en,
    input signed [31:0] i_vector [0:2],
    output logic signed [31:0] o_vector [0:2],
    output logic o_busy,
    output logic o_valid
);

    // procedure of normal:
    // mult -> add -> add -> sqrt -> div

    logic signed [31:0] square1, square2, square3;
    fip_32_mult mult_1_inst (.i_x(i_vector[0]), .i_y(i_vector[0]), .o_z(square1));
    fip_32_mult mult_2_inst (.i_x(i_vector[1]), .i_y(i_vector[1]), .o_z(square2));
    fip_32_mult mult_3_inst (.i_x(i_vector[2]), .i_y(i_vector[2]), .o_z(square3));

    logic signed [31:0] sum1, sum2;
    assign sum1 = square1 + square2;
    assign sum2 = sum1 + square3;

    logic signed [31:0] sqrt_sum2;
    logic [0:1] drop; // not using pipeline
    fip_32_sqrt sqrt_inst (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(i_en), .i_rad(sum2),
                           .o_root(sqrt_sum2), .o_busy(drop[0]), .o_valid(drop[1]));

    fip_32_div div_1_inst (.i_x(i_vector[0]), .i_y(sqrt_sum2), .o_z(o_vector[0]));
    fip_32_div div_2_inst (.i_x(i_vector[1]), .i_y(sqrt_sum2), .o_z(o_vector[1]));
    fip_32_div div_3_inst (.i_x(i_vector[2]), .i_y(sqrt_sum2), .o_z(o_vector[2]));

endmodule: fip_32_vector_normal
