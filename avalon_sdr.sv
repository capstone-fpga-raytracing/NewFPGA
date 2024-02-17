// reference: https://github.com/intel/multi_power_sequencer/blob/master/source/avmm_sequencer.sv
// Does not support unaligned accesses. Data is read/written from right to left.

module avalon_sdr 
#(
   // these are bogus. assign them as needed
   parameter MAX_NREAD = 1,
   parameter MAX_NWRITE = 1
)
(
   input  logic         clk,
   input  logic         reset,

   // AVMM interface
   output logic         avm_m0_read,
   output logic         avm_m0_write,
   output logic [15:0]  avm_m0_writedata,
   output logic [31:0]  avm_m0_address,
   input  logic [15:0]  avm_m0_readdata,
   input  logic         avm_m0_readdatavalid,
   output logic [1:0]   avm_m0_byteenable,
   input  logic         avm_m0_waitrequest,

   // external interface
   input  logic [31:0] sdr_baseaddr,
   input  logic [29:0] sdr_nelems,
   output logic [32*MAX_NREAD-1:0] sdr_readdata,
   input  logic [32*MAX_NWRITE-1:0] sdr_writedata,
   input  logic sdr_readstart,
   output logic sdr_readend,
   input  logic sdr_writestart,
   output logic sdr_writeend
);

logic [30:0] max_offset;
assign max_offset = 2*sdr_nelems - 1;

localparam INIT = 2'd0,
           READ_ASSERT = 2'd1,
           WRITE_ASSERT = 2'd2;

logic [1:0] cur_state, next_state;

always_ff @(posedge clk) begin
   if (reset) cur_state <= INIT;
   else cur_state <= next_state;
end

assign avm_m0_byteenable = 2'd3;

reg [30:0] offset;
reg offset_en;

always_ff @(posedge clk) begin
   if (reset || (cur_state == INIT)) begin
      offset <= 31'd0;
   end
   else if (clk) begin
      if (offset_en)
         offset++;
      else offset <= offset;
   end
end

always @* begin
   avm_m0_write <= 1'b0;
   avm_m0_read <= 1'b0;
   avm_m0_address <= 32'd0;
   avm_m0_writedata <= 1'b0;
   offset_en <= 1'b0;
   
   sdr_readdata <= 'b0;
   sdr_writeend <= 1'b0;
   sdr_readend <= 1'b0;
   
   case (cur_state)
      INIT: 
      begin
         if (sdr_writestart)
            next_state <= WRITE_ASSERT;
         else if (sdr_readstart)
            next_state <= READ_ASSERT;
         else 
            next_state <= cur_state;
      end
        
      WRITE_ASSERT: 
      begin
         avm_m0_write <= 1'b1;
         avm_m0_address <= sdr_baseaddr + (2 * offset);
         avm_m0_writedata <= sdr_writedata[16*offset +: 16];
         offset_en <= !avm_m0_waitrequest;
         
         if (!avm_m0_waitrequest && offset >= max_offset) begin
            sdr_writeend <= 1'b1;
            next_state <= INIT;
         end else 
            next_state <= WRITE_ASSERT;
      end
      
      READ_ASSERT: 
      begin
         avm_m0_read <= 1'b1;
         avm_m0_address <= sdr_baseaddr + (2 * offset);       
         sdr_readdata[16*offset +: 16] <= avm_m0_readdata;
         offset_en <= !avm_m0_waitrequest;
         
         if (!avm_m0_waitrequest && offset >= max_offset) begin
            sdr_readend <= 1'b1;
            next_state <= INIT;
         end else
            next_state <= READ_ASSERT;
      end
         
   endcase
end
    
endmodule
