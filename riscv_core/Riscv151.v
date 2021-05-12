`include "arith_op.vh"
`include "../EECS151.v"
`define BUBBLE_INST 32'h0
module Riscv151 #(
    parameter CPU_CLOCK_FREQ    = 50_000_000,
    parameter RESET_PC          = 32'h4000_0000,
    parameter BAUD_RATE         = 115200,
    parameter BIOS_MEM_HEX_FILE = "bios151v3.mif"
    
) (
    input  clk,
    input  rst,
    input  FPGA_SERIAL_RX,
    output FPGA_SERIAL_TX,
    output [31:0] csr
);
//PC
    wire [31:0] Pc_val;
    wire [31:0] Pc_next;
    //pc will be piplined three time
    wire [31:0] inst_addr_DC, inst_addr_EX,inst_addr_MEM;   
    wire inst_valid,inst_valid_MEM;  
    
    wire [31:0] Pc_add4=inst_addr+4;
    reg [31:0] inst_addr;
    always @(*) begin
        if(bp_fail)
            if(branch_taken)
                inst_addr=ALU_val;
            else 
                inst_addr=inst_addr_EX+4;
        else if(PcJump_EX)
                inst_addr=ALU_val;
        else if(bp_taken_en)
                inst_addr=branch_addr;
        else
                inst_addr=Pc_val;
    end

    //PcSel  control the next pc val
    wire PcSel;
    //?
    assign Pc_next=Pc_add4;

    REGISTER_R_CE #(.N(32),.INIT(RESET_PC)) pc(.d(Pc_add4),.q(Pc_val),.rst(rst),.clk(clk),.ce(~bubble_from_bypass));
    //pipe pc from if to DC 
    REGISTER_R_CE #(.N(32),.INIT(0)) PIPE_addr(.d(inst_addr),.q(inst_addr_DC),.rst(rst),.clk(clk),.ce(~bubble_from_bypass));

// Instruction Memory    
    localparam IMEM_AWIDTH = 14;
    localparam IMEM_DWIDTH = 32;
    localparam IMEM_DEPTH  = 16384;

    wire [3:0] imem_wea;
    reg [3:0] imem_web_from_cpu;
    wire [3:0] imem_web;
    wire [IMEM_AWIDTH-1:0] imem_addra, imem_addrb;
    wire [IMEM_DWIDTH-1:0] imem_douta, imem_doutb;
    wire [IMEM_DWIDTH-1:0] imem_dina, imem_dinb;
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Write-byte-enable: select which of the four bytes to write
    XILINX_SYNC_RAM_DP_WBE #(
        .AWIDTH(IMEM_AWIDTH),
        .DWIDTH(IMEM_DWIDTH),
        .DEPTH(IMEM_DEPTH)
    ) imem (
        .q0(imem_douta),    // output
        .d0(imem_dina),     // input
        .addr0(imem_addra), // input
        .wbe0(imem_wea),    // input
        .q1(imem_doutb),    // output
        .d1(imem_dinb),     // input
        .addr1(imem_addrb), // input
        .wbe1(imem_web),    // input
        .clk(clk), .rst(rst));
    assign imem_dina=0;
    assign imem_wea=4'b0;
    assign imem_addra=inst_addr[IMEM_AWIDTH+1:2];
    assign imem_web=imem_web_from_cpu;
    assign imem_dinb=dataB_shift;
    //because memory are word align but risc-v is byte aligned
    assign imem_addrb=RW_Mem_addr[IMEM_AWIDTH+1:2]; 

//Controler
    //control signals
    wire regWE,BrUnsig,BSel,ASel,load_unsign,MemWE,MemRE,PcJump,inst_branch;
    //control signal pipelined
    wire PcJump_EX,branch_EX,BSel_EX,ASel_EX,loadu_EX,MemWE_EX,MemRE_EX,regWE_EX;
    wire [1:0]CSR_EN,CSR_EN_EX;
    wire [`Br_OP_BIT-1:0] Br_OP,Br_OP_EX;
    wire [`ALU_FUNC_BIT-1:0] ALUFunc,ALUFunc_EX;
    //control signal choose witch data to write to rf
    wire [1:0] WBSel,WBSel_EX,WBSel_MEM,WBSel_WB;
    // immediate 
    wire [31:0] imm,imm_EX,imm_MEM;

    //signal for lb/wb lh/sh lw sw
    wire [3:0] bhw,bhw_EX,bhw_MEM;
    assign PcSel=(branch_taken)? 1:PcJump_EX;
    //do we insert bublle?
    assign inst_valid=~PcSel;
    //backup inst for handle data hazard
    wire [31:0] inst_back_up;
    wire bubble_from_bypass;
    REGISTER_R #(.N(32)) backup_inst(.d(inst),.q(inst_back_up),.clk(clk),.rst(rst));

    //instruction from imm or bios
    wire [31:0] inst,inst_in_control;
    //we we handle hazard we need duplicate one instruction
    assign inst= (bubble_inst_from_bypass)? inst_back_up: (inst_addr[30])?  bios_douta:imem_douta;
    // inst_in_control is the real signal get into controller if execute inst is j/branch and they indeed need jump,we insert bubble for programme correct
    assign inst_in_control=(PcJump_EX||bp_fail)? `BUBBLE_INST:inst;
    control  con(.inst(inst_in_control),.PcJump(PcJump),.Branch(inst_branch),.imm(imm),.regWE(regWE),
                .BSel(BSel),.ASel(ASel),.ALUFunc(ALUFunc),.MemWE(MemWE),.MemRE(MemRE),.WBSel(WBSel),.CSR_EN(CSR_EN),.load_unsign(load_unsign),.bhw(bhw),.Br_OP(Br_OP));

    //back up the result of branch predict. so that we can know if branch predictor has go to wrong direction
    wire bp_taken_DC,bp_taken_EX;
    REGISTER_R #(.N(1)) backup_bp_taken(.d(bp_taken),.q(bp_taken_DC),.clk(clk),.rst(rst));
// branch predictor
    wire bp_taken;
    Branch_Predict_Global #(.AWIDTH(2)) branch_p(.clk(clk),.rst(rst),.inst_cur(inst_addr),
                                        .inst_last(inst_addr_EX),.taken_last(branch_taken),.update_valid(branch_EX),
                                            .taken(bp_taken));   
    // if the result of branch predictor is inconsistant with the result of branch comparator and this inst is actuallu a branch inst,
    // it means the bp has failed. so we has to  restore the pipeline.
    wire bp_fail=(bp_taken_EX!=branch_taken)&&branch_EX;
    // we need a adder to caculate the address of branch
    wire [31:0] branch_addr=inst_addr_DC+imm;
    // indicate we need branch because of branch predictor
    wire bp_taken_en=bp_taken_DC&&inst_branch;

    //Register file
    wire rf_we;
    wire [4:0]  rf_ra1, rf_ra2, rf_wa;
    wire [31:0] rf_wd;
    wire [31:0] rf_rd1, rf_rd2;
    // Asynchronous read: read data is available in the same cycle
    // Synchronous write: write takes one cycle
    REGFILE_1W2R # (
        .AWIDTH(5),
        .DWIDTH(32),
        .DEPTH(32)
    ) rf (
        .d0(rf_wd),     // input
        .addr0(rf_wa),  // input
        .we0(rf_we),    // input
        .q1(rf_rd1),    // output
        .addr1(rf_ra1), // input
        .q2(rf_rd2),    // output
        .addr2(rf_ra2), // input
        .clk(clk));

    //rs1,rs2,rd come from inst note RD need to piped twice(decode and execut),RS need pipline once for excute
    wire [4:0] RS1,RS1_EX,RS2,RS2_EX,RD,RD_MEM,RD_EX;

    assign RD=inst[11:7];
    assign RS1=inst[19:15];
    assign RS2=inst[24:20];

    assign rf_ra1=RS1;
    assign rf_ra2=RS2;
    assign rf_wa=RD_WB;
    assign rf_we=(rf_wa==5'b0)? 0:regWE_WB;
    assign rf_wd=WB_val;

//pipline from DC to EX stage include control signal PC,imm,RSRD,registerfile value
    REGISTER_R #(.N(26),.INIT(0)) PIPE_SIG_EX(
                .d({{PcJump},{inst_branch},{regWE},{BSel},{ASel},{ALUFunc},{MemWE},{MemRE},
                    {WBSel},{CSR_EN},{load_unsign},{bhw},{Br_OP},{inst_valid},{bp_taken_DC}}),
                .q({{PcJump_EX},{branch_EX},{regWE_EX},{BSel_EX},{ASel_EX},{ALUFunc_EX},{MemWE_EX},{MemRE_EX},{WBSel_EX},{CSR_EN_EX},
                    {loadu_EX},{bhw_EX},{Br_OP_EX},{inst_valid_MEM},{bp_taken_EX}}),
                .rst(rst|bubble_from_bypass),.clk(clk));
    
    REGISTER_R #(.N(32),.INIT(0)) PIPE_IMM_1(.d(imm),.q(imm_EX),.rst(rst),.clk(clk));
    REGISTER_R #(.N(15),.INIT(0)) PIPE_RSRD(.d({{RS1},{RS2},{RD}}),.q({{RS1_EX},{RS2_EX},{RD_EX}}),.rst(rst),.clk(clk));
    wire [31:0] rs1_data,rs1_data_EX,rs2_data,rs2_data_EX;
    REGISTER_R #(.N(32),.INIT(0)) PIPE_rs1_data(.d(rs1_data),.q(rs1_data_EX),.rst(rst),.clk(clk));
    REGISTER_R #(.N(32),.INIT(0)) PIPE_rs2_data(.d(rs2_data),.q(rs2_data_EX),.rst(rst),.clk(clk));
    REGISTER_R_CE #(.N(32),.INIT(0)) PIPE_PC1(.d(inst_addr_DC),.q(inst_addr_EX),.rst(rst),.clk(clk),.ce(1'b1));

    REGISTER_R #(.N(32)) PIPE_PC2(.d(inst_addr_EX),.q(inst_addr_MEM),.rst(rst),.clk(clk));

