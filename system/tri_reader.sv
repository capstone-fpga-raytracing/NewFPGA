
// Index is the index of the tri in the tri list.
// Data can be sampled when done is asserted.
// Read and index should be kept high until then.
// 
// If data is in cache, done is asserted on the next
// cycle, otherwise it may take several cycles for
// done to be asserted.
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
   
   output logic ovalid,
   output logic iready,
   
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
   .MAX_NWRITE(1), // unused
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
   
   .sdr_baseaddr(baseaddr+NDWORDS*sel_index),
   .sdr_nelems(NDWORDS),
   .sdr_readdata(mem_rddata), 
   .sdr_readstart(mem_readstart),
   .sdr_readend(mem_readend),
   .sdr_writedata('hDEADBEEF),
   .sdr_writestart(1'b0),
   .sdr_writeend()   
);


localparam CHECK_CACHE = 3'd1,
           SDRAM_RDASSERT = 3'd2,
			  CHECK_CACHE_PENDING1 = 3'd3,
			  CHECK_CACHE_PENDING2 = 3'd4,
			  SDRAM_RDASSERT_PENDING = 3'd5;

logic [2:0] cur_state, next_state;

always_ff @(posedge clk) begin
   if (reset) cur_state <= CHECK_CACHE1;
   else cur_state <= next_state;
end

// if pending rq high, prev index contains the mem read, and cur index contains the pending read
// if pending rq low, cur index contains the mem read index
   
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
      CHECK_CACHE:
		begin
			cache_en <= read; // i_en
			cache_op <= 1'b0; // i_wrt
			iready <= 1'b1; // input ready (busy if this is 0)
			
			// this is okay, first read is always a cache miss
			if (read && !ovalid) // o_success, also output valid for this module
			begin
				// is there an extra request?
				pending_rq_en <= read;
				// prev_index or cur_index
				t_selidx <= read ? 2'd2 : 2'd1;
				t_selidx_en <= 1'b1;
				mem_readstart <= 1'b1;
				next_state <= SDRAM_RDASSERT;
			end
			else next_state <= CHECK_CACHE;
      end

      SDRAM_RDASSERT: 
		begin
         if (!mem_readend)
				next_state <= SDRAM_RDASSERT;
			else begin
            cache_en <= 1'b1;
            cache_op <= 1'b1;
				if (pending_rq)
					t_selidx <= 2'd1; // cur_index
					t_selidx_en <= 1'b1;
					next_state <= CHECK_CACHE_PENDING1;
				else begin
					t_selidx <= 2'd0; // index
					t_selidx_en <= 1'b1;
					next_state <= CHECK_CACHE;
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
				t_selidx <= 2'd0;
				t_selidx_en <= 1'b1;
				pending_rq_reset <= 1'b1;
				next_state <= CHECK_CACHE;
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
				t_selidx <= 2'd0;
				t_selidx_en <= 1'b1;
				pending_rq_reset <= 1'b1;
				next_state <= CHECK_CACHE;
			end
		end
   endcase

end

endmodule


// avalonmm read protects its registers
// by having an extra cycle for done signal,
// in our case we must start again immediately

// cache stage must exist simultaneously with
// memory read, to receive the next request but
// wait on it


/*
reg curidx_en, nextidx_en;
reg [31:0] cur_idx, next_idx;

always_ff @(posedge clk)
begin
	if (reset)
		next_idx <= 32'hFFFFFFFF;
	else if (nextidx_en)
		next_idx <= read ? index : 32'hFFFFFFFF;
end

always_ff @(posedge clk)
begin
	if (reset)
		cur_idx <= 32'hFFFFFFFF;
	else if (read && saved_idxen)
		saved_idx <= index;
end
*/


// iready needs to be 1 initially,
// then after the first read it should
// be 1 if the last ovalid was 1.

/*
reg iready_en;
reg ireadyst, nextireadyst;

always_ff @(posedge clk)
begin
	if (reset) begin
		iready <= 1'b1;
		ireadyst <= 1'b0;
	end
	else begin
		ireadyst <= nextireadyst;		
		if (iready_en)
			iready <= 1'b1;		
	end
end

always_comb
begin
	iready_en = 1'b0;
	case (ireadyst)
		1'b0: 
			nextireadyst <= read ? 1'b1: 1'b0;
		1'b1: begin
			iready_en <= ovalid;
			nextireadyst <= 1'b1;
		end
	endcase
end
*/

// read from memory always on the prev_index
// how to check if a cur_index must also be serviced?