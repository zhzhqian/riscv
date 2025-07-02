module uart_receiver #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE  = 115_200
) (
    input clk,
    input rst,

    // Dequeue the received character to the Sink
    output [7:0] data_out,
    output  data_out_valid,
    input data_out_ready,

    // Serial bit input
    input serial_in
);
    // See diagram in the lab guide
    localparam SYMBOL_EDGE_TIME    = CLOCK_FREQ / BAUD_RATE;
    localparam SAMPLE_TIME         = SYMBOL_EDGE_TIME / 2;
    localparam CLOCK_COUNTER_WIDTH = $clog2(SYMBOL_EDGE_TIME);

    wire [9:0] rx_shift_val;
    reg [9:0] rx_shift_next;
    wire rx_shift_ce;

    // LSB to MSB
    REGISTER_CE #(.N(10)) rx_shift (
        .q(rx_shift_val),
        .d(rx_shift_next),
        .ce(rx_shift_ce),
        .clk(clk));
    assign data_out=rx_shift_next[8:1];
    wire [3:0] bit_counter_val;
    reg [3:0] bit_counter_next;
    wire bit_counter_ce;
    wire bit_counter_rst;

    // Keep track of how many bits have been sampled
    REGISTER_R_CE #(.N(4), .INIT(0)) bit_counter (
        .q(bit_counter_val),
        .d(bit_counter_next),
        .ce(bit_counter_ce),
        .rst(bit_counter_rst),
        .clk(clk)
    );
    assign bit_counter_rst=rst;

    wire [CLOCK_COUNTER_WIDTH-1:0] clock_counter_val;
    reg [CLOCK_COUNTER_WIDTH-1:0] clock_counter_next;
    wire clock_counter_ce;
    reg clock_counter_rst;

    // Keep track of sample time and symbol edge time
    REGISTER_R_CE #(.N(CLOCK_COUNTER_WIDTH), .INIT(0)) clock_counter (
        .q(clock_counter_val),
        .d(clock_counter_next),
        .ce(clock_counter_ce),
        .rst(clock_counter_rst),
        .clk(clk)
    );
    wire is_symbol_edge = (clock_counter_val == SYMBOL_EDGE_TIME - 1);
    wire is_sample_time = (clock_counter_val == SAMPLE_TIME - 1);

    // Note that UART protocol is asynchronous, the dequeue logic should be
    // inpedendent of the symbol/bit sample logic. You don't have to implement
    // a back-pressure handling (i.e., if data_out_ready is LOW for a long time)
    wire data_out_fire;
    assign  data_out_fire= data_out_valid & data_out_ready;
    
    wire state_next;
    wire state_val;
    reg state_rst;
    REGISTER_R_CE #(.N(1),.INIT(0)) negedge_state(.d(state_next),.q(state_val),.rst(state_rst),.clk(clk),.ce(1'b1));
    wire data_out_valid_val;
    reg  data_out_valid_next,data_out_valid_state_ce;
    REGISTER_R_CE #(.N(1),.INIT(0)) data_out_valid_state(.d(data_out_valid_next),.q(data_out_valid_val),.rst(data_out_fire|rst),.ce(data_out_valid_state_ce),.clk(clk));
    reg bit_ce,ser_ce;
    assign data_out_valid=data_out_valid_val;
    assign state_next=bit_ce|~serial_in;
    assign bit_counter_ce=1'b1;  
    assign rx_shift_ce=1'b1;
    assign clock_counter_ce=state_val;

    always @(*) begin
        clock_counter_rst= rst;
        clock_counter_next=clock_counter_val+1;
        bit_counter_next=bit_counter_val;
        rx_shift_next=rx_shift_val;
        data_out_valid_next=1'b0;
        bit_ce=1'b1;
        state_rst=1'b0;
        data_out_valid_state_ce=0;
        if(is_symbol_edge) begin
            clock_counter_next=0;
        end
        if(is_sample_time) begin
            rx_shift_next={serial_in,rx_shift_val[9:1]};
            if(bit_counter_val==4'd9) begin
                data_out_valid_next=1'b1;
                data_out_valid_state_ce=1;
                bit_counter_next=0;
                bit_ce=1'b0;
                state_rst=1'b1;
                clock_counter_rst=1'b1;
                
                state_rst=1'b1;
            end
            else begin
            bit_counter_next=bit_counter_val+1;
            end
        end
        if(bit_counter_val==4'd0)
            bit_ce=1'b0;

    end
    
endmodule
