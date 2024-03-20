module tri_insector(
    input logic clk,
    input logic reset,
    // constant
    input logic [31:0] tris_baseaddr,
    input logic [32*6-1:0] ray,
    input logic [31:0] tri_index,
    output logic hit,
    output logic signed [31:0] t,
    input logic ivalid,  // input valid, do not set unless input ready
    output logic iready, // input ready
    output logic ovalid, // output valid
    // AVMM interface
    output logic avm_m0_read,
    output logic avm_m0_write,
    output logic [15:0] avm_m0_writedata,
    output logic [31:0] avm_m0_address,
    input logic [15:0] avm_m0_readdata,
    input logic avm_m0_readdatavalid,
    output logic [1:0] avm_m0_byteenable,
    input logic avm_m0_waitrequest
);

    wire [BLOCKSZ-1:0] raw_data;

    fip [0:2][0:2] rdtri;
    genvar i, j;
    generate 
        for (i=0; i<3; ++i) begin: cast0
            for (j=0; j<3; ++j) begin: cast1
                assign rdtri[i][j] = (fip)raw_data[(32*(3*i+j+1)-1 : 32*(3*i+j)];
            end
        end
    endgenerate

    wire rddone;

    assign iready = rddone;

    tri_reader tri_read(
        .clk(clk),
        .reset(reset),
        .avm_m0_read(avm_m0_read),
        .avm_m0_write(avm_m0_write),
        .avm_m0_writedata(avm_m0_writedata),
        .avm_m0_address(avm_m0_address),
        .avm_m0_readdata(avm_m0_readdata),
        .avm_m0_readdatavalid(avm_m0_readdatavalid),
        .avm_m0_byteenable(avm_m0_byteenable),
        .avm_m0_waitrequest(avm_m0_waitrequest),
        .baseaddr(tris_baseaddr),
        .index(tri_index),
        .read(ivalid),
        .data(raw_data),
        .done(rddone)
    );
    
endmodule
//

module ray_tracer(
    input logic clk,
    input logic reset
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
    output logic [15:0] avm_m0_writedata,
);

    // State table
    localparam  READ_INIT = 3'd0,
                READ_START = 3'd1,
                READ_ASSERT = 3'd2,
                READ_DONE = 3'd3,
                WRITE_INIT = 3'd4,
                WRITE_ASSERT = 3'd5,
                WRITE_DONE = 3'd6;


    logic [2:0] cur_state, next_state;

    always_ff @(posedge sdr_clk) begin
    if (sdr_reset) cur_state <= READ_INIT;
    else cur_state <= next_state;
    end

    logic          start_rt;
    logic          end_rt;
    logic [31:0]   sdr_baseaddr;
    logic [29:0]   sdr_nelems;
    logic [31*7-1:0] sdr_read_numtris_ray;
    logic          sdr_readend;
    logic          sdr_readstart;
    logic [2047:0] sdr_writedata;
    logic          sdr_writeend;
    logic          sdr_writestart;
    logic          ivalid;

    always @* begin
        end_rt <= 1'b0;
        sdr_readstart <= 1'b0;
        sdr_writestart <= 1'b0;
        sdr_writedata <= 32'hBEEF;
        sdr_baseaddr <= 'hDEAD;
        sdr_nelems <= 'd0;
        rd_reset <= 1'b0;
        raytest_en <= 1'b0;
        ivalid <= 1'b0;

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
                // sdr_baseaddr <= 'b0;
                // sdr_nelems <= 30'd7; // inputs are hardcoded for avalon_sdr initial read
                end_rt <= sdr_readend;
                next_state <= sdr_readend ? TRI_INSECTOR_INIT : READ_ASSERT;
            end
            // After this state, the number of tris and ray are in sdr_read_numtris_ray 
            // and ready to be passed to tri_insector

            // haha 🐛
            TRI_INSECTOR: begin
                // base addr to tri_insector is 7 words from sdr_baseaddr
                sdr_baseaddr <= sdr_baseaddr + 'd7*4;
                
            end

            WRITE_INIT: begin
                sdr_writestart <= 1'b1;
                next_state <= WRITE_ASSERT;
            end

            WRITE_ASSERT: begin
                sdr_baseaddr <= 'b0;
                sdr_nelems <= 30'd1;
                end_rt <= sdr_writeend;
                next_state <= sdr_writeend ? WRITE_DONE : WRITE_ASSERT;
            end

            WRITE_DONE: begin
                next_state <= READ_INIT;
            end



        endcase

    end

    // Insantiate avalon_sdr to read first 7 words from SDRAM:
    // 0: Num Tris
    // 1-3: Ray origin
    // 4-6: Ray direction
    avalon_sdr read_initial(
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

        .sdr_baseaddr(32'b0),
        .sdr_nelems(30'd7),
        .sdr_readdata(sdr_read_numtris_ray),
        .sdr_readstart(sdr_readstart),
        .sdr_readend(sdr_readend),
        .sdr_writedata(sdr_writedata),
        .sdr_writestart(sdr_writestart),
        .sdr_writeend(sdr_writeend)
    );

endmodule