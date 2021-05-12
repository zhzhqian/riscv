`include "../EECS151.v"
module csr (
    input [31:0] addr,
    input [31:0] data,
    input csr_WE,
    input clk,
    input rst,
    output  reg [31:0] state);
    //addr
    localparam to_host_addr=31'h51e;
    wire [31:0] to_host_out;
    reg to_host_ce;
    //pipeline
    wire [31:0] addr_piped;
    wire [31:0] data_piped;
    wire csr_WE_piped;
    REGISTER_R #(.N(32)) pipe_addr(.d(addr),.q(addr_piped),.clk(clk),.rst(rst));
    REGISTER_R #(.N(32)) pipe_data (.d(data),.q(data_piped),.clk(clk),.rst(rst));
    REGISTER_R #(.N(1)) pipe_con_sig(.d(csr_WE),.q(csr_WE_piped),.rst(rst),.clk(clk)); 

    REGISTER_R_CE #(.N(32),.INIT(0)) to_host(.q(to_host_out),.d(data_piped),.rst(rst),.clk(clk),.ce(to_host_ce));

    always @(*) begin
        to_host_ce=0;
        state=to_host_out;
        if(addr_piped==to_host_addr)begin
            to_host_ce=csr_WE_piped;
        end
    end
endmodule