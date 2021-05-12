module RAM_DP ( clk,rst,RA,RB,WA,WB,WEA,WEB,WAData,WBData,dataA,dataB);
	parameter DWITH=8 ;
    parameter AWIDTH=8;
    localparam DEPTH=32'd1<<AWIDTH;
	input clk;
	input rst;
	input[AWIDTH-1:0] RA;
	input[AWIDTH-1:0] RB;
	input[AWIDTH-1:0] WA;
    input[AWIDTH-1:0] WB ;
	input WEA;
    input WEB;
	input  [DWITH-1:0] WAData;
    input  [DWITH-1:0] WBData;
	output [DWITH-1:0] dataA;
	output [DWITH-1:0] dataB;

	reg[DWITH-1:0] regs[DEPTH-1:0];
	assign dataA=regs[RA];
	assign dataB=regs[RB];
	
	integer i;
	initial begin 
		for(i=0;i<DEPTH;i=i+1) 
			regs[i]<=0;
	end
	always @(posedge clk) begin
		if(WEA)
			regs[WA]<=WAData;
        if(WEB)
            regs[WB]<=WBData;
		if(rst)
			for(i=0;i<DEPTH;i=i+1)
				regs[i]<=0;
	end
endmodule
module REGISTER_R ( clk,rst,d,q
);
    parameter N =8 ;
    parameter INIT =0 ;
    input clk;
    input rst;
    input [N-1:0] d;
    output [N-1:0] q;

    reg[N-1:0] state;
    assign q=state;
    always @(posedge clk) begin
        state<=d;
        if(rst)
            state<=0;
    end
endmodule
module REGISTER_R_CE  #(
    parameter N =8, 
    parameter INIT =0 

)(
    input clk,
    input rst,
    input ce,
    input [N-1:0] d,
    output [N-1:0] q
);
    reg[N-1:0] state;
    assign q=state;
    always @(posedge clk) begin
        if(ce)
            state<=d;
        if(rst)
            state<=INIT;
    end
endmodule