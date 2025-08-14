class param_env #(parameter int WIDTH=4) extends uvm_env;
    `uvm_component_param_utils(param_env #(WIDTH))
    
    // Sub-components
    param_agent      #(WIDTH) agent;
    param_scoreboard #(WIDTH) scoreboard;
    
    function new(string name = "param_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create agent and scoreboard
        agent = param_agent #(WIDTH)::type_id::create("agent", this);
        scoreboard = param_scoreboard #(WIDTH)::type_id::create("scoreboard", this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect monitor to scoreboard
        agent.monitor.mon_analysis_port.connect(scoreboard.item_collected_export);
    endfunction
endclass