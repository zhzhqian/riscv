

module synchronizer #(parameter WIDTH = 1) (
    input [WIDTH-1:0] async_signal,
    input clk,
    output [WIDTH-1:0] sync_signal
);
	    // TODO: Create your 2 flip-flop synchronizer here
	    // This module takes in a vector of WIDTH-bit asynchronous
      // (from different clock domain or not clocked, such as button press) signals
	    // and should output a vector of WIDTH-bit synchronous signals
      // that are synchronized to the input clk

	    // Remove this line once you create your synchronizer
	    wire flip1out;
	    REGISTER #(.N(WIDTH)) flip1(.d(async_signal),.q(sync_signal),.clk(clk));


endmodule
