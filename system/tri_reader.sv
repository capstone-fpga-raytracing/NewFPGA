// this is terrible code and I should be jailed for it
//
//
// Index is the index of the tri in the tri list.
// Data can be sampled when ovalid is asserted.
// Read and index should be kept high until then.
// 
// If data is in cache, ovalid is asserted on the next
// cycle, otherwise it may take several cycles for
// it to be asserted.
//
module tri_reader
#(
   parameter NDWORDS = 9,
   localparam BLOCKSZ = 32*NDWORDS
)(
   input logic clk,
   input logic reset,
   
   input logic [31:0] baseaddr, // constant
   input logic [31:0] index,
   input logic read, // behaves like ivalid
   
   output logic [BLOCKSZ-1:0] data,
   
   output logic ovalid, // output valid
   output logic iready, // input ready
   
   // AVMM interface
   output logic         avm_m0_read,
   output logic         avm_m0_write, // unused
   output logic [15:0]  avm_m0_writedata, // unused
   output logic [31:0]  avm_m0_address,
   input  logic [15:0]  avm_m0_readdata,
   input  logic         avm_m0_readdatavalid,
   output logic [1:0]   avm_m0_byteenable,
   input  logic         avm_m0_waitrequest  
);

logic cache_op; // 0 for read, 1 for write
logic cache_en;

// data read from memory
wire [BLOCKSZ-1:0] mem_rddata;

reg pending_rq;
reg pending_rq_en, pending_rq_reset;

always_ff @(posedge clk)
begin
   if (reset || pending_rq_reset)
      pending_rq <= 1'b0;
   else if (pending_rq_en)
      pending_rq <= 1'b1;
end

reg [31:0] prev_index, cur_index;
always_ff @(posedge clk)
begin
   if (reset) begin
      prev_index <= 32'hFFFFFFFF;
      cur_index <= 32'hFFFFFFFF;
   end else if (read) begin
      cur_index <= index;
      prev_index <= cur_index;
   end
end

reg [1:0] t_selidx;

reg t_selidx_en;
reg [1:0] t_selidx_reg;
always_ff @(posedge clk)
begin
   if (reset)
      t_selidx_reg <= 2'd0;
   else if (t_selidx_en)
      t_selidx_reg <= t_selidx;
end

logic [31:0] sel_index;

always_comb begin
   case (t_selidx_reg)
      2'd0: sel_index = index;      // real-time
      2'd1: sel_index = cur_index;  // 1 cycle late
      2'd2: sel_index = prev_index; // 2 cycles late
      default: sel_index = index;
   endcase
end

cache_ro #(
   .SIZE_BLOCK(BLOCKSZ),
   .BIT_TOTAL(32),
   .BIT_INDEX(8), // is this okay?
   .WAY(1)
)
tri_cache(
   .i_clk(clk),
   .i_rst(reset),
   .i_en(cache_en),
   .i_wrt(cache_op),
   .i_addr(sel_index),
   .i_data(mem_rddata),
   .o_data(data),
   .o_success(ovalid)
);

logic mem_readstart;
logic mem_readend;

avalon_sdr #(
   .MAX_NREAD(NDWORDS),
   .MAX_NWRITE(1) // unused
)
sdram_reader
(
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
   
   .sdr_baseaddr(baseaddr+4*NDWORDS*sel_index),
   .sdr_nelems(NDWORDS),
   .sdr_readdata(mem_rddata), 
   .sdr_readstart(mem_readstart),
   .sdr_readend(mem_readend),
   .sdr_writedata('hDEADBEEF),
   .sdr_writestart(1'b0),
   .sdr_writeend()   
);

localparam CHECK_CACHE1 = 3'd0,
           CHECK_CACHE2 = 3'd1,
           SDRAM_RDASSERT = 3'd2,
           CHECK_CACHE_PENDING1 = 3'd3,
           CHECK_CACHE_PENDING2 = 3'd4,
           SDRAM_RDASSERT_PENDING = 3'd5;

logic [2:0] cur_state, next_state;

always_ff @(posedge clk) begin
   if (reset) cur_state <= CHECK_CACHE1;
   else cur_state <= next_state;
end

// if pending rq high, prev index is for mem read, and cur index is pending read
// if pending rq low, cur index is for mem read
   
always_comb
begin
   iready <= 1'b0;
   cache_en <= 1'b0;
   cache_op <= 1'b0;
   mem_readstart <= 1'b0;
   pending_rq_en <= 1'b0;
   pending_rq_reset <= 1'b0;
   
   t_selidx <= 2'd0;
   t_selidx_en <= 1'b0;

   case(cur_state)
      CHECK_CACHE1:
      begin
         cache_en <= read;
         cache_op <= 1'b0;
         iready <= 1'b1;
         next_state <= CHECK_CACHE2;
      end
   
      CHECK_CACHE2:
      begin
         cache_en <= read;
         cache_op <= 1'b0;
         iready <= 1'b1;
         
         if (!ovalid) // success from cache
         begin
            // is there an extra request?
            pending_rq_en <= read;
            // prev_index or cur_index
            t_selidx <= read ? 2'd2 : 2'd1;
            t_selidx_en <= 1'b1;
            mem_readstart <= 1'b1;
            next_state <= SDRAM_RDASSERT;
         end
         else next_state <= CHECK_CACHE2;
      end

      SDRAM_RDASSERT: 
      begin
         if (!mem_readend)
            next_state <= SDRAM_RDASSERT;
         else begin
            cache_en <= 1'b1;
            cache_op <= 1'b1;
            if (pending_rq) begin
               t_selidx <= 2'd1; // cur_index
               t_selidx_en <= 1'b1;
               next_state <= CHECK_CACHE_PENDING1;
            end else begin
               t_selidx <= 2'd0; // index
               t_selidx_en <= 1'b1;
               next_state <= CHECK_CACHE2;
            end
         end
      end
      
      CHECK_CACHE_PENDING1:
      begin
         cache_en <= 1'b1;
         cache_op <= 1'b0;
         next_state <= CHECK_CACHE_PENDING2;
      end
      
      CHECK_CACHE_PENDING2:
      begin
         if (ovalid) begin
            t_selidx <= 2'd0; // index
            t_selidx_en <= 1'b1;
            pending_rq_reset <= 1'b1;
            // does not go to check_cache1 but still works? bug?
            next_state <= CHECK_CACHE2;
         end else begin
            mem_readstart <= 1'b1;
            next_state <= SDRAM_RDASSERT_PENDING;
         end
      end
      
      SDRAM_RDASSERT_PENDING:
      begin
         if (!mem_readend)
            next_state <= SDRAM_RDASSERT_PENDING;
         else begin
            cache_en <= 1'b1;
            cache_op <= 1'b1;
            t_selidx <= 2'd0; // index
            t_selidx_en <= 1'b1;
            pending_rq_reset <= 1'b1;
            next_state <= CHECK_CACHE2;
         end
      end
   endcase

end

endmodule