//handle data hazard 
    //bypass ALU stage, notably we use ~MemRE_EX to avoid bypass load instruction 
    wire bypass_EX_EN=(RD_EX!=5'b0)&&regWE_EX&&(~MemRE_EX);
    //bypass MEM_stage 
    wire bypass_MEM_EN=(RD_MEM!=5'b0)&&regWE_MEM;
    //bypass WBack stage
    wire bypass_WB_EN=(RD_WB!=5'b0)&&regWE_WB;
    //indicate whether we need insert bubble when bypass load instruction
    assign bubble_from_bypass=(RD_EX!=5'b0)&&regWE_EX&&MemRE_EX&&(RS1==RD_EX||RS2==RD_EX);

    reg [31:0] bypass_data_EX,bypass_data_MEM;
    wire [31:0] bypass_data_WB;
    always @(*) begin
        case(WBSel_EX)
            2'b00: bypass_data_EX=inst_addr_DC;
            2'b01: bypass_data_EX=ALU_val; 
                //load instruct ,in ex stage do not bypass just wait one cycle
            2'b10: bypass_data_EX=0; 
            2'b11: bypass_data_EX=imm_EX; 
        endcase

        case(WBSel_MEM)
            2'b00: bypass_data_MEM=inst_addr_EX;
            2'b01: bypass_data_MEM=ALU_val_MEM; 
            2'b10: bypass_data_MEM=MemSel_out; 
            2'b11: bypass_data_MEM=imm_MEM; 
        endcase
    end

    assign bypass_data_WB=WB_val;
    assign rs1_data=(RS1==RD_EX&&bypass_EX_EN)? bypass_data_EX : (RS1==RD_MEM&&bypass_MEM_EN)? bypass_data_MEM:  (RS1==RD_WB&&bypass_WB_EN)? bypass_data_WB  :rf_rd1 ;
    assign rs2_data=(RS2==RD_EX&&bypass_EX_EN)? bypass_data_EX : (RS2==RD_MEM&&bypass_MEM_EN)? bypass_data_MEM:  (RS2==RD_WB&&bypass_WB_EN)? bypass_data_WB  :rf_rd2 ;

    wire insert_buble_next,bubble_inst_from_bypass;
// handle bubble, we need insert bublle when bypass loard ,branch,jal 
    // after jump we need insert one more bubble
    REGISTER_R #(.N(1),.INIT(0)) insert_bubble_state(.d({{bubble_from_bypass}}),
            .q({{bubble_inst_from_bypass}}),.rst(rst),.clk(clk));
    
//branch comperator for deciding wether to branch 
    wire [31:0] dataA,dataB;
    assign dataA=rs1_data_EX;
    assign dataB=rs2_data_EX;
    wire b_comp_res,branch_taken;
    branch_comp brc(.Br_OP(Br_OP_EX),.dataA(dataA),.dataB(dataB),.comp_res(b_comp_res));
    assign branch_taken=b_comp_res&&branch_EX;

//CSR block 
    wire [31:0]csr_next,csr_val;
    wire csr_WE=CSR_EN_EX[0]||CSR_EN_EX[1];
    csr csr_M(.addr(imm_EX),.data(csr_next),.csr_WE(csr_WE),.rst(rst),.clk(clk),.state(csr_val));
    assign csr_next=CSR_EN_EX[0]? dataA:{27'b0,RS1_EX};
    assign csr=csr_val;


//ALU
    //alu inputs
    wire [31:0]ALU_in_A;
    wire [31:0]ALU_in_B;
    //alu output
    wire [31:0] ALU_val;
    //alu output piplined
    wire [31:0] ALU_val_MEM;
    assign ALU_in_A=(ASel_EX)? dataA:inst_addr_EX;
    assign ALU_in_B=(BSel_EX)? imm_EX:dataB;
    alu  alu(.dataA(ALU_in_A),.dataB(ALU_in_B),.ALUFunc(ALUFunc_EX),.resData(ALU_val));
    wire regWE_MEM,loadu_MEM;
    
    
//pipeline form EX to MEM stage including some control signal and alu output imm pc rd
    reg [3:0]write_mask;
    wire [3:0]write_mask_MEM;
    REGISTER_R #(.N(32),.INIT(`BUBBLE_INST)) PIPE_IMM_2(.d(imm_EX),.q(imm_MEM),.rst(rst),.clk(clk));
    REGISTER_R #(.N(17),.INIT(0)) PIPE_CON_SIG_2(.d({{regWE_EX},{WBSel_EX},{loadu_EX},{bhw_EX},{RD_EX},{write_mask}}),
                .q({{regWE_MEM},{WBSel_MEM},{loadu_MEM},{bhw_MEM},{RD_MEM},{write_mask_MEM}}),
                .rst(rst),.clk(clk));

    REGISTER_R #(.N(32),.INIT(0)) PIPE_ALU_VAL(.d(ALU_val),.q(ALU_val_MEM),.rst(rst),.clk(clk));

    //address to load or strore data from data/imem/bios memory,we do not use ALU out value for saving delay
    wire [31:0] RW_Mem_addr=ALU_in_A+ALU_in_B;
   
 // BIOS Memory
    localparam BIOS_AWIDTH = 12;
    localparam BIOS_DWIDTH = 32;
    localparam BIOS_DEPTH  = 4096;
    wire [BIOS_AWIDTH-1:0] bios_addra, bios_addrb;
    wire [BIOS_DWIDTH-1:0] bios_douta, bios_doutb;
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    XILINX_SYNC_RAM_DP #(
        .AWIDTH(BIOS_AWIDTH),
        .DWIDTH(BIOS_DWIDTH),
        .DEPTH(BIOS_DEPTH),
        .MEM_INIT_HEX_FILE(BIOS_MEM_HEX_FILE)
    ) bios_mem(
        .q0(bios_douta),    // output
        .d0(),              // intput
        .addr0(bios_addra), // input
        .we0(1'b0),         // input
        .q1(bios_doutb),    // output
        .d1(),              // input
        .addr1(bios_addrb), // input
        .we1(1'b0),         // input
        .clk(clk), .rst(rst));
    assign bios_addra=inst_addr[BIOS_AWIDTH+1:2];
    assign bios_addrb=RW_Mem_addr[BIOS_AWIDTH+1:2];


// Data Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Write-byte-enable: select which of the four bytes to write
    localparam DMEM_AWIDTH = 14;
    localparam DMEM_DWIDTH = 32;
    localparam DMEM_DEPTH  = 16384;
    reg [3:0] dmem_wea_from_cpu;
    wire [3:0] dmem_wea;
    wire [3:0] dmem_web;
    wire [DMEM_AWIDTH-1:0] dmem_addra,dmem_addrb;
    wire [DMEM_DWIDTH-1:0] dmem_dina, dmem_douta,dmem_dinb,dmem_doutb;

    XILINX_SYNC_RAM_DP_WBE #(
        .AWIDTH(DMEM_AWIDTH),
        .DWIDTH(DMEM_DWIDTH),
        .DEPTH(DMEM_DEPTH)
    ) dmem (
        .q0(dmem_douta),    // output
        .d0(dmem_dina),     // input
        .addr0(dmem_addra), // input
        .wbe0(dmem_wea),    // input
        .q1(dmem_doutb),    // output
        .d1(dmem_dinb),     // input
        .addr1(dmem_addrb), // input
        .wbe1(dmem_web),    // input
        .clk(clk), .rst(rst));
    //if conv2D is working we leave dmem for conv
    assign dmem_addra=(conv_working)? dmem_addra_from_io:RW_Mem_addr[DMEM_AWIDTH+1:2];
    assign dmem_addrb=(conv_working)? dmem_addrb_from_io:RW_Mem_addr[DMEM_AWIDTH+1:2];
    assign dmem_dina=(conv_working)? dmem_dina_from_io:dataB_shift;
    assign dmem_dinb=dmem_dinb_from_io;
    assign dmem_wea=(conv_working)? dmem_wea_from_io:dmem_wea_from_cpu;
    assign dmem_web=dmem_web_from_io;

//IO_Mem uart conv2D 
    reg [3:0] io_we;
    wire [31:0]dmem_addra_from_io,dmem_addrb_from_io;
    wire [31:0]dmem_dina_from_io,dmem_dinb_from_io;
    wire [31:0]dmem_douta_to_io,dmem_doutb_to_io;
    wire [3:0]dmem_wea_from_io,dmem_web_from_io;
    wire conv_working;
    assign dmem_douta_to_io=dmem_douta;
    assign dmem_doutb_to_io=dmem_doutb;
    
    wire [31:0] IO_out;
    IO_MEM io_m(.io_addr(RW_Mem_addr),.io_we(io_we),.clk(clk),.rst(rst),.inst_valid(inst_valid_MEM),.d(dataB),.q(IO_out),
        .SERIAL_IN(FPGA_SERIAL_RX),.SERIAL_OUT(FPGA_SERIAL_TX),
        .from_dmem_douta(dmem_douta_to_io),.from_dmem_doutb(dmem_doutb_to_io),
        .to_dmem_dina(dmem_dina_from_io),.to_dmem_dinb(dmem_dinb_from_io),.to_dmem_addra(dmem_addra_from_io),.to_dmem_addrb(dmem_addrb_from_io),
        .to_dmem_wea(dmem_wea_from_io),.to_dmem_web(dmem_web_from_io),
        .conv_working(conv_working)
    );
//pipline MEM to WB  pc imm Memdata RD 
    wire [31:0] ALU_val_WB,MemSel_out_MEM,imm_WB;
    wire [4:0] RD_WB;
    wire regWE_WB,MemRE_WB;
    REGISTER_R #(.N(32)) PIPE_ALU_VAL1(.d(ALU_val_MEM),.q(ALU_val_WB),.rst(rst),.clk(clk));
    REGISTER_R #(.N(32)) PIPE_MemSel(.d(MemSel_out),.q(MemSel_out_MEM),.rst(rst),.clk(clk));
    REGISTER_R #(.N(32)) PIPE_IMM2(.d(imm_MEM),.q(imm_WB),.rst(rst),.clk(clk));
    REGISTER_R #(.N(9)) PIPE_RD3(.d({{regWE_MEM},{RD_MEM},{WBSel_MEM},{MemRE_EX}}),
                                    .q({{regWE_WB},{RD_WB},{WBSel_WB},{MemRE_WB}}),.rst(rst),.clk(clk));

//mask block :choose proper location in a word to write back
    wire [31:0] Mask_out,Mask_in,MemSel_out;
    //choose which memory as output
    assign Mask_in=(ALU_val_MEM[30])? bios_doutb:dmem_douta;
    assign MemSel_out=(ALU_val_MEM[31])? IO_out:Mask_out;
    //mask block choose witch byte as final output 
    mask_bhw mask(.bhw(bhw_MEM),.mask(write_mask_MEM),.load_unsign(loadu_MEM),.data_in(Mask_in),.data_out(Mask_out));



//write back mux choose witch data as write back value to rd
    reg [31:0] WB_val;
    always @(*) begin
        case (WBSel_WB)
            2'b00: WB_val=inst_addr_MEM;
            2'b01: WB_val=ALU_val_WB;
            2'b10: WB_val=MemSel_out_MEM;
            2'b11: WB_val=imm_WB;
        endcase
    end
//caculate dmem imem iom write enable and shift data to proper location in a word 
    //do we excute instruction in bios?
    wire bios_M=inst_addr_EX[30];
    //shift data to rigth position along with WEA for correct write
    reg [31:0]dataB_shift;
    //write byte enable signal
    //in order to shift data in word to right place
    always @(*) begin
        write_mask=bhw_EX<<RW_Mem_addr[1:0];
        dataB_shift=dataB<<{RW_Mem_addr[1:0],3'b0};
        if(RW_Mem_addr[1:0]==2'b11&&bhw_EX==4'b11)begin
                write_mask=4'b1100;
                dataB_shift={dataB[15:0],16'b0};
            end
        io_we=0;
        imem_web_from_cpu=0;
        dmem_wea_from_cpu=0;
        if(MemWE_EX)begin
            io_we=write_mask&{4{RW_Mem_addr[31]}};
            if(RW_Mem_addr[29]&&bios_M)
                imem_web_from_cpu=write_mask;
            else
                dmem_wea_from_cpu=write_mask; 
        end
    end 
endmodule