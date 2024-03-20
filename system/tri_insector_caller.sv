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
    // localparam  READ_INIT = 3'd0,
    //             READ_START = 3'd1,
    //             READ_ASSERT = 3'd2,
    //             TRI_INSECTOR = 3'd3,
    //             WRITE_INIT = 3'd4,
    //             WRITE_ASSERT = 3'd5,
    //             WRITE_DONE = 3'd6;
    localparam READ_INIT = 3'd0,
          READ_START = 3'd1,
          READ_ASSERT = 3'd2,
          READ_DONE = 3'd3,
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

    // always @* begin
    //     end_rt <= 1'b0;
    //     sdr_readstart <= 1'b0;
    //     sdr_writestart <= 1'b0;
    //     sdr_writedata <= 32'hBEEF;
    //     sdr_baseaddr <= 'hDEAD;
    //     sdr_nelems <= 'd0;
    //     // raytest_en <= 1'b0;

    //     case(cur_state)
    //         READ_INIT: begin
    //             next_state <= start_rt ? READ_START : READ_INIT;
    //         end
    //         READ_START: begin
    //             sdr_readstart <= 1'b1;
    //             next_state <= READ_ASSERT;
    //         end
    //         READ_ASSERT: begin
    //             sdr_baseaddr <= 'b0;
    //             sdr_nelems <= 30'd15;
    //             end_rt <= sdr_readend;
    //             next_state <= sdr_readend ? READ_DONE : READ_ASSERT;
    //         end
    //         READ_DONE: begin
    //             next_state <= WRITE_INIT;
    //         end
    //         WRITE_INIT: begin
    //             sdr_writestart <= 1'b1;
    //             next_state <= WRITE_ASSERT;
    //         end
    //         WRITE_ASSERT: begin
    //             sdr_baseaddr <= 'b0;
    //             sdr_nelems <= 30'd7;
    //             end_rt <= sdr_writeend;
    //             next_state <= sdr_writeend ? WRITE_DONE : WRITE_ASSERT;
    //         end
    //         WRITE_DONE: begin
    //             next_state <= READ_INIT;
    //         end
    //     endcase
    // end

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

    // logic avm_m0_read_sdr;
    // logic avm_m0_write_sdr;
    // logic [15:0] avm_m0_writedata_sdr;
    // logic [31:0] avm_m0_address_sdr;
    // logic [1:0] avm_m0_byteenable_sdr;

    // logic avm_m0_read_tri;
    // logic avm_m0_address_tri;
    // logic [1:0] avm_m0_byteenable_tri;

    // assign avm_m0_

    // // tri_insector instance
    // tri_insector tri_insector_inst(
    //     .clk(clk),
    //     .reset(reset),
    //     .ivalid(ivalid),
    //     .baseaddr(tri_baseaddr),
    //     .i_ray(i_ray),
    //     .i_tri_cnt(i_tri_cnt),
    //     .o_hit(o_hit),
    //     .o_t(o_t),
    //     .o_tri_index(o_tri_index),
    //     .o_finish(o_finish),
    //     .avm_m0_read(avm_m0_read),
    //     .avm_m0_address(avm_m0_address),
    //     .avm_m0_readdata(avm_m0_readdata),
    //     .avm_m0_readdatavalid(avm_m0_readdatavalid),
    //     .avm_m0_byteenable(avm_m0_byteenable),
    //     .avm_m0_waitrequest(avm_m0_waitrequest)
    // );
endmodule