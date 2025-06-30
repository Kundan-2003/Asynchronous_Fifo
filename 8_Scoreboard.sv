class scoreboard #(parameter data_width =8);
  
  //queue to hold expected values written to fifo
  bit[data_width-1:0] expected_q[$];
  
  mailbox mon2scb; //mailbox to receive monitered transaction
  virtual fifo_if vif;
  
 //constructor
  function new(mailbox mon2scb, virtual fifo_if vif);
    this.mon2scb=mon2scb;
    this.vif=vif;
  endfunction

  
  //main run task
  task run();
    transaction tr;
    
    forever begin      
      mon2scb.get(tr);
      
      //write operation:save data to expected queue
      if(tr.wr_en && !tr.rd_en) begin
        expected_q.push_back(tr.data);
        $display("[scb] write:expectd_q<=%0d", tr.data);
      end
      
      //read operation:compare with expected
      else if(tr.rd_en && !tr.wr_en) begin
        if(expected_q.size()>0) begin
          bit[data_width-1:0] expected_val=expected_q.pop_front();
          if(tr.data!==expected_val) begin
            $display("[scb][fail] read mismatched! Expected: %0d, got %0d", expected_val,tr.data);
          end else begin
            $display("[scb][pass] Read matched:=%0d",tr.data);
          end
        end else begin
          $display("[scb][warn] underflow: read occured with no expected value");
        end
      end
      
      //simulataneous read+write:push and pop
//       else if(tr.rd_en && tr.wr_en) begin
//         if(expected_q.size()>0)begin
//           bit[data_width-1:0] expected_val=expected_q.pop_front();
//           if(tr.data!==expected_val) begin
//             $display("[scb][fail] simul rw mismatched! Expected: %0d, Got: %0d", expected_val, tr.data);
    
//           end else begin
//             $display("[SCB][PASS] Simul RW matched: %0d", tr.data);
//           end
//         end else begin
//           $display("[scb][warn] simul RW: underflow case");
//         end
//         expected_q.push_back(tr.data);
//       end
    end
  endtask
endclass
    
    
    
    
        
        
        
        
        
        
        
        
    
    
    
