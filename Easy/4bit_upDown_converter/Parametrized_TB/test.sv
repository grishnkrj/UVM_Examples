class param_base_test #(parameter int WIDTH=4) extends uvm_test;
    // Register with factory using parameterized class
    `uvm_component_param_utils(param_base_test#(WIDTH))
    
    // Environment instance
    param_env #(WIDTH) env;
    
    // Allow override of WIDTH from config_db
    int config_width;
    
    function new(string name = "param_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Check if WIDTH was set in config_db
        if (uvm_config_db#(int)::get(null, "*", "WIDTH", config_width)) begin
            `uvm_info(get_type_name(), $sformatf("Using width from config_db: %0d", config_width), UVM_LOW)
            
            // IMPORTANT: Make sure we're using the same WIDTH for the interface lookup
            // Create a properly typed environment with the config WIDTH
            if (config_width != WIDTH) begin
                `uvm_warning(get_type_name(), $sformatf("Config width (%0d) doesn't match class parameter width (%0d)", 
                                                      config_width, WIDTH))
            end
        end else begin
            config_width = WIDTH;
            `uvm_info(get_type_name(), $sformatf("Using default width: %0d", WIDTH), UVM_LOW)
        end
        
        // Create environment with the configured width
        env = param_env #(WIDTH)::type_id::create("env", this);
    endfunction
    
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        
        // Print topology
        uvm_top.print_topology();
    endfunction
    
    task run_phase(uvm_phase phase);
        // Empty in base test
    endtask
endclass

// Parameterized test with default WIDTH=4
class param_counter_test #(parameter int WIDTH=4) extends param_base_test #(WIDTH);
    `uvm_component_param_utils(param_counter_test#(WIDTH))
    
    function new(string name = "param_counter_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    task run_phase(uvm_phase phase);
        // Sequences
        param_rst_seq #(WIDTH) rst_seq;
        param_up_seq  #(WIDTH) up_seq;
        param_dw_seq  #(WIDTH) dw_seq;
        
        // Raise objection to prevent test from ending
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), $sformatf("Starting test with WIDTH = %0d", WIDTH), UVM_LOW)
        
        // Create and start reset sequence
        rst_seq = param_rst_seq #(WIDTH)::type_id::create("rst_seq");
        `uvm_info(get_type_name(), "Starting reset sequence", UVM_LOW)
        rst_seq.start(env.agent.sequencer);
        #10;
        
        // Create and start up-count sequence (17 iterations)
        up_seq = param_up_seq #(WIDTH)::type_id::create("up_seq");
        `uvm_info(get_type_name(), "Starting up-count sequence (17 iterations)", UVM_LOW)
        repeat(17) begin
            up_seq.start(env.agent.sequencer);
            #10;
        end
        
        // Create and start down-count sequence (10 iterations)
        dw_seq = param_dw_seq #(WIDTH)::type_id::create("dw_seq");
        `uvm_info(get_type_name(), "Starting down-count sequence (10 iterations)", UVM_LOW)
        repeat(10) begin
            dw_seq.start(env.agent.sequencer);
            #10;
        end
        
        // Additional up-count (5 iterations)
        `uvm_info(get_type_name(), "Starting additional up-count sequence (5 iterations)", UVM_LOW)
        repeat(5) begin
            up_seq.start(env.agent.sequencer);
            #10;
        end
        
        // Additional down-count (7 iterations)
        `uvm_info(get_type_name(), "Starting additional down-count sequence (7 iterations)", UVM_LOW)
        repeat(7) begin
            dw_seq.start(env.agent.sequencer);
            #10;
        end
        
        // Allow some time for scoreboard to process remaining transactions
        #50;
        
        // Drop objection to end the test
        phase.drop_objection(this);
    endtask
endclass

// Explicitly parameterized test classes for specific widths
class param_counter_test_4bit extends param_counter_test #(4);
    `uvm_component_utils(param_counter_test_4bit)
    
    function new(string name = "param_counter_test_4bit", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Override build_phase to properly handle interface lookups
    function void build_phase(uvm_phase phase);
        // Override WIDTH in config_db to match our parameter
        uvm_config_db#(int)::set(null, "*", "WIDTH", 4);
        super.build_phase(phase);
    endfunction
endclass

class param_counter_test_8bit extends param_counter_test #(8);
    `uvm_component_utils(param_counter_test_8bit)
    
    function new(string name = "param_counter_test_8bit", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Override build_phase to properly handle interface lookups
    function void build_phase(uvm_phase phase);
        // Override WIDTH in config_db to match our parameter
        uvm_config_db#(int)::set(null, "*", "WIDTH", 8);
        super.build_phase(phase);
    endfunction
endclass

class param_counter_test_16bit extends param_counter_test #(16);
    `uvm_component_utils(param_counter_test_16bit)
    
    function new(string name = "param_counter_test_16bit", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Override build_phase to properly handle interface lookups
    function void build_phase(uvm_phase phase);
        // Override WIDTH in config_db to match our parameter
        uvm_config_db#(int)::set(null, "*", "WIDTH", 16);
        super.build_phase(phase);
    endfunction
endclass