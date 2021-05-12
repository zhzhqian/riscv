module IO_MEM
    #(parameter CPU_CLOCK_FREQ    = 50_000_000,
        parameter BAUD_RATE         = 115200)
    (
    input [31:0] io_addr,
    input [3:0] io_we,
    input clk,
    input rst,
    input inst_valid,
    input [31:0] d,
    input SERIAL_IN,
    input [31:0] from_dmem_douta,
    input [31:0] from_dmem_doutb,

    output [31:0] to_dmem_dina,
    output [31:0] to_dmem_dinb,
    output [31:0] to_dmem_addra,
    output [31:0] to_dmem_addrb,
    output [3:0]  to_dmem_wea,
    output [3:0]  to_dmem_web,
    output conv_working,
    output reg [31:0] q,
    output SERIAL_OUT
    );
 
wire  [7:0] io_addr_piped;
wire [31:0] d_piped;
wire  [3:0]io_we_piped;
wire inst_valid_piped;
wire conv_idle_piped,conv_start_piped,conv_done_piped;

//pipline 
REGISTER_R #(.N(8))io_addr_reg(.d(io_addr[7:0]),.q(io_addr_piped),.rst(rst),.clk(clk));
REGISTER_R #(.N(32))d_reg(.d(d),.q(d_piped),.rst(rst),.clk(clk));
wire uart_tx_data_in_ready_piped,uart_rx_data_out_valid_piped;
wire [7:0] uart_rx_data_out_piped;
REGISTER_R #(.N(18))sig_reg(.d({{io_we},{inst_valid},{uart_tx_data_in_ready},{uart_rx_data_out_valid},{uart_rx_data_out},{conv_idle},{conv_start},{conv_done}}),
                            .q({{io_we_piped},{inst_valid_piped},{uart_tx_data_in_ready_piped},{uart_rx_data_out_valid_piped},{uart_rx_data_out_piped},{conv_idle_piped},{conv_start_piped},{conv_done_piped}}),
                            .rst(rst),.clk(clk));

wire [31:0] from_dmem_douta_piped,from_dmem_doutb_piped;
// REGISTER_R #(.N(32)) pip_dmem_dataa(.d(from_dmem_douta),.q(from_dmem_douta_piped),.rst(rst),.clk(clk));
// REGISTER_R #(.N(32)) pip_dmem_datab(.d(from_dmem_doutb),.q(from_dmem_doutb_piped),.rst(rst),.clk(clk));

wire [31:0] to_dmem_addra_before,to_dmem_addrb_before;
// REGISTER_R #(.N(32)) pip_dmem_addra(.d(to_dmem_addra_before),.q(to_dmem_addra),.rst(rst),.clk(clk));
// REGISTER_R #(.N(32)) pip_dmem_addrb(.d(to_dmem_addrb_before),.q(to_dmem_addrb),.rst(rst),.clk(clk));

wire [31:0] to_dmem_dataa_before,to_dmem_datab_before;
// REGISTER_R #(.N(32)) pip_to_dmem_dataa(.d(to_dmem_dataa_before),.q(to_dmem_dina),.rst(rst),.clk(clk));
// REGISTER_R #(.N(32)) pip_to_dmem_datab(.d(to_dmem_datab_before),.q(to_dmem_dinb),.rst(rst),.clk(clk));

wire [3:0] to_dmem_wea_before,to_dmem_web_before;
// REGISTER_R #(.N(8)) pip_dmem_wea(.d({{to_dmem_wea_before},{to_dmem_web_before}}),.q({{to_dmem_wea},{to_dmem_web}}),.rst(rst),.clk(clk));

assign from_dmem_douta_piped=from_dmem_douta;
assign from_dmem_doutb_piped=from_dmem_doutb;
assign to_dmem_addra=to_dmem_addra_before;
assign to_dmem_addrb=to_dmem_addrb_before;
assign to_dmem_dina=to_dmem_dataa_before;
assign to_dmem_dinb=to_dmem_datab_before;
assign to_dmem_wea=to_dmem_wea_before;
assign to_dmem_web=to_dmem_web_before;

// UART Receiver
wire [7:0] uart_rx_data_out;
wire uart_rx_data_out_valid;
reg uart_rx_data_out_ready;

uart_receiver #(
    .CLOCK_FREQ(CPU_CLOCK_FREQ),
    .BAUD_RATE(BAUD_RATE)) uart_rx (
    .clk(clk),
    .rst(rst),
    .data_out(uart_rx_data_out),             // output
    .data_out_valid(uart_rx_data_out_valid), // output
    .data_out_ready(uart_rx_data_out_ready), // input
    .serial_in(SERIAL_IN)               // input
);

// UART Transmitter
wire [7:0] uart_tx_data_in;
reg uart_tx_data_in_valid;
wire uart_tx_data_in_ready;

