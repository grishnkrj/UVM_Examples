class param_agent #(parameter int WIDTH=4) extends uvm_agent;
    `uvm_component_param_utils(param_agent #(WIDTH))
    
    // Sub-components
    param_driver    #(WIDTH) driver;
    param_sequencer #(WIDTH) sequencer;
    param_monitor   #(WIDTH) monitor;
    
    // Configuration
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    
    function new(string name = "param_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create monitor regardless of agent mode
        monitor = param_monitor #(WIDTH)::type_id::create("monitor", this);
        
        // Only create driver and sequencer in active mode
        if(is_active == UVM_ACTIVE) begin
            driver = param_driver #(WIDTH)::type_id::create("driver", this);
            sequencer = param_sequencer #(WIDTH)::type_id::create("sequencer", this);
        end
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect driver and sequencer in active mode
        if(is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
endclass