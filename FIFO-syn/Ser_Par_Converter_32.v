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

module testconv;

reg data_in,En,rst,clk;
wire [31:0]Data_out;
wire wrt;
Ser_Par_Converter_32 sp1(.Data_out(Data_out),.wrt(wrt),.data_in(data_in),.En(En),.clk(clk),.rst(rst));

initial begin
  $dumpfile("testconv.vcd");
  $dumpvars(0,testconv);
  $monitor($time,"data_out=%b wrt=%b data_in=%b en=%b rst=%b",Data_out,data_in,En,clk,rst);
  clk=1'b1;
  #10;rst=1;
  #10;rst=0;
  #10;data_in=1'b0;
  #20 $finish;
end
always #5 clk=~clk;
always #7.5 data_in=~data_in;

endmodule
