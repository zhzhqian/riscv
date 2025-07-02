
module conv_block(input clk,
                input rst,
                input conv_start,
                input [31:0] dmem_to_conva,
                input [31:0] dmem_to_convb,
                input [31:0] conv_fm_dim,
                input [31:0] conv_wt_offset,
                input [31:0] conv_ifm_offset,
                input [31:0] conv_ofm_offset,

                output [31:0] dmem_from_conva,
                output [31:0] dmem_from_convb,
                output [31:0] dmem_addra_from_conv,
                output [31:0] dmem_addrb_from_conv,
                output [3:0]  to_dmem_wea,
                output [3:0]  to_dmem_web,
                output conv_idle,
                output conv_done
                 );


wire [31:0] conv_req_read_addr;
wire conv_req_read_addr_valid,conv_req_read_addr_ready;
wire [31:0] conv_req_read_len;
wire [31:0] conv_resp_read_data;
wire conv_resp_read_data_valid,conv_resp_read_data_ready;
wire [31:0] conv_req_write_addr;
wire conv_req_write_addr_valid,conv_req_write_addr_ready;
wire [31:0] conv_req_write_len;
wire [31:0] conv_req_write_data;
wire conv_req_write_data_valid,conv_req_write_data_ready;
wire conv_resp_write_status,conv_resp_write_status_valid,conv_resp_write_status_ready;

io_dmem_controller CONV2D_CON(.clk(clk),.rst(rst),
                            .dmem_douta(dmem_to_conva),.dmem_doutb(dmem_to_convb),.dmem_dina(dmem_from_conva),.dmem_dinb(dmem_from_convb),
                                .dmem_addra(dmem_addra_from_conv),.dmem_addrb(dmem_addrb_from_conv),.dmem_wea(to_dmem_wea),.dmem_web(to_dmem_web),
                            .req_read_addr(conv_req_read_addr),.req_read_addr_valid(conv_req_read_addr_valid),.req_read_addr_ready(conv_req_read_addr_ready),.req_read_len(conv_req_read_len),
                            .resp_read_data(conv_resp_read_data),.resp_read_data_valid(conv_resp_read_data_valid),.resp_read_data_ready(conv_resp_read_data_ready),
                            .req_write_addr(conv_req_write_addr),.req_write_addr_valid(conv_req_write_addr_valid),.req_write_addr_ready(conv_req_write_addr_ready),.req_write_len(conv_req_write_len),
                            .req_write_data(conv_req_write_data),.req_write_data_valid(conv_req_write_data_valid),.req_write_data_ready(conv_req_write_data_ready),
                            .resp_write_status(conv_resp_write_status),.resp_write_status_valid(conv_resp_write_status_valid),.resp_write_status_ready(conv_resp_write_status_ready)
                            );


// conv2D_naive conver(.clk(clk),.rst(rst),.start(conv_start),.idle(conv_idle),.done(conv_done),
//                     .fm_dim(conv_fm_dim),.wt_offset(conv_wt_offset),.ifm_offset(conv_ifm_offset),.ofm_offset(conv_ofm_offset),
//                     .req_read_addr(conv_req_read_addr),.req_read_addr_valid(conv_req_read_addr_valid),.req_read_addr_ready(conv_req_read_addr_ready),.req_read_len(conv_req_read_len),
//                     .resp_read_data(conv_resp_read_data),.resp_read_data_valid(conv_resp_read_data_valid),.resp_read_data_ready(conv_resp_read_data_ready),
//                     .req_write_addr(conv_req_write_addr),.req_write_addr_valid(conv_req_write_addr_valid),.req_write_addr_ready(conv_req_write_addr_ready),.req_write_len(conv_req_write_len),
//                     .req_write_data(conv_req_write_data),.req_write_data_valid(conv_req_write_data_valid),.req_write_data_ready(conv_req_write_data_ready),
//                     .resp_write_status(conv_resp_write_status),.resp_write_status_valid(conv_resp_write_status_valid),.resp_write_status_ready(conv_resp_write_status_ready)
//                     );
conv2D_opt conver_opt(.clk(clk),.rst(rst),.start(conv_start),.idle(conv_idle),.done(conv_done),
                    .fm_dim(conv_fm_dim),.wt_offset(conv_wt_offset),.ifm_offset(conv_ifm_offset),.ofm_offset(conv_ofm_offset),
                    .req_read_addr(conv_req_read_addr),.req_read_addr_valid(conv_req_read_addr_valid),.req_read_addr_ready(conv_req_read_addr_ready),.req_read_len(conv_req_read_len),
                    .resp_read_data(conv_resp_read_data),.resp_read_data_valid(conv_resp_read_data_valid),.resp_read_data_ready(conv_resp_read_data_ready),
                    .req_write_addr(conv_req_write_addr),.req_write_addr_valid(conv_req_write_addr_valid),.req_write_addr_ready(conv_req_write_addr_ready),.req_write_len(conv_req_write_len),
                    .req_write_data(conv_req_write_data),.req_write_data_valid(conv_req_write_data_valid),.req_write_data_ready(conv_req_write_data_ready),
                    .resp_write_status(conv_resp_write_status),.resp_write_status_valid(conv_resp_write_status_valid),.resp_write_status_ready(conv_resp_write_status_ready)
                    );
endmodule