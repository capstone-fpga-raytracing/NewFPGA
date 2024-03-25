module raytracer_tb();
    logic clk, reset;
    always #10 clk = ~clk;

    logic avm_m0_read;
    logic [31:0] avm_m0_address;
    logic [15:0] avm_m0_readdata;
    logic avm_m0_readdatavalid, avm_m0_waitrequest;
    logic [1:0] drop_byteenable;
    
    logic start_rt, end_rt;
    logic end_rtstat;
	 
	 logic avm_m0_write;
	 logic [15:0] avm_m0_writedata;

    ray_tracer dut (
        .clk(clk),
        .reset(reset),
        .start_rt(start_rt),
        .end_rt(end_rt),
        .end_rtstat(end_rtstat),

        .avm_m0_read(avm_m0_read),
		  .avm_m0_write(avm_m0_write),
		  .avm_m0_writedata(avm_m0_writedata),
        .avm_m0_address(avm_m0_address),
        .avm_m0_readdata(avm_m0_readdata), // 2 cyles to return 1 word
        .avm_m0_readdatavalid(avm_m0_readdatavalid), // 2 cyles to return 1 word
        .avm_m0_byteenable(drop_byteenable), // ignore
        .avm_m0_waitrequest(avm_m0_waitrequest) // const = 0
    );
    
    logic signed [31:0] i_ray [0:1][0:2];

    // tri[0:2]
    logic signed [31:0] i_tri [0:2][0:2][0:2];
    always_comb begin
    
        i_ray[0] = '{'b0, 'b0, 1 << 16};
        i_ray[1] = '{'b0, 'b0, -1 << 16};
         
        // tri
        i_tri[0][0] = '{'b0, 2 << 16, 'b0};
        i_tri[0][1] = '{-2 << 16, -2 << 16, 'b0};
        i_tri[0][2] = '{2 << 16, 2 << 16, 'b0};
        // expects result = 1, t = 65536 (1)

        i_tri[1][0] = '{'b0, 2 << 16, -2 << 16};
        i_tri[1][1] = '{-2 << 16, -2 << 16, -2 << 16};
        i_tri[1][2] = '{2 << 16, -2 << 16, -2 << 16};
        // expects result = 1, t = 196608 (3)

        i_tri[2][0] = '{'b0, 2 << 16, 'b0};
        i_tri[2][1] = '{-2 << 16, 2 << 16, 'b0};
        i_tri[2][2] = '{2 << 16, 2 << 16, 'b0};
        // expects result = 0, t = x (default in simulation of div by 0)
    end

    task automatic pass_tri(
        input int tri_num); begin

        for(int i = 0; i < tri_num; i+=1) begin
            while(!avm_m0_read) @(posedge clk);
            avm_m0_readdatavalid = 'b1;
            $display("[%d]starting tri: %0d", $time(), i);
            for(int j = 0; j < 3; j+=1) begin
                for(int k = 0; k < 3; k+=1) begin
                    avm_m0_readdata = i_tri[i][j][k][15:0];
                    @(posedge clk);
                    avm_m0_readdata = i_tri[i][j][k][31:16];
                    @(posedge clk);
                end
            end
            $display("[%0d]finished tri: %0d", $time(), i);
            avm_m0_readdatavalid = 'b0;
        end

    end endtask
	 
	 task automatic pass_ray(); 
	 begin

        while(!avm_m0_read) @(posedge clk);
		  
        avm_m0_readdatavalid = 'b1;
        $display("[%d]starting ray", $time());
        for(int j = 0; j < 2; j+=1) begin
            for(int k = 0; k < 3; k+=1) begin
                avm_m0_readdata = i_ray[j][k][15:0];
                @(posedge clk);
                avm_m0_readdata = i_ray[j][k][31:16];
                @(posedge clk);
            end
        end
        $display("[%0d]finished ray", $time());
        avm_m0_readdatavalid = 'b0;

    end endtask

    initial begin
        clk = 'b1;
        reset = 'b1;
        start_rt = 1'b0;
        avm_m0_readdata = 'b0;
        avm_m0_readdatavalid = 'b0;
        avm_m0_waitrequest = 'b0;
        repeat(6) @(posedge clk);
        reset = 'b0;
        repeat(6) @(posedge clk);
        
        
        start_rt = 1'b1;
        @(posedge clk);
        start_rt = 1'b0;
        
        pass_ray();
		  avm_m0_readdatavalid = 1'b1;
		  avm_m0_readdata = 16'd3;
		  @(posedge clk);
		  avm_m0_readdata = 16'd0;
		  @(posedge clk);
		  avm_m0_readdatavalid = 1'b0;
        
        
        $display("[%0d]starting passing tri", $time());
        pass_tri(3);
        $display("[%0d]passing tri end", $time());
		  

        // set en, baseaddr, i_ray, i_tri_cnt, avm_m0_readdata, avm_m0_readdatavalid
        // monitor o_hit, o_t, o_tri_index, o_finish, avm_m0_read, avm_m0_address

        // start
        //ray[0] = '{'b0, 'b0, 1 << 16};
        ///ray[1] = '{'b0, 'b0, -1 << 16};
        //i_ray = 'b0;
        //i_ray[95:64] = 1 << 16;
        //i_ray[191:160] = -1 << 16;
//
        //baseaddr = 'h1000;
        //i_tri_cnt = 'd3;
        //en = 'b1;
        //@(posedge clk);
        //$display("[%0d]enabled", $time());
        //en = 'b0;
//
        //repeat (4) @(posedge clk);
        //$display("[%0d]starting passing tri", $time());
        //pass_tri(3);
        //$display("[%0d]passing tri end", $time());
//
        //repeat(20) @(posedge clk);
//
        //$display("[%0d]tri_insector: test end\n", $time());
        #5000 $finish;
        $stop();
    end
endmodule: raytracer_tb
