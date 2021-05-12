
module uart_transmitter #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200)
(
    input clk,
    input rst,

    // Enqueue the to-be-sent character
    input [7:0] data_in,
    input data_in_valid,
    output data_in_ready,

    // Serial bit output
    output reg serial_out
);
    // See diagram in the lab guide
    localparam SYMBOL_EDGE_TIME    = CLOCK_FREQ / BAUD_RATE;
    localparam CLOCK_COUNTER_WIDTH = $clog2(SYMBOL_EDGE_TIME);

    wire [9:0] tx_shift_val;
    reg [9:0] tx_shift_next;
    wire tx_shift_ce;

    // LSB to MSB
    REGISTER_CE #(.N(10)) tx_shift (
        .q(tx_shift_val),
        .d(tx_shift_next),
        .ce(tx_shift_ce),
        .clk(clk));

    wire [3:0] bit_counter_val;
    reg [3:0] bit_counter_next;
    wire bit_counter_ce, bit_counter_rst;

    // Count to 10
    REGISTER_R_CE #(.N(4), .INIT(0)) bit_counter (
        .q(bit_counter_val),
        .d(bit_counter_next),
        .ce(bit_counter_ce),
        .rst(bit_counter_rst),
        .clk(clk)
    );

    wire [CLOCK_COUNTER_WIDTH-1:0] clock_counter_val;
    reg [CLOCK_COUNTER_WIDTH-1:0] clock_counter_next;
    wire clock_counter_ce, clock_counter_rst;

    // Keep track of sample time and symbol edge time
    REGISTER_R_CE #(.N(CLOCK_COUNTER_WIDTH), .INIT(0)) clock_counter (
        .q(clock_counter_val),
        .d(clock_counter_next),
        .ce(clock_counter_ce),
        .rst(clock_counter_rst),
        .clk(clk)
    );

    wire is_symbol_edge = (clock_counter_val == SYMBOL_EDGE_TIME - 1);

    wire data_in_fire = data_in_valid & data_in_ready;
    
    reg state_next;
    wire state_val;
    
    //REGISTER #(.N(1)) work_state(.d(state_next),.q(state_val),.clk(clk));

    //dadada
    assign data_in_ready=~(|bit_counter_val)&&~(|clock_counter_val);
   
    assign clock_counter_rst=data_in_ready&&~data_in_valid||rst;

    assign tx_shift_ce=1'b1;

    assign bit_counter_ce=1'b1;

    assign clock_counter_ce=1'b1;
    
    assign bit_counter_rst=rst;
    
    //register data_in
    // wire data_ce;
    // wire [7:0] data_next,data_val;
    // REGISTER_R_ce #(.N(8),.INIT(0)) data_in_reg(.d(data_next),.q(data_val),.clk(clk),.rst(rst),.data_ce);
    // assign   data_ce=data_in_valid;
    // assign data_next=data_in;
    always @(*) begin
        clock_counter_next=clock_counter_val+1;
        serial_out=tx_shift_val[0];
        if(data_in_ready&&data_in_valid)
            tx_shift_next= {1'b1,data_in,1'b0};
        else begin
            if(is_symbol_edge)
                tx_shift_next={1'b1,tx_shift_val[9:1]};
            else
                tx_shift_next=tx_shift_val;
        end

        if(data_in_ready)
            serial_out=1'b1;
        
        if(bit_counter_val==9&&is_symbol_edge)
            bit_counter_next=0;
        else begin
            if(is_symbol_edge)
                bit_counter_next=bit_counter_val+1;
            else 
               bit_counter_next=bit_counter_val ;
        end

        if(is_symbol_edge)
            clock_counter_next=0;

    end

endmodule
