`timescale 1ns/1ps
module Ser_Par_Converter_32(Data_out,wrt,data_in,En,clk,rst);
 output [31:0]Data_out;
 output wrt;
 input data_in;
 input En,clk,rst;

 parameter S_idle =0;
 parameter S_1=1;

 reg state,nxt_state;
 reg [4:0] cnt;
 reg Data_out;
 reg shift,incr;
 
always @(posedge clk or posedge rst) begin
    if(rst)
    begin
        state<=S_idle;
        cnt<=0;
    end
    else begin
        state<=nxt_state;
    end
 end
 always@ (state or En or wrt)begin
shift=0;
incr=0;
nxt_state=state;
case(state)
S_idle:if(En) 
        begin 
            nxt_state=S_1;
            shift=1;
        end
S_1:if(!wrt)
     begin
        shift=1;
        incr=1;
     end
    else if (En) begin
        shift=1;
        incr=1;
    end
    else
    begin
        nxt_state=S_idle;
        incr=1;
    end
endcase
end

always@(posedge clk or posedge rst)begin
if(rst)begin
    cnt<=0;
end
else if(incr)
 cnt<=cnt+1;
end
always@(posedge clk or posedge rst)
begin
    if(rst)
    Data_out<=0;
    else if (shift) begin
        Data_out<={data_in,Data_out[31:0]};
    end
end
assign write=(cnt==31);
endmodule
module write_synchronizer(write_synch,write,clk,reset);
output write_synch;
input write;
input clk,reset;
reg meta_synch,write_synch;
 always@(negedge clk)
 begin
    if(reset==1)
    begin
        meta_synch<=0;
        write_synch<=0;
    end
    else
    begin
      meta_synch<=write;
      write_synch<=write_synch?0:meta_synch;
    end
 end
endmodule

module FIFO_Buffer(data_out,full,almost_full,half_full,empty,almost_empty,data_in,wrt,read,clk,rst);
 parameter stack_width=32;
 parameter stack_height=8;
 parameter stack_ptr_width=3;
 parameter AE_level=2;
 parameter AF_level=6;
 parameter HF_level=4;
 input clk,rst;
 input wrt,read;
 input [stack_width-1:0]data_in;
 output full,almost_full,half_full,empty,almost_empty;
 output reg[stack_width-1:0]data_out;

 reg [stack_ptr_width-1:0]rd_ptr,wr_ptr;
 reg [stack_ptr_width:0]ptr_gap;
 reg [stack_width-1:0]Data_out;
 reg [stack_width-1:0] fifo_ram[stack_height-1:0];

 assign full=(ptr_gap==stack_height);
 assign almost_full=(ptr_gap==AF_level);
 assign half_full=(ptr_gap==HF_level);
 assign almost_full=(ptr_gap==AE_level);
 assign almost_empty=(ptr_gap==AE_level);
 assign empty=(ptr_gap==0);

 always@(posedge clk or posedge rst)
 begin
    if(rst)
    begin
        data_out<=0;
        rd_ptr<=0;
        wr_ptr<=0;
        ptr_gap<=0;
    end
    else if(wrt && (!full) && (!read))
    begin
        fifo_ram[wr_ptr]<=data_in;
        wr_ptr<=wr_ptr+1;
        ptr_gap<=ptr_gap+1;
    end
    else if(!wrt && !empty && read)
    begin: reaad
     data_out<=fifo_ram[rd_ptr];
     rd_ptr<=rd_ptr+1;
     ptr_gap<=ptr_gap+1;
    end
    else if(wrt && (empty) && read) 
    begin
        fifo_ram[wr_ptr]<=data_in;
    wr_ptr<=wr_ptr+1;
    ptr_gap<=ptr_gap+1;
    end
    else if (wrt && read && empty) begin
        data_out<=fifo_ram[rd_ptr];
        rd_ptr<=rd_ptr+1;
        ptr_gap<=ptr_gap+1;

    end
    else if (wrt && read && !full && !empty) begin
        data_out<=fifo_ram[rd_ptr];
        fifo_ram[wr_ptr]<=data_in;
        rd_ptr<=rd_ptr+1;
        wr_ptr<=wr_ptr+1;
    end
 end
 endmodule

 module t_FIFO_buffer();
    parameter stack_height=8;
    parameter stack_width=32;
    parameter stack_ptr_width=4;
    
    wire [stack_width-1:0] data_out;
    wire write;
    reg [stack_width-1:0] data_in;
    reg wrt,read;
    wire  full,almost_full,half_full,almost_empty,empty;
    reg wr_ptr,rd_ptr;
    reg clk,rst;
    wire [stack_height-1:0] stack0,satck1,stack2,stack3,stack4,stack5,stack6,stack7;
    
    assign stack0=M1.fifo_ram[0];
    assign stack1=M1.fifo_ram[1];
    assign stack2=M1.fifo_ram[2];
    assign stack3=M1.fifo_ram[3];
    assign stack4=M1.fifo_ram[4];
    assign stack5=M1.fifo_ram[5];
    assign stack6=M1.fifo_ram[6];
    assign stack7=M1.fifo_ram[7];
    
    FIFO_Buffer M1(data_out,full,almost_full,half_full,almost_empty,empty,data_in,wrt,read,clk,rst);

    initial #300 $finish;
    initial begin rst=1;#2 rst=0; end
    initial begin clk=0;forever #4 clk=~clk;end
    initial begin data_in=32'hFFFF_AAAA;
    @(posedge wrt);
    repeat(24)@(negedge clk)
     data_in=~data_in;
    end

    initial fork
        begin #8 wrt=0;end 
        begin #16 wrt=1;#140 wrt=0;end
        begin #224 wrt=1;end
    join

    initial fork
        begin #8 wrt=0;end
        begin #16 wrt=1;#140 wrt=0;end
        begin #224 wrt=1;end
    join

    initial fork
        begin #8 read=0;end
        begin #64 read=1;#40 read=0;end
        begin #144 read=1;#8 read=0;end
        begin #176 read=1;#8 read=0;end
    join
endmodule
module t_fifo_clock_domain_synch();
  parameter stack_width=32;
  parameter stack_height=8;
  parameter stack_ptr_width=3;
  defparam M1.stack_width=32;
  defparam M1.stack_height=8;
  defparam M1.stack_ptr_width=3;

  wire [stack_width-1:0] data_out,data_out2;
  wire full,almost_full,half_full;
  wire almost_empty,empty;
  wire write_synch;
  wire write;
  reg data_in;
  reg read;
  reg En;
  reg clk_write,clk_read,rst;
  wire [31:0] stack0,stack1,stack2,stack3,stack4,stack5,stack6,stack7;

  assign stack0=M1.fifo_ram[0];
  assign stack1=M1.fifo_ram[1]; 
  assign stack2=M1.fifo_ram[2];
  assign stack3=M1.fifo_ram[3];
  assign stack4=M1.fifo_ram[4];
  assign stack5=M1.fifo_ram[5];
  assign stack6=M1.fifo_ram[6];
  assign stack7=M1.fifo_ram[7];
    

reg [stack_width-1:0] Data1,Data2;

always@(negedge clk_read)
if(rst)
begin
    Data2<=0;
    Data1<=0;
end
else
begin
    Data1<=data_out2;
    Data2<=Data1;
end
Ser_Par_Converter_32 M0(data_out2,write,Data_in,En,clk_write,rst);
write_synchronizer Mw0(write_synch,write,clk_read,rst);
FIFO_Buffer M1 (Data_out,full,almost_full,half_full,almost_empty,empty,Data2,write_synch,read,clk_read,rst);

initial #10000 $finish;
initial fork rst=1;#8 rst=0;join
initial 
begin
    $dumpfile("t_fifo.vcd");
    $dumpvars(1,t_FIFO_buffer,t_fifo_clock_domain_synch);
    clk_write=0;
    forever #4 clk_write=~clk_write;end
    initial begin clk_read=0;forever #4 clk_read=~clk_read;end
    initial fork #1 En=0;#48 En=1;#2534 En=0;#3944 En=1;join
    initial fork
        #6 read=0;
        #2700 read=1;#2706 read=0; 
        #3980 read=1;#3986 read=0;
        #6000 read=1;#6006 read=0;
        #7776 read=1;#7782 read=0;
    join

    initial begin
        #1 data_in=0;
        @(posedge En) data_in=1;
        @(posedge write);
        repeat(6) begin
        repeat(16) @(negedge clk_write) data_in=0;
        repeat(16) @(negedge clk_write) data_in=1;
        repeat(16) @(negedge clk_write) data_in=1;
        repeat(16) @(negedge clk_write) data_in=0;
        end
    end
    endmodule  