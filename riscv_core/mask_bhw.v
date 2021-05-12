
module mask_bhw(bhw,mask,load_unsign,data_in,data_out);
    input [3:0]bhw;
    input [31:0] data_in;
    input load_unsign;
    output [31:0] data_out;
    input [3:0] mask;
    reg [31:0] data_unsign;
    assign  data_out=data_unsign;
    always @(*) begin
            data_unsign=data_in;
            case (mask)
                4'h1: data_unsign=(load_unsign)? {24'b0,data_in[7:0]}:{{24{data_in[7]}},data_in[7:0]};
                4'h2: data_unsign=(load_unsign)? {24'b0,data_in[15:8]}:{{24{data_in[15]}},data_in[15:8]};
                4'h4: data_unsign=(load_unsign)? {24'b0,data_in[23:16]}:{{24{data_in[23]}},data_in[23:16]};
                4'h8: data_unsign=(load_unsign)? {24'b0,data_in[31:24]}:{{24{data_in[31]}},data_in[31:24]};
                4'h3: data_unsign=(load_unsign)? {16'b0,data_in[15:0]}:{{16{data_in[15]}},data_in[15:0]};
                4'h6: data_unsign=(load_unsign)? {16'b0,data_in[23:8]}:{{16{data_in[23]}},data_in[23:8]};
                4'hc: data_unsign=(load_unsign)? {16'b0,data_in[31:16]}:{{16{data_in[31]}},data_in[31:16]};
            endcase 
        end

endmodule   

