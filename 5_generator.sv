class generator;

  //mode selection: 0= user-defined, 1=random
   bit random_mode;
  
  //user-defined transaction queue
  transaction user_queue[$];
  
  //mailbox to send transaction to driver
  mailbox gen2drv;
  
  //number of random transaction(for random mode)
  int num_transaction =10;
  
  //constructor
  function new(mailbox gen2drv);
    this.gen2drv=gen2drv;
    this.random_mode=1; //defalut to random mode
  endfunction
  
  //task to add user-defined transaction
  task add_user_transaction(transaction tr);
    user_queue.push_back(tr);
  endtask
  
  // main run method
  task run();
    transaction tr;
    
    if(random_mode) begin
      $display("[Gen] running random mode");
      repeat(num_transaction) begin
        tr=new();
        assert(tr.randomize() with{
          (wr_en || rd_en); // atleast one enable must be set
        });
        tr.display("GEN");
        gen2drv.put(tr);
      end
    end else begin
      $display("[GEN] Running in user-defined mode");
      foreach(user_queue[i]) begin
        user_queue[i].display("GEN");
        gen2drv.put(user_queue[i]);
      end
    end
  endtask
endclass
  
  







