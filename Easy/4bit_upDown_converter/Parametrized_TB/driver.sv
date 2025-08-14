class param_driver #(parameter int WIDTH=4) extends uvm_driver #(param_seq_item #(WIDTH));
    `uvm_component_param_utils(param_driver #(WIDTH))
    
    virtual param_counter_if #(WIDTH) vif;
    
    function new(string name = "param_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual param_counter_if #(WIDTH))::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface not set!")
        end
    endfunction
    
    task run_phase(uvm_phase phase);
        vif.rst_n = 1'b1;
        vif.up_down = 1'b0;
        
        forever begin
            param_seq_item #(WIDTH) seq_item;
            seq_item_port.get_next_item(seq_item);
            
            // Drive signals to interface
            @(posedge vif.clk);
            vif.rst_n = seq_item.rst_n;
            vif.up_down = seq_item.up_down;
            
            seq_item_port.item_done();
        end
    endtask
endclass