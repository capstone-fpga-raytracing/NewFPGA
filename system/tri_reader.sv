
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
   localparam NDWORDS = 9,
   localparam BLOCKSZ = 32*NDWORDS
)(
   input logic clk,
   input logic reset,
   
   input logic [31:0] baseaddr,
   input logic [31:0] index,
   input logic read,
   
   output logic [BLOCKSZ-1:0] data,
   output logic done,
   
   // AVMM interface
   output logic         avm_m0_read,
   output logic         avm_m0_write,
   output logic [15:0]  avm_m0_writedata,
   output logic [31:0]  avm_m0_address,
   input  logic [15:0]  avm_m0_readdata,
   input  logic         avm_m0_readdatavalid,
   output logic [1:0]   avm_m0_byteenable,
   input  logic         avm_m0_waitrequest
    
)(

logic cache_op; // 0 for read, 1 for write
logic cache_en;

logic cache_success;

// data read from memory
wire [BLOCKSZ-1:0] mem_rddata;
// data read from cache
wire [BLOCKSZ-1:0] cache_rddata;

assign data = cache_rddata;

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
   .i_addr(index),
   .i_data(mem_rddata),
   .o_data(cache_rddata),
   .o_success(cache_success)
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
   
   .sdr_baseaddr(baseaddr+NDWORDS*index),
   .sdr_nelems(NDWORDS),
   .sdr_readdata(mem_rddata), 
   .sdr_readstart(mem_readstart),
   .sdr_readend(mem_readend),
   .sdr_writedata('hDEADBEEF),
   .sdr_writestart(1'b0),
   .sdr_writeend()   
);


localparam WAIT_READ = 3'd0,
           CHECK_DONE = 3'd1,
           SDRAM_RDASSERT = 3'd2,
           DONE = 3'd3;

logic [2:0] cur_state, next_state;

always_ff @(posedge clk) begin
   if (reset) cur_state <= INIT;
   else cur_state <= next_state;
end

always_comb
begin
   cache_en <= 1'b0;
   cache_op <= 1'b0;
   mem_readstart <= 1'b0;
   done <= 1'b0;
   
   case(cur_state)
      WAIT_READ: begin
         cache_en <= read;
         next_state <= CHECK_DONE;
      end
      
      CHECK_DONE: 
      begin
         done <= cache_success;
         if (cache_success)
            next_state <= WAIT_READ;         
         else begin
            mem_readstart <= 1'b1;
            next_state <= SDRAM_RDASSERT;
         end
      end

      SDRAM_RDASSERT: begin
         if (mem_readend) begin
            cache_en <= 1'b1;
            cache_op <= 1'b1;
            next_state <= DONE;
         end else
            next_state <= SDRAM_RDASSERT;
      end
      
      DONE: begin
         done <= 1'b1;
         next_state <= WAIT_READ;
      end
   endcase

end

endmodule