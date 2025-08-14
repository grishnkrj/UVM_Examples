
class agnt extends uvm_agent;
  `uvm_component_utils(agnt)
  drv my_drv;
  mon my_mon;
  seqr my_seqr;
  
  function new(string name="agnt",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    my_drv=drv::type_id::create("my_drv",this);
    my_seqr=seqr::type_id::create("my_seqr",this);
    my_mon=mon::type_id::create("my_mon",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    my_drv.seq_item_port.connect(my_seqr.seq_item_export);
  endfunction
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask
  endclass