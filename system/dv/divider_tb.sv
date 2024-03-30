module divider_tb();
    localparam WIDTH = 48;
    logic clk, rst, en;
    logic [WIDTH-1:0] dividend, divider, quotient;
    logic o_valid;
    always #10 clk = ~clk;

    divider #(.WIDTH(WIDTH)) dut (clk, rst, en, dividend, divider, quotient, o_valid);

    initial begin
        clk=1;
        rst=1;
        repeat(10) @(posedge clk);
        rst=0;

        dividend = 48'h300000000;
        divider = 48'h10000;
        en = 1;
        @(posedge clk);
        en = 0;

        //repeat(20) @(posedge clk);
        dividend = 48'h200000000;
        divider = 48'h10000;
        en = 1;
        @(posedge clk);
        en = 0;

        //while(~ready) @(posedge clk);
        repeat(100) @(posedge clk);
        $stop();

    end


endmodule: divider_tb
