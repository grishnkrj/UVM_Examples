class drv extends uvm_driver#(seq_item);
  `uvm_component_utils(drv)
  virtual intf_4b vifd;
  seq_item item;

  
  function new(string name="drv",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!(uvm_config_db#(virtual intf_4b)::get(this,"*","VIF",vifd)))
      `uvm_fatal("Driver Class", "VIF failed to acquire")
  endfunction
      
      function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
        item=seq_item::type_id::create("item");
      seq_item_port.get_next_item(item);
      drive(item);
      seq_item_port.item_done();
    end
  endtask

    
    task drive(seq_item item);
      vifd.rst_n<=item.rst_n;
      vifd.up_down<=item.up_down;
            @(posedge vifd.clk);      

    endtask

    endclass