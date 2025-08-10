/**
 * APB Agent Class
 * 
 * This agent encapsulates all APB-related components for the SPI Controller testbench.
 * It integrates the sequencer, driver, and monitor into a coherent unit.
 *
 * Features:
 * - Configuration-based active/passive mode
 * - Common handle to virtual interface
 * - Analysis port forwarding from monitor
 */
class apb_agent extends uvm_agent;
    // Configuration object
    protected apb_config cfg;
    
    // Sub-components
    apb_sequencer    sequencer;
    apb_driver       driver;
    apb_monitor      monitor;
    
    // Analysis port
    uvm_analysis_port #(apb_seq_item) ap;
    
    // Factory registration
    `uvm_component_utils_begin(apb_agent)
        `uvm_field_object(cfg, UVM_REFERENCE)
    `uvm_component_utils_end
    
    // Constructor
    function new(string name = "apb_agent", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
    
    // Build phase - construct sub-components
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get config object
        if (!uvm_config_db#(apb_config)::get(this, "", "cfg", cfg)) begin
            // Create default config if not provided
            cfg = apb_config::type_id::create("cfg");
            `uvm_warning("APB_AGENT", "Failed to get config object, using default configuration")
        end
        
        // Always create monitor
        monitor = apb_monitor::type_id::create("monitor", this);
        
        // Create driver and sequencer only in active mode
        if (cfg.is_active == UVM_ACTIVE) begin
            driver = apb_driver::type_id::create("driver", this);
            sequencer = apb_sequencer::type_id::create("sequencer", this);
        end
        
        // Push down configurations to sub-components
        uvm_config_db#(apb_config)::set(this, "monitor", "cfg", cfg);
        uvm_config_db#(bit)::set(this, "monitor", "coverage_enable", cfg.has_coverage);
        
        if (cfg.is_active == UVM_ACTIVE) begin
            uvm_config_db#(apb_config)::set(this, "driver", "cfg", cfg);
            uvm_config_db#(apb_config)::set(this, "sequencer", "cfg", cfg);
        end
    endfunction
    
    // Connect phase - connect sub-components
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect monitor to agent's analysis port
        monitor.item_collected_port.connect(this.ap);
        
        // Connect driver and sequencer in active mode
        if (cfg.is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
    
    // Report phase - report statistics
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        if (cfg.is_active == UVM_ACTIVE) begin
            `uvm_info(get_type_name(), $sformatf("Active APB agent statistics: %0d transactions processed", 
                                                 driver.get_transaction_count()), UVM_MEDIUM)
        end
    endfunction
    
endclass : apb_agent