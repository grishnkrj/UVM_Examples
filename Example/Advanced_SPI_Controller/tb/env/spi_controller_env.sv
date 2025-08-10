/**
 * SPI Controller Environment
 * 
 * This class integrates all verification components for the SPI controller testbench.
 * It contains APB and SPI agents, scoreboard, and reference model.
 */
class spi_controller_env extends uvm_env;
    // Agents
    apb_agent apb_agnt;
    spi_agent spi_agnt;
    
    // Reference model
    spi_controller_ref_model ref_model;
    
    // Scoreboard
    spi_controller_scoreboard scoreboard;
    
    // Environment configuration object
    spi_controller_env_config cfg;
    
    // Factory registration
    `uvm_component_utils(spi_controller_env)
    
    // Constructor
    function new(string name = "spi_controller_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build phase - create components
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get environment configuration
        if (!uvm_config_db#(spi_controller_env_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("ENV_CONFIG", "Failed to get env_config from config DB")
        end
        
        // Create APB agent
        apb_agnt = apb_agent::type_id::create("apb_agnt", this);
        
        // Configure APB agent
        uvm_config_db#(apb_config)::set(this, "apb_agnt", "cfg", cfg.apb_cfg);
        
        // Create SPI agent
        spi_agnt = spi_agent::type_id::create("spi_agnt", this);
        
        // Configure SPI agent
        uvm_config_db#(spi_config)::set(this, "spi_agnt", "cfg", cfg.spi_cfg);
        
        // Create reference model if checking is enabled
        if (cfg.has_spi_checker) begin
            ref_model = spi_controller_ref_model::type_id::create("ref_model", this);
            
            // Create scoreboard
            scoreboard = spi_controller_scoreboard::type_id::create("scoreboard", this);
        end
        
        // Enable coverage collection if configured
        if (cfg.has_coverage) begin
            uvm_config_db#(bit)::set(this, "apb_agnt.monitor", "coverage_enable", 1);
            uvm_config_db#(bit)::set(this, "spi_agnt.monitor", "coverage_enable", 1);
        end
    endfunction
    
    // Connect phase - connect components
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // If checking is enabled, connect components to scoreboard and reference model
        if (cfg.has_spi_checker) begin
            // Connect APB agent to reference model
            apb_agnt.ap.connect(ref_model.apb_analysis_export);
            
            // Connect reference model to scoreboard
            ref_model.spi_analysis_port.connect(scoreboard.spi_expected_export);
            
            // Connect APB agent to scoreboard
            apb_agnt.ap.connect(scoreboard.apb_actual_export);
            
            // Connect SPI agent to scoreboard
            spi_agnt.item_observed_port.connect(scoreboard.spi_actual_export);
            
            // Connect reference model to APB scoreboard
            // This part requires a special adapter that we need to implement
            // We'll create a special component to handle this later
            // For now, we'll leave this connection
        end
    endfunction
    
    // Report phase - summarize results
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info(get_type_name(), "Report phase", UVM_LOW)
        
        // Report agent statistics
        if (cfg.apb_cfg.is_active == UVM_ACTIVE) begin
            `uvm_info(get_type_name(), 
                     $sformatf("APB transactions: %0d", apb_agnt.get_transaction_count()), UVM_LOW)
        end
        
        if (cfg.spi_cfg.is_active == UVM_ACTIVE) begin
            `uvm_info(get_type_name(), 
                     $sformatf("SPI transactions: %0d", spi_agnt.get_transaction_count()), UVM_LOW)
        end
    endfunction
    
endclass : spi_controller_env