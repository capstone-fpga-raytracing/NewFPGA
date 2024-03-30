module sub_divider #(
    parameter WIDTH = 32
)(
    input i_clk,
    input i_rst,
    input i_en,
    input [WIDTH-1:0] i_quotient_temp,
    input [WIDTH*2-1:0] i_dividend_copy,
    input [WIDTH*2-1:0] i_divider_copy,
    output logic [WIDTH-1:0] o_quotient_temp,
    output logic [WIDTH*2-1:0] o_dividend_copy,
    output logic [WIDTH*2-1:0] o_divider_copy,
    output logic o_valid
);

    logic [WIDTH*2-1:0] diff;
    assign diff = i_dividend_copy - i_divider_copy;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            o_quotient_temp <= 'b0;
            o_dividend_copy <= 'b0;
            o_divider_copy <= 'b0;
            o_valid <= 1'b0;
        end else begin
            o_quotient_temp <= i_quotient_temp << 1;
            if( !diff[WIDTH*2-1] ) begin
                o_dividend_copy <= diff;
                o_quotient_temp[0] <= 1'd1;
            end else begin
                o_dividend_copy <= i_dividend_copy;
            end
            o_divider_copy <= i_divider_copy >> 1;
            o_valid <= i_en;
        end
    end

endmodule: sub_divider


module divider #(
    parameter WIDTH = 32
)(
    input i_clk,
    input i_rst,
    input i_en,
    input [WIDTH-1:0] i_x,
    input [WIDTH-1:0] i_y,
    output logic [WIDTH-1:0] o_z,
    output logic o_valid
);

    logic [WIDTH-1:0] valid;
    logic valid_f;
    logic [WIDTH-1:0][WIDTH-1:0] quotient_temp;
    logic [WIDTH-1:0][WIDTH*2-1:0] dividend_copy;
    logic [WIDTH-1:0][WIDTH*2-1:0] divider_copy;

    logic [WIDTH*2-1:0] dividend_copy_f, divider_copy_f;

    sub_divider #(.WIDTH(WIDTH)) inst_first (i_clk, i_rst, valid_f, 'b0, dividend_copy_f, divider_copy_f,
                                             quotient_temp[0], dividend_copy[0], divider_copy[0], valid[0]);
    genvar i;
    generate begin: sub_dividers
        for (i = 1; i < WIDTH; i+=1) begin
            sub_divider #(.WIDTH(WIDTH)) inst (i_clk, i_rst, valid[i-1], quotient_temp[i-1], dividend_copy[i-1], divider_copy[i-1],
                                               quotient_temp[i], dividend_copy[i], divider_copy[i], valid[i]);
        end
    end endgenerate

    logic negative_output;
    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            dividend_copy_f <= 'b0;
            divider_copy_f <= 'b0;
            negative_output <= 1'b0;
            valid_f <= 1'b0;
        end else begin
            if (i_en) begin
                dividend_copy_f <= (!i_x[WIDTH-1]) ? {WIDTH'('b0),i_x} : {WIDTH'('b0),~i_x + 1'b1};
                divider_copy_f <= (!i_y[WIDTH-1]) ? {1'b0,i_y,(WIDTH-1)'('b0)} : {1'b0,~i_y + 1'b1,(WIDTH-1)'('b0)};
                negative_output <= ((i_y[WIDTH-1] && !i_x[WIDTH-1]) || (!i_y[WIDTH-1] && i_x[WIDTH-1]));
            end
            valid_f <= i_en;
        end
    end

    assign o_z = (!negative_output) ?
				  quotient_temp[WIDTH-1] :
				  ~quotient_temp[WIDTH-1] + 1'b1;
    assign o_valid = valid[WIDTH-1];

endmodule: divider

/*
reg [WIDTH-1:0] quotient_temp;
reg [WIDTH*2-1:0] dividend_copy, divider_copy, diff;
reg negative_output;
assign remainder = (!negative_output) ? dividend_copy[WIDTH-1:0] : ~dividend_copy[WIDTH-1:0] + 1'b1;
reg [5:0] bitv;
reg del_ready = 1;
assign ready = (!bitv) & ~del_ready;
wire [WIDTH-2:0] zeros = 0;
initial bitv = 0;
initial negative_output = 0;

always @( posedge clk ) 
begin
	del_ready <= !bitv;
	if( start ) 
	begin
		bitv = WIDTH;
		quotient = 0;
		quotient_temp = 0;
		dividend_copy = (!dividend[WIDTH-1]) ?
				{1'b0,zeros,dividend} :
				{1'b0,zeros,~dividend + 1'b1};			
		divider_copy = (!divider[WIDTH-1]) ?
				{1'b0,divider,zeros} :
				{1'b0,~divider + 1'b1,zeros};
		negative_output = 
			((divider[WIDTH-1] && !dividend[WIDTH-1])
			||(!divider[WIDTH-1] && dividend[WIDTH-1]));
	end
	else if ( bitv > 0 ) begin
		diff = dividend_copy - divider_copy;
		quotient_temp = quotient_temp << 1;
		if( !diff[WIDTH*2-1] ) begin
			dividend_copy = diff;
			quotient_temp[0] = 1'd1;
		end
		quotient = (!negative_output) ?
				quotient_temp :
				~quotient_temp + 1'b1;
		divider_copy = divider_copy >> 1;
		bitv = bitv - 1'b1;
	end
end
endmodule
*/