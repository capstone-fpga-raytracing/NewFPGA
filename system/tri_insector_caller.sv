// module tri_insector(
//     input clk,
//     input reset,
//     input ivalid,  // enable, should be one cycle
//     input [31:0] baseaddr, // const in one batch
//     input [32*6-1:0] i_ray, // const in one batch
//     input [31:0] i_tri_cnt, // sampled on ivalid

//     output logic o_hit, // if there is any hit
//     output logic signed [31:0] o_t, // min distance, if there is any hit
//     output logic [31:0] o_tri_index, // triangle index of min distance
//     output logic o_finish, // batch finish, stays high

//     // AVMM interface, SDRAM controller <-> reader <-> avalon_sdr
//     output logic         avm_m0_read,
//     output logic [31:0]  avm_m0_address,
//     input  [15:0]        avm_m0_readdata,
//     input                avm_m0_readdatavalid,
//     output logic [1:0]   avm_m0_byteenable,
//     input                avm_m0_waitrequest
// );

//     logic reader_en, reader_ready, reader_valid;
//     logic [32*9-1:0] reader_data;
//     reader #(
//         .NDWORDS(9)
//     ) tri_reader_inst (
//         .clk(clk),
//         .reset(reset),

//         .baseaddr(baseaddr),
//         .index(tri_cnt_in),
//         .read(reader_en),
//         .data(reader_data),
//         .ovalid(reader_valid),
//         .iready(reader_ready),

//         .avm_m0_read(avm_m0_read),
//         .avm_m0_address(avm_m0_address),
//         .avm_m0_readdata(avm_m0_readdata),
//         .avm_m0_readdatavalid(avm_m0_readdatavalid),
//         .avm_m0_byteenable(avm_m0_byteenable),
//         .avm_m0_waitrequest(avm_m0_waitrequest)
//     );

//     logic signed [31:0] reader_tri [0:2][0:2];
//     genvar i, j;
//     generate begin: unflatten_reader_data
//         for (i=0; i<3; ++i) begin: reader_data0
//             for (j=0; j<3; ++j) begin: reader_data1
//                 assign reader_tri[i][j] = reader_data[32*(3*i+j+1)-1 : 32*(3*i+j)];
//             end
//         end
//     end endgenerate

//     logic signed [31:0] ray [0:1][0:2];
//     generate begin: unflatten_ray_data
//         for (i=0; i<2; ++i) begin: ray0
//             for (j=0; j<3; ++j) begin: ray1
//                 assign ray[i][j] = i_ray[32*(2*i+j+1)-1 : 32*(2*i+j)];
//             end
//         end
//     end endgenerate

//     logic inter_valid;
//     logic signed [31:0] t;
//     logic hit;
//     intersection #(
//         .MIN_T(0)
//     ) intersection_inst (
//         .i_clk(clk),
//         .i_rstn(!reset),
//         .i_en(reader_valid),
//         .i_tri(reader_tri),
//         .i_ray(ray),
//         .o_t(t),
//         .o_result(hit),
//         .o_valid(inter_valid)
//     );

//     logic [31:0] reg_tri_cnt_in, reg_tri_cnt_out, reg_tri_idx_min;
//     logic signed [31:0] reg_t_min;
//     logic reg_hit;
//     always_ff@(posedge clk) begin
//         o_finish <= 1'b0;
//         if(reset) begin
//             reg_tri_cnt_in <= 'b0;
//             reg_tri_cnt_out <= 'b0;
//             reg_tri_idx_min <= 'b0;
//             reg_t_min <= 'b0;
//             reg_hit <= 1'b0;
//         end else if (ivalid) begin
//             reg_tri_cnt_in <= i_tri_cnt-1;
//             reg_tri_cnt_out <= i_tri_cnt-1;
//             reg_t_min <= `FIP_MAX;
//             reg_hit <= 1'b0;
//         end else begin
//             // decrease reg_tri_cnt_in and set reader_en if reader_ready
//             // decrease reg_tri_cnt_out if inter_valid
//             // and update reg_t_min , reg_tri_idx_min and reg_hit
//             // set o_finish when reg_tri_cnt_out == 0
//             if (reader_ready && !reg_tri_cnt_in) begin
//                 reg_tri_cnt_in <= reg_tri_cnt_in-1;
//                 reader_en <= 1'b1;
//             end
//             if (inter_valid) begin
//                 if (reg_tri_cnt_out) begin
//                     reg_tri_cnt_out <= reg_tri_cnt_out-1;
//                     if (t < reg_t_min) begin
//                         reg_t_min <= t;
//                         reg_tri_idx_min <= reg_tri_cnt_out;
//                         reg_hit <= 1'b1;
//                     end
//                 end else begin
//                     o_finish <= 1'b1;
//                 end
//             end
//         end
//     end

// endmodule: tri_insector


