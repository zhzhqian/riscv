`include "util.v"
module Branch_Predict #(
    parameter AWIDTH =10 
)
(
    input clk,
    input rst,
    input [31:0] inst_cur,
    output taken,
    input [31:0] inst_last,
    input taken_last,
    input update_valid
);
    localparam COUNTER_BITS =2 ;
    wire[AWIDTH-1:0] rd_counter_indxA=inst_cur[AWIDTH-1:0];
    wire[AWIDTH-1:0] rd_counter_indxB=inst_last[AWIDTH-1:0];
    wire[AWIDTH-1:0] wt_counter_indx=rd_counter_indxB;
    wire [1:0] counter_val_A,counter_val_B;
    reg  [1:0] counter_next;
    wire [31:0] hit_times_next,hit_times_val;
    wire [31:0] branch_total_val,branch_total_next;
    wire [31:0] hit;
    REGISTER_R_CE #(.N(32),.INIT(0)) hit_time(.clk(clk),.rst(rst),.d(hit_times_next),.q(hit_times_val),.ce(update_valid));
    assign hit_times_next=hit_times_val+hit;
    assign hit=(counter_val_B[1]==taken_last)? 1:0;
    REGISTER_R_CE #(.N(32),.INIT(0)) all_branch(.clk(clk),.rst(rst),.d(branch_total_next),.q(branch_total_val),.ce(update_valid));
    assign branch_total_next=branch_total_val+update_valid;


    RAM_DP #(.AWIDTH(AWIDTH),.DWITH(COUNTER_BITS)) counters(.clk(clk),.rst(rst),.RA(rd_counter_indxA),.RB(rd_counter_indxB),
                                            .WA(wt_counter_indx),.WB(0),.WEA(update_valid),.WEB(0),.WAData(counter_next),.WBData(0),
                                            .dataA(counter_val_A),.dataB(counter_val_B));
    always@(*) begin
        counter_next=counter_val_B+taken_last;
        if(!taken_last&&counter_val_B!=0) begin
            counter_next=counter_val_B-1;
        end
        if(taken_last&&counter_val_B==2'b11)
            counter_next=counter_val_B;
    end
    assign taken=counter_val_A[1];
endmodule

module Branch_Predict_E #(
    parameter AWIDTH =10 
)
(
    input clk,
    input rst,
    input [31:0] inst_cur,
    output taken,
    input [31:0] inst_last,
    input taken_last,
    input update_valid
);
    localparam COUNTER_BITS =2 ;
    localparam GRDWITH =AWIDTH ;
    wire [AWIDTH-1:0] rd_gr_indx=inst_cur[AWIDTH-1:0];
    wire [AWIDTH-1:0] wt_gr_indx=inst_last[AWIDTH-1:0];
    wire [GRDWITH-1:0] rd_counter_indxA,rd_counter_indxB,wt_counter_indx;
    wire [GRDWITH-1:0] gr_next;
    wire [GRDWITH-1:0] gr_val_B,gr_val_A;
    wire [1:0] counter_val_A;
    wire [1:0] counter_val_B;
    reg  [1:0] counter_next;

    wire [31:0] hit_times_next,hit_times_val;
    wire [31:0] branch_total_val,branch_total_next;
    wire [31:0] hit;
    REGISTER_R_CE #(.N(32),.INIT(0)) hit_time(.clk(clk),.rst(rst),.d(hit_times_next),.q(hit_times_val),.ce(update_valid));
    assign hit_times_next=hit_times_val+hit;
    assign hit=(counter_val_B[1]==taken_last)? 1:0;
    REGISTER_R_CE #(.N(32),.INIT(0)) all_branch(.clk(clk),.rst(rst),.d(branch_total_next),.q(branch_total_val),.ce(update_valid));
    assign branch_total_next=branch_total_val+update_valid;

    RAM_DP #(.AWIDTH(AWIDTH),.DWITH(GRDWITH)) gr(.clk(clk),.rst(rst),.RA(rd_gr_indx),.RB(wt_gr_indx),
                                    .WA(wt_gr_indx),.WB(0),.WEA(update_valid),.WEB(0),.WAData(gr_next),.WBData(0),
                                    .dataA(gr_val_A),.dataB(gr_val_B));
    assign rd_counter_indxA=gr_val_A;
    assign rd_counter_indxB=gr_val_B;
    assign wt_counter_indx=gr_val_B;
    
    RAM_DP #(.AWIDTH(AWIDTH),.DWITH(COUNTER_BITS)) counter(.clk(clk),.rst(rst),.RA(rd_counter_indxA),.RB(rd_counter_indxB),
                                    .WA(wt_counter_indx),.WB(0),.WEA(update_valid),.WEB(0),.WAData(counter_next),.WBData(0),
                                    .dataA(counter_val_A),.dataB(counter_val_B));
                                    
    assign gr_next=(update_valid)? {gr_val_B[GRDWITH-1:1],taken_last}:gr_val_B;
    always@(*) begin
        counter_next=counter_val_B+taken_last;
        if(!taken_last&&counter_val_B!=0) begin
            counter_next=counter_val_B-1;
        end
        if(taken_last&&counter_val_B==2'b11)
            counter_next=counter_val_B;
    end
    assign taken=counter_val_A[1];
endmodule

module Branch_Predict_Global #(
    parameter AWIDTH =10 
)
(
    input clk,
    input rst,
    input [31:0] inst_cur,
    output taken,
    input [31:0] inst_last,
    input taken_last,
    input update_valid
);
    localparam COUNTER_BITS =2 ;
    localparam GRDWITH =AWIDTH ;
    wire [GRDWITH-1:0] rd_counter_indxA,rd_counter_indxB,wt_counter_indx;
    wire [GRDWITH-1:0] gr_next;
    wire [GRDWITH-1:0] gr_val;
    wire [1:0] counter_val_A;
    wire [1:0] counter_val_B;
    reg  [1:0] counter_next;
    wire [31:0] hit_times_next,hit_times_val;
    wire [31:0] branch_total_val,branch_total_next;
    wire [31:0] hit;

    REGISTER_R_CE #(.N(32),.INIT(0)) hit_time(.clk(clk),.rst(rst),.d(hit_times_next),.q(hit_times_val),.ce(update_valid));
    assign hit_times_next=hit_times_val+hit;
    assign hit=(counter_val_B[1]==taken_last)? 1:0;
    REGISTER_R_CE #(.N(32),.INIT(0)) all_branch(.clk(clk),.rst(rst),.d(branch_total_next),.q(branch_total_val),.ce(update_valid));
    assign branch_total_next=branch_total_val+update_valid;

    REGISTER_R #(.N(GRDWITH)) gr(.clk(clk),.rst(rst),.d(gr_next),.q(gr_val));
     
    RAM_DP #(.AWIDTH(AWIDTH),.DWITH(COUNTER_BITS)) counter(.clk(clk),.rst(rst),.RA(rd_counter_indxA),.RB(rd_counter_indxB),
                                    .WA(wt_counter_indx),.WB(0),.WEA(update_valid),.WEB(0),.WAData(counter_next),.WBData(0),
                                    .dataA(counter_val_A),.dataB(counter_val_B));
    assign rd_counter_indxA=gr_val^inst_cur[AWIDTH-1:0];

    assign rd_counter_indxB=gr_val^inst_last[AWIDTH-1:0];
    assign wt_counter_indx=gr_val^inst_last[AWIDTH-1:0];
    
    assign gr_next={gr_val[GRDWITH-1:1],taken_last};

    always@(*) begin
        counter_next=counter_val_B+taken_last;
        if(!taken_last&&counter_val_B!=0) begin
            counter_next=counter_val_B-1;
        end
        if(taken_last&&counter_val_B==2'b11)
            counter_next=counter_val_B;
    end
    assign taken=counter_val_A[1];
endmodule

module Branch_Predict_Combine #(
    parameter AWIDTH =10 
)
(
    input clk,
    input rst,
    input [31:0] inst_cur,
    output taken,
    input [31:0] inst_last,
    input taken_last,
    input update_valid
);
    localparam COUNTER_BITS =2 ;
    localparam GRDWITH =AWIDTH ;
    wire[AWIDTH-1:0] rd_gr_indx=inst_cur[AWIDTH-1:0];
    wire[AWIDTH-1:0] wt_gr_indx=inst_last[AWIDTH-1:0];
    wire [GRDWITH-1:0] rd_counter_indxA,rd_counter_indxB,wt_counter_indx;
    wire [GRDWITH-1:0] gr_next;
    wire [1:0] counter_val_A;
    wire [1:0] counter_val_B;
    reg  [1:0] counter_next;

    wire P1_taken,P2_taken;
    wire P1_update,P2_update;
    wire choose_P1;
    
    wire [31:0] hit_times_next,hit_times_val;
    wire [31:0] branch_total_val,branch_total_next;
    wire [31:0] hit;

    REGISTER_R_CE #(.N(32),.INIT(0)) hit_time(.clk(clk),.rst(rst),.d(hit_times_next),.q(hit_times_val),.ce(update_valid));
    assign hit_times_next=hit_times_val+hit;
    assign hit=(counter_val_B[1]==taken_last)? 1:0;
    REGISTER_R_CE #(.N(32),.INIT(0)) all_branch(.clk(clk),.rst(rst),.d(branch_total_next),.q(branch_total_val),.ce(update_valid));
    assign branch_total_next=branch_total_val+update_valid;
    REGISTER_R_CE #(.N(1)) save_choice(.clk(clk),.ce(update_valid),.rst(rst),.d(choose_P1),.q(last_choice));

    RAM_DP #(.AWIDTH(AWIDTH),.DWITH(COUNTER_BITS)) counter(.clk(clk),.rst(rst),.RA(rd_counter_indxA),.RB(rd_counter_indxB),
                                        .WA(wt_counter_indx),.WB(0),.WEA(update_valid),.WEB(0),.WAData(counter_next),.WBData(0),
                                        .dataA(counter_val_A),.dataB(counter_val_B));

    assign rd_counter_indxA=inst_cur[AWIDTH-1:0];
    assign rd_counter_indxB=inst_last[AWIDTH-1:0];

    assign wt_counter_indx=inst_last[AWIDTH-1:0];
    
    assign choose_P1=counter_val_A[1];
    assign taken=(choose_P1)? P1_taken:P2_taken;
    always@(*) begin
        counter_next=counter_val_B+taken_last;
        if(taken_last&&counter_val_B==2'b11)
            counter_next=counter_val_B;
    end

    Branch_Predict_E #(
        .AWIDTH (AWIDTH) 
    ) P1
    (
        .clk(clk),
        .rst(rst),
        .inst_cur(inst_cur),
        .taken(P1_taken),
        .inst_last(inst_last),
        .taken_last(taken_last),
        .update_valid(P1_update)
    );

    Branch_Predict_E #(
         .AWIDTH (AWIDTH)
    ) P2
    (
        .clk(clk),
        .rst(rst),
        .inst_cur(inst_cur),
        .taken(P2_taken),
        .inst_last(inst_last),
        .taken_last(taken_last),
        .update_valid(P2_update)
    );
    assign P1_update=(~last_choice) ? update_valid:0;  
    assign P2_update=(last_choice) ? update_valid:0;
endmodule