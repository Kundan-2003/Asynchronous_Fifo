//asynchronous fifo 
module async_fifo#(
  parameter data_width=8,
  parameter addr_width=4
)(
  //write domain 
  input wire [data_width-1:0] data_in,
  input wire wr_en,
  input wire wr_clk,
  input wire wr_rst,
  output wire full,
  
  //read domain
  output reg [data_width-1:0] data_out,
  input wire rd_en,
  input wire rd_clk,
  input wire rd_rst,
  output wire empty
);  
  localparam depth=1<<addr_width;//depth=2^addr_width
  //fifo memory 
  reg[data_width-1:0] mem [0:depth-1]; 
  
  // write pointer (binary and gray)
  reg[addr_width:0] wr_ptr_bin, wr_ptr_gray;
  
  //read pointer (binary &gray)
  reg[addr_width:0] rd_ptr_bin, rd_ptr_gray;
  
  //synchronized gray pointer
  reg [addr_width:0] rd_ptr_gray_sync_wr1,rd_ptr_gray_sync_wr2;
  reg[addr_width:0] wr_ptr_gray_sync_rd1, wr_ptr_gray_sync_rd2;
    
  
//write operation
  always@(posedge wr_clk or posedge wr_rst) begin
    if(wr_rst)begin
      wr_ptr_bin<=0;
      wr_ptr_gray<=0;
      rd_ptr_gray_sync_wr1<=0;
      rd_ptr_gray_sync_wr2<=0;
    end else begin
      if(wr_en && !full) begin
        mem[wr_ptr_bin[addr_width-1:0]]<=data_in;
        wr_ptr_bin<=wr_ptr_bin+1;
        wr_ptr_gray<=(wr_ptr_bin+1)^((wr_ptr_bin+1)>>1); //binary to gray conv.(we are doing +1 again bcz it is using non-blocking assignment which get updated in nba region only not immediatelty that's why we are doing +1 for gray code as prev +1 not get reflected in next line)
      end
      //synchronoze read pointer(gray) into write clock domain
      rd_ptr_gray_sync_wr1<=rd_ptr_gray;
      rd_ptr_gray_sync_wr2<=rd_ptr_gray_sync_wr1;
    end
  end
        
      
//read operation
  always@(posedge rd_clk or posedge rd_rst) begin
    if(rd_rst) begin
      rd_ptr_bin<=0;
      rd_ptr_gray<=0;
      wr_ptr_gray_sync_rd1<=0;
      wr_ptr_gray_sync_rd2<=0;
      //data_out<=0;
    end else begin 
      if(rd_en && !empty) begin 
        data_out<=mem[rd_ptr_bin[addr_width-1:0]];
        rd_ptr_bin<=rd_ptr_bin+1;
        rd_ptr_gray<=(rd_ptr_bin+1)^((rd_ptr_bin+1)>>1);//binary to gray
      end
        //synchronize write pointer(gray) into read clock domain
        wr_ptr_gray_sync_rd1<=wr_ptr_gray;
        wr_ptr_gray_sync_rd2<=wr_ptr_gray_sync_rd1;
      end
  end
  
// Gray to binary conversion
function automatic [addr_width:0] gray_to_bin(input [addr_width:0] gray);
  integer i;
  begin
    gray_to_bin[addr_width] = gray[addr_width];
    for (i = addr_width-1; i >= 0; i = i - 1)
      gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
  end
endfunction
  
  //convert gray pointers to binary
wire[addr_width:0]wr_ptr_gray_to_bin=gray_to_bin(wr_ptr_gray);  wire[addr_width:0]rd_ptr_gray_sync_wr2_to_bin=gray_to_bin(rd_ptr_gray_sync_wr2);
wire[addr_width:0]rd_ptr_gray_to_bin=gray_to_bin(rd_ptr_gray);
wire[addr_width:0]wr_ptr_gray_sync_rd2_to_bin=gray_to_bin(wr_ptr_gray_sync_rd2);
  
  // Full: When next write ptr = read ptr with MSB inverted
  assign full = (wr_ptr_gray_to_bin[addr_width] != rd_ptr_gray_sync_wr2_to_bin[addr_width]) &&
    (wr_ptr_gray_to_bin[addr_width-1:0] == rd_ptr_gray_sync_wr2_to_bin[addr_width-1:0]);

  // Empty: When rd_ptr == wr_ptr (synchronized)
  assign empty = (rd_ptr_gray_to_bin == wr_ptr_gray_sync_rd2_to_bin);

endmodule
  
