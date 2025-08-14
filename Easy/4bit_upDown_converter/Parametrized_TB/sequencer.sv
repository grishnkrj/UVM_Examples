class param_sequencer #(parameter int WIDTH=4) extends uvm_sequencer #(param_seq_item #(WIDTH));
    `uvm_component_param_utils(param_sequencer #(WIDTH))
    
    function new(string name = "param_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass