
module conv2D_opt #(
    parameter AWIDTH  = 32,
    parameter DWIDTH  = 32,
    parameter WT_DIM  = 3
) (
    input clk,
    input rst,

    // Control/Status signals
    input start,
    output idle,
    output done,

    // Scalar signals
    input  [31:0]       fm_dim,
    input  [31:0]       wt_offset,
    input  [31:0]       ifm_offset,
    input  [31:0]       ofm_offset,

    // Read Request Address channel
    output [AWIDTH-1:0] req_read_addr,
    output              req_read_addr_valid,
    input               req_read_addr_ready,
    output [31:0]       req_read_len, // burst length

    // Read Response channel
    input [DWIDTH-1:0]  resp_read_data,
    input               resp_read_data_valid,
    output              resp_read_data_ready,

    // Write Request Address channel
    output [AWIDTH-1:0] req_write_addr,
    output              req_write_addr_valid,
    input               req_write_addr_ready,
    output [31:0]       req_write_len, // burst length

    // Write Request Data channel
    output [DWIDTH-1:0] req_write_data,
    output              req_write_data_valid,
    input               req_write_data_ready,

    // Write Response channel
    input                resp_write_status,
    input                resp_write_status_valid,
    output               resp_write_status_ready
);
    localparam WT_SIZE=WT_DIM*WT_DIM;
    localparam HALF_WT_DIM=WT_DIM>>1;
    //state 
    localparam idle_state=3'b000;
    localparam read_w_state=3'b001;
    localparam read_ifm_delay_state=3'b010;
    localparam read_ifm_state=3'b011;
    localparam compute_mul_state=3'b100;
    localparam compute_add_state=3'b110;
    localparam write_ofm_state=3'b101;
    localparam done_state=3'b111;
    //do not use bust mode when writting ofm
    assign req_write_len=1;

    wire [2:0] state;
    reg [2:0]state_next;
    REGISTER_R #(.N(3),.INIT(0)) state_reg(.d(state_next),.q(state),.clk(clk),.rst(rst));

    assign idle=state==idle_state;

    wire done_q;
    //control signal
    reg rst_control;

    assign done = ~start & done_q;

    // start register -- asserts when 'start', and stays HIGH until reset
    wire start_q;
    REGISTER_R_CE #(.N(1), .INIT(0)) start_reg (
        .q(start_q),
        .d(1'b1),
        .ce(start),
        .rst(done | rst),
        .clk(clk));

    // done register -- asserts when the conv2D is done, and stay HIGH until reset
    REGISTER_R_CE #(.N(1), .INIT(0)) done_reg (
        .q(done_q),
        .d(1'b1),
        .ce(start_q & idle),
        .rst(start | rst),
        .clk(clk));

    wire req_read_addr_fire=req_read_addr_ready&req_read_addr_valid;
    wire req_write_addr_fire=req_write_addr_ready&req_write_addr_valid;
    wire req_write_data_fire=req_write_data_ready&req_write_data_valid;
    wire resp_write_status_fire   = resp_write_status_valid   & resp_write_status_ready;
    
    wire read_data_fire=resp_read_data_ready&resp_read_data_valid;

    wire reading_w=(state==read_w_state)&read_data_fire; 
    wire read_done=row_q==WT_DIM-1 & col_q==WT_DIM-1&read_mem;
    wire reading_ifm=(state==read_ifm_state)&(read_data_fire|halo);

    wire writting_mem=fifo_enq_write_addr_fire;

    wire fifo_enq_write_addr_fire=fifo_enq_write_addr_valid&fifo_enq_write_addr_ready;
    // x_loc_val ofm raw location
    wire x_loc_ce,x_loc_rst;
    wire [31:0] x_loc_next,x_loc_val;
    REGISTER_R_CE #(.N(32),.INIT(0)) x_loc_reg(.d(x_loc_next),.q(x_loc_val),.rst(x_loc_rst),.ce(x_loc_ce),.clk(clk));
    //x_loc_val copy to decrease fanout
    wire x_loc_ce_cp,x_loc_rst_cp;
    wire [31:0] x_loc_next_cp,x_loc_val_cp;
    REGISTER_R_CE #(.N(32),.INIT(0)) x_loc_reg_copy(.d(x_loc_next_cp),.q(x_loc_val_cp),.rst(x_loc_rst_cp),.ce(x_loc_ce_cp),.clk(clk));
    //y_loc_val ofm col location
    wire y_loc_ce,y_loc_rst;
    wire [31:0] y_loc_next,y_loc_val;
    REGISTER_R_CE #(.N(32),.INIT(0)) y_loc_reg(.d(y_loc_next),.q(y_loc_val),.rst(y_loc_rst),.ce(y_loc_ce),.clk(clk));
    //in a slide window, withc row or col we are reading
    wire [31:0] row_d, row_q;
    wire row_ce, row_rst;

    REGISTER_R_CE #(.N(32), .INIT(0)) slidingWindow_row_reg (
        .q(row_q),
        .d(row_d),
        .ce(row_ce),
        .rst(row_rst),
        .clk(clk)
    );

    // y index register: 0 --> fm_dim - 1
    wire [31:0] col_d, col_q;
    wire col_ce, col_rst;

    REGISTER_R_CE #(.N(32), .INIT(0)) slidingWindow_col_reg (
        .q(col_q),
        .d(col_d),
        .ce(col_ce),
        .rst(col_rst),
        .clk(clk)
    );
    // counter show whether add operation is over 
    wire [31:0] counter_d, counter_q;
    wire counter_ce, counter_rst;
    REGISTER_R_CE #(.N(32), .INIT(0)) add_counter (
        .q(counter_q),
        .d(counter_d),
        .ce(counter_ce),
        .rst(counter_rst),
        .clk(clk)
    );

    //in a slide window  point witch element we should read.
    wire signed [31:0] idx=x_loc_val_cp-HALF_WT_DIM+row_q;
    wire signed [31:0] idy=y_loc_val-HALF_WT_DIM+col_q;

    // the raw exsit halo element
    wire halo=idx<0|idx>=fm_dim|idy<0|idy>=fm_dim;
    // if we are reading halo raw,we do not read mem,if the raw has few halo element we do not need read WTDIM elements
    assign req_read_len=(state==read_w_state)? WT_SIZE: (state==read_ifm_state)? WT_DIM-col_q :0;
    //buf idx and idy
    wire [31:0] idx_buffed,idy_buffed;
    REGISTER_R #(.N(32)) BUF_IDX(.d(idx),.q(idx_buffed),.clk(clk),.rst(rst));
    REGISTER_R #(.N(32)) BUF_IDY(.d(idy),.q(idy_buffed),.clk(clk),.rst(rst));

    wire [31:0] ifm_idx=idx*fm_dim+idy;
    wire [31:0] ofm_idx=x_loc_val*fm_dim+y_loc_val;

    wire read_mem=reading_ifm|reading_w;
    wire write_mem = fifo_enq_write_addr_fire & state==write_ofm_state;

    assign x_loc_next=x_loc_val+1;
    assign x_loc_rst=(x_loc_val==fm_dim-1  & write_mem) | rst_control;
    assign x_loc_ce=write_mem;

    assign x_loc_next_cp=x_loc_val_cp+1;
    assign x_loc_rst_cp=(x_loc_val_cp==fm_dim-1  & write_mem) | rst_control;
    assign x_loc_ce_cp=write_mem;

    assign y_loc_next=y_loc_val+1;
    assign y_loc_rst=(y_loc_val==fm_dim-1 & x_loc_val==fm_dim-1& write_mem) | rst_control;
    assign y_loc_ce=write_mem& x_loc_val==fm_dim-1 ;

    assign row_d=(row_q==WT_DIM-1& col_q==WT_DIM-1  & reading_ifm &x_loc_val<fm_dim-1) ? WT_DIM-1:row_q+1;
    assign row_ce=col_ce&col_q==WT_DIM-1;
    assign row_rst=(row_q==WT_DIM-1& col_q==WT_DIM-1  &read_mem&(~(state==read_ifm_state&x_loc_val<fm_dim-1))) |rst_control;

    assign col_d=col_q+1;
    assign col_ce=read_mem;
    assign col_rst= col_q==WT_DIM-1  & read_mem |rst_control;
    
    assign counter_d=counter_q+1;
    assign counter_ce=computing_add;
    assign counter_rst=counter_q==WT_SIZE-1 & computing_add|rst_control;

    wire [DWIDTH-1:0] w_reg_val[WT_SIZE:0];
    wire [DWIDTH-1:0] x_reg_val[WT_SIZE:0];
    wire [DWIDTH-1:0] mul_reg_val[WT_SIZE:0];

    wire [DWIDTH-1:0] mul_reg_in[WT_SIZE-1:0];
    wire x_reg_ce[WT_SIZE-1:0];
    wire w_reg_ce[WT_SIZE-1:0];
    wire mul_reg_ce[WT_SIZE-1:0];

    //when load=1,load the multiplier value,or as a shift register.
    wire mul_reg_load= state==compute_mul_state ;
    assign mul_reg_val[WT_SIZE]=0;
  
    //generate register
    genvar i;
    generate 
        for(i=0;i<WT_SIZE;i=i+1)  begin
                REGISTER_R_CE #(.N(DWIDTH),.INIT(0)) W_REG(.d(w_reg_val[i+1]),.q(w_reg_val[i]),.clk(clk),.ce(w_reg_ce[i]),.rst(rst_control));
                REGISTER_R_CE #(.N(DWIDTH),.INIT(0)) X_REG(.d(x_reg_val[i+1]),.q(x_reg_val[i]),.clk(clk),.ce(x_reg_ce[i]),.rst(rst_control));
                assign w_reg_ce[i]=reading_w;
                assign x_reg_ce[i]=reading_ifm;
                assign mul_reg_in[i]=(mul_reg_load)? x_reg_val[i]*w_reg_val[i]:mul_reg_val[i+1];
                assign mul_reg_ce[i]=mul_reg_load|(state==compute_add_state);
                REGISTER_R_CE #(.N(DWIDTH)) MUL_REG(.d(mul_reg_in[i]),.q(mul_reg_val[i]),.clk(clk),.ce(mul_reg_ce[i]),.rst(rst_control));
            end
    endgenerate

    wire [DWIDTH-1:0] acc_q, acc_d;
    wire              acc_ce, acc_rst;
    REGISTER_R_CE #(.N(DWIDTH), .INIT(0)) acc_reg (
        .q(acc_q),
        .d(acc_d),
        .ce(acc_ce),
        .rst(acc_rst),
        .clk(clk)
    );
    assign acc_rst=~(state==compute_add_state)|rst_control;
    assign acc_d=acc_q+mul_reg_val[0];
    //when first cycle should be zero
    assign acc_ce=computing_add;
    

    assign computing_add= state==compute_add_state ;

    assign compute_add_done=(counter_q==WT_SIZE-1)&computing_add;
    assign w_reg_val[WT_SIZE]=resp_read_data;  
    assign x_reg_val[WT_SIZE]=(halo)? 0: resp_read_data;

    always @(*) begin
        state_next=state;
        rst_control=rst;
        case(state)
            idle_state: begin
                rst_control=1;
                if(start)
                    state_next=read_w_state;
            end
            read_w_state:begin
                if(read_done)
                    state_next=read_ifm_state;
            end
            read_ifm_state:begin
                if(read_done) 
                    state_next=compute_mul_state;
            end
            compute_mul_state:
                    //mul cost only one cycle
                    state_next=compute_add_state;
            compute_add_state: begin
                if(compute_add_done) 
                    state_next=write_ofm_state;
            end
            write_ofm_state: begin
                if(x_loc_val==fm_dim-1&y_loc_val==fm_dim-1&write_mem)
                    state_next=done_state;
                else if(write_mem)
                    state_next=read_ifm_state;
            end
            done_state:begin
                if (resp_write_status & resp_write_status_fire)
                    state_next = idle_state;
            end
            default: state_next=idle_state;
        endcase
    end

    //req_read_addr is (idx,idy) addr
    wire[31:0] wdata=acc_q;

    assign req_read_addr    =(state==read_w_state)  ?   wt_offset: 
                                (state==read_ifm_state) ? ifm_offset+ifm_idx:0;
    assign req_read_addr_valid=(state==read_ifm_state&(~halo))|  (state==read_w_state);

    assign resp_read_data_ready=(state==read_w_state)|(state==read_ifm_state);

    assign fifo_enq_write_addr=ofm_offset+ofm_idx;
    assign fifo_enq_write_addr_valid=state==write_ofm_state;
    assign fifo_enq_write_data=wdata;
    assign fifo_enq_write_data_valid=state==write_ofm_state;

    assign resp_write_status_ready=1'b1;
     // Buffering write_addr and write_data requests
    // Set the buffer large enough so that we don't have to handle back-pressure
    wire [AWIDTH-1:0] fifo_enq_write_addr;
    wire fifo_enq_write_addr_valid, fifo_enq_write_addr_ready;
    fifo #(.WIDTH(AWIDTH), .LOGDEPTH(4)) fifo_write_addr (
        .clk(clk),
        .rst(rst),

        .enq_valid(fifo_enq_write_addr_valid),
        .enq_data(fifo_enq_write_addr),
        .enq_ready(fifo_enq_write_addr_ready),

        .deq_valid(req_write_addr_valid),
        .deq_data(req_write_addr),
        .deq_ready(req_write_addr_ready)
    );

    wire [DWIDTH-1:0] fifo_enq_write_data;
    wire fifo_enq_write_data_valid, fifo_enq_write_data_ready;
    fifo #(.WIDTH(DWIDTH), .LOGDEPTH(4)) fifo_write_data (
        .clk(clk),
        .rst(rst),

        .enq_valid(fifo_enq_write_data_valid),
        .enq_data(fifo_enq_write_data),
        .enq_ready(fifo_enq_write_data_ready),

        .deq_valid(req_write_data_valid),
        .deq_data(req_write_data),
        .deq_ready(req_write_data_ready)
    );

endmodule
