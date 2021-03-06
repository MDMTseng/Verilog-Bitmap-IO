`include"BMPIO.v"


//This example shows how to load 2 image(imL.bmp & imR.bmp) and process the image
//then output the result to an image (Mix.bmp)
module test;
integer file1_R,file1_L,file2W;
reg rst,reload,pixClk,wsrst;
wire ReadEnd;
wire [8*60-1:0]  bmp_header;
wire [31:0] x,y;

wire [23:0] OutPixel_R;
wire [23:0] OutPixel_L;


wire [23:0]mixPixel=(y[0]==1)?
     (OutPixel_L):(OutPixel_R);//mix the row data

wire [23:0] KK1;
readBMPStream rS_R(file1_R,pixClk,rst,reload,bmp_header,ReadEnd,OutPixel_R,x,y);
readBMPStream rS_L(file1_L,pixClk,rst,reload,bmp_header2,ReadEnd2,OutPixel_L,xL,yL);
writeBMPStream wS(.fileHandle(file2W),.clk(pixClk),.rst(wsrst),.reload(0),.bmp_refheader(bmp_header),.writeEnd(writeEnd),.InPixel(mixPixel));


always
begin
    #10 pixClk=~pixClk;
end
///////////////////////////Important don't change it, unless you know what are you doing.
initial begin
    $dumpfile("wave.vcd");$dumpvars;
    file1_L = $fopen("imL.bmp","rb");
    file1_R = $fopen("imR.bmp","rb");
    file2W = $fopen("Mix.bmp","wb");
    pixClk=0;
    rst=1;
    reload=1;
    #50
     rst=0;
    reload=0;
end
always@(posedge pixClk)wsrst=rst;
always@(writeEnd)if(writeEnd)
    begin
        $fclose(file1_R);
        $fclose(file1_L);
        $fclose(file2W);
        $finish;
    end

///////////////////////////Important end

endmodule