module ray_tracer(
    input logic clk,
    input logic reset,
    input logic start_rt,
    output logic end_rt,
    output logic [7:0] end_rtstat,
    // Avlon MM interface
    output logic avm_m0_read,
    output logic [31:0] avm_m0_address,
    input logic [15:0] avm_m0_readdata,
    input logic avm_m0_readdatavalid,
    output logic [1:0] avm_m0_byteenable,
    input logic avm_m0_waitrequest,
    output logic avm_m0_write,
    output logic [15:0] avm_m0_writedata
);

    // State table
    localparam  READ_INIT = 3'd0,
                READ_START = 3'd1,
                READ_ASSERT = 3'd2,
                TRI_INSECTOR = 3'd3,
                WRITE_INIT = 3'd4,
                WRITE_ASSERT = 3'd5,
                WRITE_DONE = 3'd6;


    logic [2:0] cur_state, next_state;

    always_ff @(posedge clk) begin
        if (reset) 
            cur_state <= READ_INIT;
        else 
            cur_state <= next_state;
    end

    logic [31:0]   sdr_baseaddr;
    logic [29:0]   sdr_nelems;
    logic [32*7-1:0] sdr_read_numtris_ray;
    logic          sdr_readend;
    logic          sdr_readstart;
    logic [2047:0] sdr_writedata;
    logic          sdr_writeend;
    logic          sdr_writestart;
    logic          ivalid;

    logic [31:0]   tri_baseaddr;
    logic [32*6-1:0] i_ray;
    logic [31:0]   i_tri_cnt;

    logic o_hit;
    logic signed [31:0] o_t;
    logic [31:0] o_tri_index;
    logic o_finish;

    assign end_rtstat = 8'd1;
    always @* begin
        end_rt <= 1'b0;
        sdr_readstart <= 1'b0;
        sdr_writestart <= 1'b0;
        sdr_writedata <= 32'hBEEF;
        sdr_baseaddr <= 'h0;
        sdr_nelems <= 'd0;
        ivalid <= 1'b0;
        tri_baseaddr <= 'b0;
        i_ray <= 'b0;
        i_tri_cnt <= 'b0;

        case(cur_state)
            // Read first 7 words from SDRAM to send to tri_insector
            READ_INIT: begin
                next_state <= start_rt ? READ_START : READ_INIT;
            end
            READ_START: begin
                sdr_readstart <= 1'b1;
                next_state <= READ_ASSERT;
            end
            
            READ_ASSERT: begin
                sdr_baseaddr <= 'b0;
                sdr_nelems <= 30'd7;
                next_state <= sdr_readend ? TRI_INSECTOR : READ_ASSERT;
            end
            // After this state, the number of tris and ray are in sdr_read_numtris_ray 
            // and ready to be passed to tri_insector

            // haha 🐛
            TRI_INSECTOR: begin
                // base addr to tri_insector is 7 words from sdr_baseaddr
                tri_baseaddr <= 'd28;
                // Ray is the first 6 words in sdr_read_numtris_ray
                i_ray <= sdr_read_numtris_ray[32*6-1:0];
                // Number of tris is the 7th word in the array
                i_tri_cnt <= sdr_read_numtris_ray[32*7-1:32*6];
                ivalid <= 1'b1;
                if(o_finish) begin
                    // Collect results from tri_insector
                    // ? Kept for tracking purposes, these values are assigned through
                    // ? tri_insector_inst outputs, and should be set in this state
                    // o_hit <= o_hit; 
                    // o_t <= o_t;
                    // o_tri_index <= o_tri_index;
                    next_state <= WRITE_INIT;
                end
                else
                    next_state <= TRI_INSECTOR;
                
            end

            WRITE_INIT: begin
                sdr_writestart <= 1'b1;
                next_state <= WRITE_ASSERT;
            end

            WRITE_ASSERT: begin
                sdr_baseaddr <= 'd24; // overwrite tri count, leave ray intact
                if(o_hit) begin
                    // hit, number of elems to write is 3
                    sdr_nelems <= 30'd3;
                    sdr_writedata <= {o_hit, o_t, o_tri_index};
                end
                else begin
                    // no hit, number of elems to write is 1
                    sdr_nelems <= 30'd1;
                    sdr_writedata <= {o_hit};
                end
                end_rt <= sdr_writeend;
                next_state <= sdr_writeend ? WRITE_DONE : WRITE_ASSERT;
            end

            WRITE_DONE: begin
                next_state <= READ_INIT;
            end
        endcase
    end

    // Instantiate avalon_sdr to read first 7 words from SDRAM:
    // 0: Num Tris
    // 1-3: Ray origin
    // 4-6: Ray direction
    avalon_sdr #(
        .MAX_NREAD(7),
        .MAX_NWRITE(3)
    )   sdr(
        .clk(clk),
        .reset(reset),
        // Avalon MM interface
        .avm_m0_read(avm_m0_read),
        .avm_m0_write(avm_m0_write),
        .avm_m0_writedata(avm_m0_writedata),
        .avm_m0_address(avm_m0_address),
        .avm_m0_readdata(avm_m0_readdata),
        .avm_m0_readdatavalid(avm_m0_readdatavalid),
        .avm_m0_byteenable(avm_m0_byteenable),
        .avm_m0_waitrequest(avm_m0_waitrequest),

        .sdr_baseaddr(sdr_baseaddr),
        .sdr_nelems(sdr_nelems),
        .sdr_readdata(sdr_read_numtris_ray),
        .sdr_readstart(sdr_readstart),
        .sdr_readend(sdr_readend),
        .sdr_writedata(sdr_writedata),
        .sdr_writestart(sdr_writestart),
        .sdr_writeend(sdr_writeend)
    );

    // tri_insector instance
    tri_insector tri_insector_inst(
        .clk(clk),
        .reset(reset),
        .ivalid(ivalid),
        .baseaddr(tri_baseaddr),
        .i_ray(i_ray),
        .i_tri_cnt(i_tri_cnt),
        .o_hit(o_hit),
        .o_t(o_t),
        .o_tri_index(o_tri_index),
        .o_finish(o_finish),
        .avm_m0_read(avm_m0_read),
        .avm_m0_address(avm_m0_address),
        .avm_m0_readdata(avm_m0_readdata),
        .avm_m0_readdatavalid(avm_m0_readdatavalid),
        .avm_m0_byteenable(avm_m0_byteenable),
        .avm_m0_waitrequest(avm_m0_waitrequest)
    );
endmodule