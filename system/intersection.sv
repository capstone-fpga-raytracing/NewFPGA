// intersection modules and tri_insector

`define FIP_ONE 32'sh00010000
`define FIP_MIN 32'sh80000000
`define FIP_MAX 32'sh7fffffff

`define DIV_CYCLE 50

typedef logic signed [31:0] fip;


// pipelined intersection, accepts new inputs every cycle
module intersection #(
    parameter signed MIN_T = 0
) (
    input i_clk,
    input i_rstn,
    input i_en,
    input signed [31:0] i_tri [0:2][0:2], // i_tri[0]: vertex 0
    input signed [31:0] i_ray [0:1][0:2], // i_ray[0]: origin(E), i_ray[1]: direction(D)
    output logic signed [31:0] o_t,
    output logic o_result,
    output logic o_valid,

    output logic [32*4-1:0] dbg_out, // temp
    output logic dbg_out_en // temp
);

    // procedure of intersection:
    // sub -> det -> add -> div
    // {sub} -> {det} -> {add, div}
    logic [0:1] valid; // stage valid
    logic [0:1] sub_valid; // submodule valid

    // stage1: preprocess
    logic signed [31:0] e_t [0:2], t1 [0:2], t2 [0:2], _d [0:2];

    always_comb begin
        e_t = '{i_ray[0][0] - i_tri[0][0], i_ray[0][1] - i_tri[0][1], i_ray[0][2] - i_tri[0][2]};
        t1 = '{i_tri[1][0] - i_tri[0][0], i_tri[1][1] - i_tri[0][1], i_tri[1][2] - i_tri[0][2]};
        t2 = '{i_tri[2][0] - i_tri[0][0], i_tri[2][1] - i_tri[0][1], i_tri[2][2] - i_tri[0][2]};
        _d = '{32'sb0 - i_ray[1][0], 32'sb0 - i_ray[1][1], 32'sb0 - i_ray[1][2]};
    end

    // stage1 reg
    logic signed [31:0] rout_e_t [0:2], rout_t1 [0:2], rout_t2 [0:2], rout__d [0:2];

    // stage2 (multi): det
    logic signed [31:0] coef, det_a, det_b, det_t;
    logic [0:2] det_drop; // all 4 det modules are working parallelly, so keep only one o_valid
    fip_32_3b3_det det_c_inst (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(valid[0]),
                               .i_array('{rout_t1, rout_t2, rout__d}), .o_det(coef), .o_valid(sub_valid[0]));
    fip_32_3b3_det det_a_inst (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(valid[0]),
                               .i_array('{rout_e_t, rout_t2, rout__d}), .o_det(det_a), .o_valid(det_drop[0]));
    fip_32_3b3_det det_b_inst (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(valid[0]),
                               .i_array('{rout_t1, rout_e_t, rout__d}), .o_det(det_b), .o_valid(det_drop[1]));
    fip_32_3b3_det det_t_inst (.i_clk(i_clk), .i_rstn(i_rstn), .i_en(valid[0]),
                               .i_array('{rout_t1, rout_t2, rout_e_t}), .o_det(det_t), .o_valid(det_drop[2]));

    // stage3: a, b, t
    logic signed [31:0] a, b, t;
    logic [0:1] div_drop;
    fip_32_div #(.SAT(1)) div_a_inst (.i_clk(i_clk), .i_rst(~i_rstn), .i_en(sub_valid[0]),
                                      .i_x(det_a), .i_y(coef), .o_z(a), .o_valid(sub_valid[1]));
    fip_32_div #(.SAT(1)) div_b_inst (.i_clk(i_clk), .i_rst(~i_rstn), .i_en(sub_valid[0]),
                                      .i_x(det_b), .i_y(coef), .o_z(b), .o_valid(div_drop[0]));
    fip_32_div #(.SAT(1)) div_t_inst (.i_clk(i_clk), .i_rst(~i_rstn), .i_en(sub_valid[0]),
                                      .i_x(det_t), .i_y(coef), .o_z(t), .o_valid(div_drop[1]));

    // stage3 reg
    logic signed [31:0] rout_coef [0:`DIV_CYCLE-1];

    assign dbg_out = {rout_coef[`DIV_CYCLE-1], a, b, t}; // temp
    assign dbg_out_en = sub_valid[1]; // temp

    // stage4: resuslt
    logic signed [31:0] anb;
    fip_32_add_sat add_sat_inst (.i_x(a), .i_y(b), .o_z(anb));
    logic result;
    always_comb begin
        if (rout_coef[`DIV_CYCLE-1] != 32'd0 && a[31] == 1'b0 && b[31] == 1'b0 &&
            ~(anb > `FIP_ONE) && t[31] == 1'b0)
            result <= 1'b1;
        else result <= 1'b0;
    end

    // stage4 reg
    logic signed [31:0] rout_t;
    logic rout_result;

    // stage control
    always_ff@(posedge i_clk) begin: pipeline
        if (~i_rstn) begin
            rout_e_t <= '{3{32'b0}};
            rout_t1 <= '{3{32'b0}};
            rout_t2 <= '{3{32'b0}};
            rout__d <= '{3{32'b0}};

            rout_coef <= '{`DIV_CYCLE{32'b0}};

            rout_t <= 'b0;
            rout_result <= 1'b0;
            valid <= 'b0;
        end else begin
            valid[0] <= i_en;
            // valid[0] goes to sub_valid[0] in det submodules
            // sub_valid[0] goes to sub_valid[1] in div submodules
            valid[1] <= sub_valid[1];
            
            rout_coef[0] <= coef;
            for (int i = 0; i < `DIV_CYCLE-1; i += 1) begin
                rout_coef[i+1] <= rout_coef[i];
            end

            rout_e_t <= e_t;
            rout_t1 <= t1;
            rout_t2 <= t2;
            rout__d <= _d;

            rout_t <= t;
            rout_result <= result;

        end
    end

    // output
    assign o_t = rout_t;
    assign o_result = rout_result;
    assign o_valid = valid[1];

endmodule: intersection


/*
module ray_intersect_box#(
    parameter SAT = 1,
    parameter FRA_BITS = 16
)(  
    input signed [31:0] i_ray [0:1][0:2], // i_ray[0] for origin(E), i_ray[1] for direction(D)
    input signed [31:0] pbbox [0:1][0:2], // pbbox[0] for min, pbbox[1] for max
    output logic intersects
);
    logic signed [31:0] t_entry;
    logic signed [31:0] t_exit;

    wire signed [31:0] t_min[0:2];
    wire signed [31:0] t_max[0:2];
    
    // Intermediate signals for division operation results
    wire signed [31:0] div_results[0:5];

    // Instantiate division modules for each axis and boundary
    // Computing t_min and t_max for X-axis
    fip_32_div #(.SAT(SAT), .FRA_BITS(FRA_BITS)) div_x_min(.i_x(pbbox[0][0] - i_ray[0][0]), .i_y(i_ray[1][0]), .o_z(div_results[0]));
    fip_32_div #(.SAT(SAT), .FRA_BITS(FRA_BITS)) div_x_max(.i_x(pbbox[1][0] - i_ray[0][0]), .i_y(i_ray[1][0]), .o_z(div_results[1]));
    
    // Computing t_min and t_max for Y-axis
    fip_32_div #(.SAT(SAT), .FRA_BITS(FRA_BITS)) div_y_min(.i_x(pbbox[0][1] - i_ray[0][1]), .i_y(i_ray[1][1]), .o_z(div_results[2]));
    fip_32_div #(.SAT(SAT), .FRA_BITS(FRA_BITS)) div_y_max(.i_x(pbbox[1][1] - i_ray[0][1]), .i_y(i_ray[1][1]), .o_z(div_results[3]));

    // Computing t_min and t_max for Z-axis
    fip_32_div #(.SAT(SAT), .FRA_BITS(FRA_BITS)) div_z_min(.i_x(pbbox[0][2] - i_ray[0][2]), .i_y(i_ray[1][2]), .o_z(div_results[4]));
    fip_32_div #(.SAT(SAT), .FRA_BITS(FRA_BITS)) div_z_max(.i_x(pbbox[1][2] - i_ray[0][2]), .i_y(i_ray[1][2]), .o_z(div_results[5]));

    
    always_comb begin
    
        t_entry = FIP_MAX;
        t_exit = FIP_MIN;

        // For each max min check, perform all comparisons

        // X-axis check
        if (i_ray[1][0] != 0) begin
            t_entry = max(t_entry, min(t_min_x, t_max_x));
            t_exit = min(t_exit, max(t_min_x, t_max_x));
        end

        // Y-axis check
        if (i_ray[1][1] != 0) begin
            t_entry = max(t_entry, min(t_min_y, t_max_y));
            t_exit = min(t_exit, max(t_min_y, t_max_y));
        end

        // Z-axis check
        if (i_ray[1][2] != 0) begin
            t_entry = max(t_entry, min(t_min_z, t_max_z));
            t_exit = min(t_exit, max(t_min_z, t_max_z));
        end

        intersects = (t_exit >= t_entry) && (t_entry >= 0);
    end

    function signed [31:0] max(signed [31:0] a, signed [31:0] b);
        max = a > b ? a : b;
    endfunction

    function signed [31:0] min(signed [31:0] a, signed [31:0] b);
        min = a < b ? a : b;
    endfunction

endmodule: ray_intersect_box
*/


// wrapper of intersect and reader
module tri_insector(
    input clk,
    input reset,
    input ivalid,  // enable, should be one cycle
    input [31:0] baseaddr, // const in one batch
    input [32*6-1:0] i_ray, // const in one batch
    input [31:0] i_tri_cnt, // sampled on ivalid

    output logic o_hit, // if there is any hit
    output logic signed [31:0] o_t, // min distance, if there is any hit
    output logic [31:0] o_tri_index, // triangle index of min distance
    output logic o_finish, // batch finish, high for one cycle

    // AVMM interface, SDRAM controller <-> reader <-> avalon_sdr
    output logic         avm_m0_read,
    output logic [31:0]  avm_m0_address,
    input  [15:0]        avm_m0_readdata,
    input                avm_m0_readdatavalid,
    output logic [1:0]   avm_m0_byteenable,
    input                avm_m0_waitrequest,

    output logic [32*4-1:0] dbg_out, // temp
    output logic dbg_out_en // temp
);

    logic reader_en, reader_ready, reader_valid;
    logic [32*9-1:0] reader_data;
    logic [31:0] reg_tri_cnt_in;
    reader #(
        .NDWORDS(9)
    ) tri_reader_inst (
        .clk(clk),
        .reset(reset),

        .baseaddr(baseaddr),
        .index(reg_tri_cnt_in),
        .read(reader_en),
        .data(reader_data),
        .ovalid(reader_valid),
        .iready(reader_ready),

        .avm_m0_read(avm_m0_read),
        .avm_m0_address(avm_m0_address),
        .avm_m0_readdata(avm_m0_readdata),
        .avm_m0_readdatavalid(avm_m0_readdatavalid),
        .avm_m0_byteenable(avm_m0_byteenable),
        .avm_m0_waitrequest(avm_m0_waitrequest)
    );

    logic signed [31:0] reader_tri [0:2][0:2];
    genvar i, j;
    generate begin: unflatten_reader_data
        for (i=0; i<3; ++i) begin: reader_data0
            for (j=0; j<3; ++j) begin: reader_data1
                assign reader_tri[i][j] = reader_data[32*(3*i+j+1)-1 : 32*(3*i+j)];
            end
        end
    end endgenerate

    logic signed [31:0] ray [0:1][0:2];
    generate begin: unflatten_ray_data
        for (i=0; i<2; ++i) begin: ray0
            for (j=0; j<3; ++j) begin: ray1
                assign ray[i][j] = i_ray[32*(3*i+j+1)-1 : 32*(3*i+j)];
            end
        end
    end endgenerate

    logic inter_valid;
    logic signed [31:0] t;
    logic hit;
    intersection #(
        .MIN_T(0)
    ) intersection_inst (
        .i_clk(clk),
        .i_rstn(~reset),
        .i_en(reader_valid),
        .i_tri(reader_tri),
        .i_ray(ray),
        .o_t(t),
        .o_result(hit),
        .o_valid(inter_valid),

        .dbg_out(dbg_out), // temp
        .dbg_out_en(dbg_out_en) // temp
    );

    logic [31:0] reg_tri_cnt_out, reg_tri_idx_min;
    logic signed [31:0] reg_t_min;
    logic reg_hit;
    logic reg_fin_in, reg_fin_out; // state of counter into reader and outof intersection

    assign reader_en = (reader_ready && ~reg_fin_in) ? 1'b1 : 1'b0;

    always_ff@(posedge clk) begin
        if(reset) begin
            reg_tri_cnt_in <= 'b0;
            reg_tri_cnt_out <= 'b0;
            reg_tri_idx_min <= 'b0;
            reg_t_min <= 'b0;
            reg_hit <= 1'b0;
            reg_fin_in <= 1'b1;
            reg_fin_out <= 1'b1;
        end else if (ivalid) begin
            reg_tri_cnt_in <= i_tri_cnt-1;
            reg_tri_cnt_out <= i_tri_cnt-1;
            reg_t_min <= `FIP_MAX;
            reg_hit <= 1'b0;
            reg_fin_in <= 1'b0;
            reg_fin_out <= 1'b0;
        end else begin
            // reader in
            if (reader_ready && ~reg_fin_in) begin
                if(reg_tri_cnt_in) begin
                    reg_tri_cnt_in <= reg_tri_cnt_in-1;
                end else begin
                    reg_fin_in <= 1'b1;
                end
            end
            // intersection out
            if (inter_valid && ~reg_fin_out) begin
                if (hit && t < reg_t_min) begin
                    reg_t_min <= t;
                    reg_tri_idx_min <= reg_tri_cnt_out;
                    reg_hit <= 1'b1;
                end

                if (reg_tri_cnt_out) begin
                    reg_tri_cnt_out <= reg_tri_cnt_out-1;
                end else begin
                    reg_fin_out <= 1'b1;
                end
            end
        end
    end

    assign o_hit = reg_hit;
    assign o_t = reg_t_min;
    assign o_tri_index = reg_tri_idx_min;
    assign o_finish = reg_fin_out;

endmodule: tri_insector
