
//PACK_ARRAY and UNPACK_ARRAY is for 2D<->1D translate 
`define PACK_ARRAY(PK_WIDTH,PK_LEN,PK_SRC,PK_DEST)  genvar pk_idx; generate for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1) begin:PACK_ARRAY___ assign PK_DEST[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = PK_SRC[pk_idx][((PK_WIDTH)-1):0]; end endgenerate
//PACK_ARRAY 2D->1D
//UNPACK_ARRAY 1D->2D
`define UNPACK_ARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC)  genvar unpk_idx; generate for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1) begin:UNPACK_ARRAY___ assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; end endgenerate


//Read BMP sequentially 
module readBMPStream(fileHandle,clk,rst,reload,bmp_header,ReadEnd,OutPixel,pixleInRow,RowCounter);

input [31:0] fileHandle;
input clk,rst,reload;
output reg ReadEnd;
output wire [23:0]OutPixel;
output reg [31:0] pixleInRow;
output reg[31:0] RowCounter;

parameter dataBufL=2000000;
reg [7:0]  bmp_data [0:dataBufL-1];

output  [8*60-1:0]  bmp_header;
`PACK_ARRAY(8,60,bmp_data,bmp_header)



integer bmp_width, bmp_hight, data_start_index, bmp_size, imageSize,TotalLength=0;



integer byteCounter=0;
reg pixClk=0;
reg [7:0]pixFeed_R;
reg [7:0]pixFeed_G;
reg [7:0]pixFeed_B;
assign OutPixel={pixFeed_R,pixFeed_G,pixFeed_B};
wire [23:0]pixFeed={pixFeed_R,pixFeed_G,pixFeed_B};

integer progress=0;
integer Newprogress=0;
always@(posedge clk)
begin
    if(rst==1)
    begin
        if(reload==1&&TotalLength==0)begin//Get image information
            TotalLength = $fread(bmp_data, fileHandle);
            bmp_width = {bmp_data[21],bmp_data[20],bmp_data[19],bmp_data[18]};
            bmp_hight = {bmp_data[25],bmp_data[24],bmp_data[23],bmp_data[22]};
            data_start_index = {bmp_data[13],bmp_data[12],bmp_data[11],bmp_data[10]};
            bmp_size  = {bmp_data[5],bmp_data[4],bmp_data[3],bmp_data[2]};
            imageSize=bmp_size-data_start_index;
            $display("%d\n",TotalLength);
        end
        //OutPixel=bmp_data[data_start_index];
        byteCounter=0;
        pixFeed_R=bmp_data[byteCounter+data_start_index];
        pixFeed_G=bmp_data[byteCounter+data_start_index+1];
        pixFeed_B=bmp_data[byteCounter+data_start_index+2];
        byteCounter=byteCounter+3;
        ReadEnd=0;
        RowCounter=0;
        pixleInRow=0;
		Newprogress=0;
		progress=0;
    end
    else if(ReadEnd==0)
    begin


        pixleInRow=pixleInRow+1;
        if(pixleInRow==bmp_width)
        begin
            byteCounter=byteCounter+(bmp_width[1:0]);
            pixleInRow=0;
            if(RowCounter>=bmp_hight-1)ReadEnd=1;
            RowCounter=RowCounter+1;
        end

        pixFeed_R=bmp_data[byteCounter+data_start_index];
        pixFeed_G=bmp_data[byteCounter+data_start_index+1];
        pixFeed_B=bmp_data[byteCounter+data_start_index+2];
        byteCounter=byteCounter+3;
			Newprogress=byteCounter*100/bmp_size;
			if(Newprogress!=progress)
			begin
				progress=Newprogress;
				
            $display("%d \n",progress);
			end

    end

end
endmodule

//In writeBMPStream we need refrence BMP header, usually comes from readBMPStream module 
    module writeBMPStream(fileHandle,clk,rst,reload,bmp_refheader,writeEnd,InPixel);

input [31:0] fileHandle;
input  [8*60-1:0]  bmp_refheader;
input clk,rst,reload;
output reg writeEnd;

input  [23:0]InPixel;
wire [7:0]bmp_header[0:60-1];
`UNPACK_ARRAY(8,60,bmp_header,bmp_refheader)

integer bmp_width, bmp_hight, data_start_index, bmp_size, imageSize;
integer i;
integer byteCounter=0;
integer pixleInRow=0,RowCounter=0;
integer seekRet;

reg  [31:0] LLL;
always@(posedge clk)
begin
    if(rst==1)
    begin
        bmp_width = {bmp_header[21],bmp_header[20],bmp_header[19],bmp_header[18]};
        bmp_hight = {bmp_header[25],bmp_header[24],bmp_header[23],bmp_header[22]};
        data_start_index = {bmp_header[13],bmp_header[12],bmp_header[11],bmp_header[10]};
        bmp_size  = {bmp_header[5],bmp_header[4],bmp_header[3],bmp_header[2]};
        seekRet=$fseek(fileHandle, 0, 0);
        for(i = 0; i < data_start_index; i = i + 4) begin//write header into the file
            LLL={bmp_header[i+3],bmp_header[i+2],bmp_header[i+1],bmp_header[i]};
            //$display("%h,",LLL);
            $fwrite(fileHandle,"%u",LLL);
        end

        byteCounter=0;
        pixleInRow=0;
        RowCounter=0;
        writeEnd=0;
    end
    else if(writeEnd==0)
    begin


        if(pixleInRow==bmp_width)
        begin

            //BMP formate every row's pixel number must be a multiple of 4
            $fwrite(fileHandle,"%u",{8'h0,8'h0,8'h0,8'h0});
            byteCounter=byteCounter+(bmp_width[1:0]);//decide how much 0 should be padded
            pixleInRow=0;

            if(RowCounter>=bmp_hight-1)
            begin
                $fwrite(fileHandle,"%u",{8'h0,8'h0,8'h0,8'h0});
                writeEnd=1;
            end
            RowCounter=RowCounter+1;
        end

        //Because the %u(unformatted) of $fwrite must write 4 byte in one operation, so I need to back to the right position
		   //before I write any data in the file.
        seekRet=$fseek(fileHandle, data_start_index+byteCounter, 0);
        $fwrite(fileHandle,"%u",{InPixel[0*8+:8],InPixel[1*8+:8],InPixel[2*8+:8]});
        byteCounter=byteCounter+3;

        pixleInRow=pixleInRow+1;
    end
end



endmodule
