//  Class: test

class my_test extends uvm_test;
    `uvm_component_utils(my_test)
  	env my_env;
  	rst_seq rst_pkt;
  	up_seq up_pkt;
  	dw_seq dw_pkt;
  
  
    
  function new(string name = "my_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new


function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  my_env=env::type_id::create("my_env",this);
endfunction: build_phase


function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

endfunction: connect_phase

  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    rst_pkt=rst_seq::type_id::create("rst_pkt");
    rst_pkt.start(my_env.my_agnt.my_seqr);
    
    repeat (17) 
      begin
        up_pkt=up_seq::type_id::create("up_pkt");
        up_pkt.start(my_env.my_agnt.my_seqr);       
      end
    
    
    repeat (10) 
      begin
        dw_pkt=dw_seq::type_id::create("dw_pkt");
        dw_pkt.start(my_env.my_agnt.my_seqr);       
      end
    
    repeat (5) 
      begin
        up_pkt=up_seq::type_id::create("up_pkt");
        up_pkt.start(my_env.my_agnt.my_seqr);       
      end
    
    
    repeat (7) 
      begin
        dw_pkt=dw_seq::type_id::create("dw_pkt");
        dw_pkt.start(my_env.my_agnt.my_seqr);       
      end
    
    
    
    phase.drop_objection(this);
  endtask
endclass
