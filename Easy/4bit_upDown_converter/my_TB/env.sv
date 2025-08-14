
class env extends uvm_env;
  `uvm_component_utils(env)
  
  agnt my_agnt;
  scb  my_scb;
  
  function new(string name="env", uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    my_agnt=agnt::type_id::create("my_agnt",this);
    my_scb=scb::type_id::create("my_scb",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    my_agnt.my_mon.mon_port.connect(my_scb.scb_port);
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask
  
endclass