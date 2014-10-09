`include"BMPIO.v"



module test;
integer file1_R,file1_L,file2W;
reg rst,reload,pixClk,wsrst;
wire ReadEnd;
wire [8*60-1:0]  bmp_header;
wire [31:0] x,y;

wire [23:0] OutPixel_R;
wire [23:0] OutPixel_L;
reg [23:0] dd;

/*wire [7:0]gray=(
(OutPixel_L[8*2+:8]+OutPixel_L[8*1+:8]*2+OutPixel_L[8*0+:8])/4+
(OutPixel_R[8*2+:8]+OutPixel_R[8*1+:8]*2+OutPixel_R[8*0+:8])/4
)/2
;*/

wire [23:0]mixPixel=(y[0]==1)?
(OutPixel_L):(OutPixel_R);

wire [23:0] KK1;
readBMPStream rS_R(file1_R,pixClk,rst,reload,bmp_header,ReadEnd,OutPixel_R,x,y);
readBMPStream rS_L(file1_L,pixClk,rst,reload,bmp_header2,ReadEnd2,OutPixel_L,xL,yL);
writeBMPStream wS(.fileHandle(file2W),.clk(pixClk),.rst(wsrst),.reload(0),.bmp_refheader(bmp_header),.writeEnd(writeEnd),.InPixel(mixPixel));
initial begin
    $dumpfile("wave.vcd");$dumpvars;
    file1_L = $fopen("imL.bmp","rb");
    file1_R = $fopen("imR.bmp","rb");
    file2W = $fopen("Mix.bmp","wb");
    dd=0;
    pixClk=0;
    rst=1;
    reload=1;

    #50
     rst=0;
    reload=0;
end


always
begin
    #10 pixClk=~pixClk;

end
always@(posedge pixClk)begin
wsrst=rst;
/*if(OutPixel!=24'hFFFFFF)
	$display("%h\n",OutPixel);*/
	///gray=
//#1 dd={gray,gray,gray};
end
always@(writeEnd)if(writeEnd)
    begin
        $fclose(file1_R);
        $fclose(file1_L);
        $fclose(file2W);
        $finish;
    end

endmodule