uart_transmitter #(
    .CLOCK_FREQ(CPU_CLOCK_FREQ),
    .BAUD_RATE(BAUD_RATE)) uart_tx (
    .clk(clk),
    .rst(rst),
    .data_in(uart_tx_data_in),             // input
    .data_in_valid(uart_tx_data_in_valid), // input
    .data_in_ready(uart_tx_data_in_ready), // output
    .serial_out(SERIAL_OUT)            // output
);
//output signal buffer
wire [31:0] cycle_conter_next;
wire [31:0] cycle_conter_val;
reg cycle_conter_rst;
REGISTER_R #(.N(32),.INIT(0)) cycle_conter(.clk(clk),.rst(rst|cycle_conter_rst),.d(cycle_conter_next),.q(cycle_conter_val));
assign cycle_conter_next=cycle_conter_val+1;
wire  [31:0] instruct_conter_next;
wire [31:0] instruct_conter_val;
reg instruct_conter_rst;
REGISTER_R #(.N(32),.INIT(0)) instruct_conter(.clk(clk),.rst(rst|instruct_conter_rst),.d(instruct_conter_next),.q(instruct_conter_val));   
reg conv_fm_dim_ce,conv_wt_offset_ce,conv_ifm_offset_ce,conv_ofm_offset_ce;
reg conv_rst,conv_start;
wire io_mem_write=io_we_piped[0]|io_we_piped[1]|io_we_piped[2]|io_we_piped[3];
wire conv_idle,conv_done;
assign instruct_conter_next=instruct_conter_val+inst_valid_piped;
assign uart_tx_data_in=d_piped[7:0];

always @(*)begin
    uart_tx_data_in_valid=0;
    uart_rx_data_out_ready=0;
    cycle_conter_rst=0;
    q=0;
    instruct_conter_rst=0;
    conv_rst=0;
    conv_start=0;
    conv_fm_dim_ce=0;
    conv_wt_offset_ce=0;
    conv_ifm_offset_ce=0;
    conv_ofm_offset_ce=0;
    case(io_addr_piped)
        8'h00: q= {30'b0,uart_rx_data_out_valid_piped,uart_tx_data_in_ready_piped};
        8'h04: begin
            //input data and ready to recive
            q={24'b0,uart_rx_data_out_piped};
            uart_rx_data_out_ready=1;
        end 
        8'h08: uart_tx_data_in_valid=io_mem_write;
        8'h10: q=cycle_conter_val;
        8'h14: q=instruct_conter_val;
        8'h18: begin
                cycle_conter_rst=io_mem_write;
                instruct_conter_rst=io_mem_write;
            end
        8'h18: conv_rst=io_mem_write;
        8'h40: conv_start=io_mem_write;
        8'h44: q={30'b0,conv_idle_piped,conv_done_piped};
        8'h48: conv_fm_dim_ce=io_mem_write;
        8'h4c: conv_wt_offset_ce=io_mem_write;
        8'h50: conv_ifm_offset_ce=io_mem_write;
        8'h54: conv_ofm_offset_ce=io_mem_write;
    endcase  
end

assign conv_working=~conv_idle_piped;

//conv_block
//wire dmem_to_conv_sel,dmem_from_conv_sel;

wire [31:0]conv_fm_dim,conv_wt_offset,conv_ifm_offset,conv_ofm_offset,conv_fm_dim_next,conv_wt_offset_next,conv_ifm_offset_next,conv_ofm_offset_next;

assign conv_fm_dim_next=d_piped;
assign conv_wt_offset_next=d_piped;
assign conv_ifm_offset_next=d_piped;
assign conv_ofm_offset_next=d_piped;

REGISTER_R_CE #(.N(32),.INIT(0)) conv_fm_dim_reg(.d(conv_fm_dim_next),.q(conv_fm_dim),.clk(clk),.rst(rst),.ce(conv_fm_dim_ce));
REGISTER_R_CE #(.N(32),.INIT(0)) conv_wt_offset_reg(.d(conv_wt_offset_next),.q(conv_wt_offset),.clk(clk),.rst(rst),.ce(conv_wt_offset_ce));
REGISTER_R_CE #(.N(32),.INIT(0)) conv_ifm_offset_reg(.d(conv_ifm_offset_next),.q(conv_ifm_offset),.clk(clk),.rst(rst),.ce(conv_ifm_offset_ce));
REGISTER_R_CE #(.N(32),.INIT(0)) conv_ofm_offset_reg(.d(conv_ofm_offset_next),.q(conv_ofm_offset),.clk(clk),.rst(rst),.ce(conv_ofm_offset_ce));

conv_block  conv_naive( .clk(clk), .rst(conv_rst|rst),
                .dmem_to_conva(from_dmem_douta_piped),.dmem_to_convb(from_dmem_doutb_piped),.to_dmem_wea(to_dmem_wea_before),.to_dmem_web(to_dmem_web_before),
                .conv_fm_dim(conv_fm_dim),.conv_wt_offset(conv_wt_offset),.conv_ifm_offset(conv_ifm_offset),.conv_ofm_offset(conv_ofm_offset),
                .dmem_from_conva(to_dmem_dataa_before),.dmem_from_convb(to_dmem_datab_before),.dmem_addra_from_conv(to_dmem_addra_before),.dmem_addrb_from_conv(to_dmem_addrb_before),
                .conv_idle(conv_idle),.conv_start(conv_start),.conv_done(conv_done));
endmodule

