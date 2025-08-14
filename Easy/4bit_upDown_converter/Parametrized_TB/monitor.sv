class param_monitor #(parameter int WIDTH=4) extends uvm_monitor;
    `uvm_component_param_utils(param_monitor #(WIDTH))
    
    virtual param_counter_if #(WIDTH) vif;
    uvm_analysis_port #(param_seq_item #(WIDTH)) mon_analysis_port;
    
    function new(string name = "param_monitor", uvm_component parent = null);
        super.new(name, parent);
        mon_analysis_port = new("mon_analysis_port", this);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual param_counter_if #(WIDTH))::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "Virtual interface not set!")
        end
    endfunction
    
    task run_phase(uvm_phase phase);
        param_seq_item #(WIDTH) seq_item;
        
        forever begin
            @(posedge vif.clk);
            seq_item = param_seq_item #(WIDTH)::type_id::create("seq_item");
            seq_item.rst_n = vif.rst_n;
            seq_item.up_down = vif.up_down;
            seq_item.count = vif.count;
            
            mon_analysis_port.write(seq_item);
        end
    endtask
endclass