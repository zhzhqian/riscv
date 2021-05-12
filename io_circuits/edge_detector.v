

module edge_detector #(
    parameter WIDTH = 1
)(
    input clk,
    input [WIDTH-1:0] signal_in,
    output [WIDTH-1:0] edge_detect_pulse
);

      // TODO: implement an edge detector that detects a rising edge of 'signal_in'
      // and outputs a one-cycle pulse at the next clock edge
      // Feel free to use as many number of registers you like
      wire [WIDTH-1:0] in;
       wire [WIDTH-1:0] stateout;
       wire [WIDTH-1:0] cycleout;
      
      genvar i;
      generate 
      for(i=0;i<WIDTH;i=i+1) begin
          REGISTER #(.N(1)) cycle(.d(in[i]),.q(edge_detect_pulse[i]),.clk(clk));
          REGISTER #(.N(1)) state(.d(signal_in[i]),.q(stateout[i]),.clk(clk));
          assign in[i]=(~edge_detect_pulse[i])&signal_in[i]&~stateout[i];
      end
      endgenerate 
endmodule
