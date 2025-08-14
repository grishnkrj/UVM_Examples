class mon extends uvm_monitor; 
  `uvm_component_utils(mon)
  uvm_analysis_port#(seq_item) mon_port;
  virtual intf_4b vifm;
  seq_item item;
  
  function new(string name="mon",uvm_component parent);
    super.new(name,parent);
    mon_port=new("mon_port",this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

endfunction

function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(!(uvm_config_db#(virtual intf_4b)::get(this,"*","VIF", vifm)))
        `uvm_fatal(get_full_name(), "VIF Error")
endfunction
task run_phase(uvm_phase phase);
  super.run_phase(phase);
    forever begin
     @(vifm.cb);
    item = seq_item::type_id::create("item");
    item.rst_n = vifm.cb.rst_n;
    item.up_down = vifm.cb.up_down;
    item.count = vifm.cb.count;
    mon_port.write(item);
end
endtask
        
  
  
  endclass