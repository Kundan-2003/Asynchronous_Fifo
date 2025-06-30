`timescale 1ns/1ps
`include "interface.sv"
`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "environment.sv"


module top;
  parameter data_width=8;
  parameter addr_width=4;
  
  logic wr_clk=0, rd_clk=0;
  
  //enviornment 
  environment #(data_width) env;
   
  
  //instantiate interface
  fifo_if #(data_width) intf(
    .wr_clk(wr_clk),
    .rd_clk(rd_clk)
  );
  
   //clock generation
  always #5 wr_clk=~wr_clk; //100 mhz
  always #7 rd_clk=~rd_clk;//71 mhz
  
  //connect to dut 
   async_fifo #(
    .data_width(data_width),
    .addr_width(addr_width)
  ) dut (
    .data_in(intf.data_in),
    .wr_en(intf.wr_en),
    .wr_clk(intf.wr_clk),
    .wr_rst(intf.wr_rst),
    .full(intf.full),
    .data_out(intf.data_out),
    .rd_en(intf.rd_en),
    .rd_clk(intf.rd_clk),
    .rd_rst(intf.rd_rst),
    .empty(intf.empty)
  );
  
  
  
initial begin
  $dumpfile("fifo.vcd");
  $dumpvars(0,top);
end
  

  
  //test1->reset test
  task automatic test_reset_check();
    env.gen.random_mode=0;
    intf.wr_rst=1;
    intf.rd_rst=1;
    intf.wr_en=0;
    intf.rd_en=0;
    intf.data_in=0;
    #20;
    intf.wr_rst=0;
    intf.rd_rst=0;
    #20;
    $display("[TB] Reset completed.");
  endtask  
  
  
  
  //test2:- one write & one read 
  task automatic test_single_write_read();
    transaction t;
    env.gen.random_mode=0;
    $display("[Test2] single write and read test");
    //single write
    t=new();
    t.wr_en=1;
    t.rd_en=0;
    t.data=42;
    env.gen.add_user_transaction(t);
   
    //single read
    t=new();
    t.wr_en=0;
    t.rd_en=1;
    env.gen.add_user_transaction(t);  
  endtask
  
  //test3:- multiple write and read test
  task automatic test_multiple_write_read();
    env.gen.random_mode=0;
    $display("[Test3] multiple write followed by read");
    
    //write
    for(int i=0; i<4; i++) begin
      transaction t=new();
      t.wr_en=1;
      t.rd_en=0;
      t.data=8'hA0+i;
      env.gen.add_user_transaction(t);
  end

     for(int i=0; i<4; i++) begin
      transaction t=new();
      t.wr_en=0;
      t.rd_en=1;
      env.gen.add_user_transaction(t);
     end
  endtask
             
  //test4: overflow condition
  task automatic test_overflow();
    env.gen.random_mode=0;
    $display("[Test4] fifo overflow test");
    
    for(int i=0; i<20; i++) begin
      transaction t=new();
      t.wr_en=1;
      t.rd_en=0;
      t.data=8'hA0+i;
      env.gen.add_user_transaction(t);
    end
  endtask
  
  //test5:- underflow condition
  task automatic test_underflow();
    transaction t;
    env.gen.random_mode=0;
    $display("[Test5] Fifo underflow test");
    
    //single write
    t=new();
    t.wr_en=1;
    t.rd_en=0;
    t.data=42;
    env.gen.add_user_transaction(t);
    
    //attempt to read from an empty fifo
    for(int i=0; i<5; i++) begin
      t=new();
      t.wr_en=0;
      t.rd_en=1;
      env.gen.add_user_transaction(t);
    end
  endtask
  
  //test6:- Randomize write and read 
  task automatic test_random_write_read();
    env.gen.random_mode=1;//enable random generation
    $display("[Test6] Random write-read test");
    
    //generate a number of random transaction
    for(int i=0; i<20; i++) begin
      transaction t=new();
      t.wr_en=$urandom_range(0,1); //randomly enable write
      t.rd_en=$urandom_range(0,1); //randomly enable read
      
      //only assign data if write is enable
      if(t.wr_en) begin
        t.data=$urandom_range(0,255);
      end else begin
        t.data=0;
      end
      env.gen.add_user_transaction(t);
    end
  endtask
    
  //test7: wrap-around test
  task automatic test_wraparound();
    env.gen.random_mode=0;
    $display("[Test7] fifo wrap-around test");
    
    //step1: fill the fifo completely
    for(int i=0; i<16; i++) begin
      transaction t=new();
      t.wr_en=1;
      t.rd_en=0;
      t.data=8'hD0+i;
    env.gen.add_user_transaction(t);
    end
    
    //step2: read half of it
    for(int i=0; i<8; i++) begin
      transaction t=new();
      t.wr_en=0;
      t.rd_en=1;
      env.gen.add_user_transaction(t);
    end
  
  //step3: write 8 more items
    for(int i=0; i<8; i++) begin
      transaction t=new();
      t.wr_en=1;
      t.rd_en=0;
      t.data = 8'hE0+i;
      env.gen.add_user_transaction(t);
    end
    
    //step4: Read all remaining items
    for(int i=0; i<16; i++) begin
      transaction t=new();
      t.wr_en=0;
      t.rd_en=1;
      env.gen.add_user_transaction(t);
    end
    endtask
  
    
//test8:-reset at middle   
 task automatic test_mid_reset_operation();
  transaction t;  
  //transaction dummy;
  env.gen.random_mode = 0;
  $display("[Test8] Fifo reset in middle");
  // Step 1: Write some values before reset
  for (int i = 0; i < 4; i++) begin
    t = new();
    t.wr_en = 1;
    t.rd_en = 0;
    t.data = 8'hA0 + i;
    env.gen.add_user_transaction(t);
  end
  // Dummy transactions to allow time for write to complete
//   for (int i = 0; i < 10; i++) begin
//     dummy = new();
//     dummy.wr_en = 0;
//     dummy.rd_en = 0;
//     env.gen.add_user_transaction(dummy);
//   end

  // Start environment run
  fork
    env.run();
  join_none

  // Delay before reset to allow previous writes to go through
  #300;
  $display("[TB] >>> Applying Reset in Middle <<< @ %0t", $time);
  intf.wr_rst = 1;
  intf.rd_rst = 1;
  intf.wr_en = 0;
  intf.rd_en = 0;
  #50;
  intf.wr_rst = 0;
  intf.rd_rst = 0;
  $display("[TB] >>> Reset completed <<< @ %0t", $time);
 endtask
  
  
  //test9:-simultaneous write and read
  task automatic test_simultaneous_write_read();
  $display("[Test9] Simultaneous write and read test");
  env.gen.random_mode = 0;

  // First, fill FIFO halfway so reads can be valid
  for (int i=0;i<8; i++) begin
    transaction t = new();
    t.wr_en=1;
    t.rd_en=0;
    t.data=8'hC0+i;
    env.gen.add_user_transaction(t);
  end

  // Now issue simultaneous write and read
  for (int i=0; i<8; i++) begin
    transaction t = new();
    t.wr_en=1;
    t.rd_en=1;
    t.data=8'hD0+i;
    env.gen.add_user_transaction(t);
  end

  // Finish with some reads to flush remaining
  for (int i=0; i<8; i++) begin
    transaction t = new();
    t.wr_en=0;
    t.rd_en=1;
    env.gen.add_user_transaction(t);
  end
endtask
  
  
  initial begin
    env=new(intf.Tb);
    test_reset_check();
    //test_single_write_read();
    //test_multiple_write_read();
    //test_overflow();
    //test_underflow();
    //test_random_write_read();
    test_wraparound();  
    //test_mid_reset_operation();
    //test_simultaneous_write_read();
   
    
    
    env.run();
    #1500;
    $finish;
  end    
endmodule
  









     
     
     
     
     
  
  
  
