/**
 * SPI Agent Class
 * 
 * This class combines the SPI driver, monitor, and sequencer into a unified agent.
 * It can operate in active mode (driving and monitoring) or passive mode (only monitoring).
 *
 * Features:
 * - Active/passive mode support
 * - Dynamic configuration
 * - Analysis port for observed transactions
 */
class spi_agent extends uvm_agent;
    // Agent components
    spi_driver    driver;
    spi_sequencer sequencer;
    spi_monitor   monitor;
    
    // Configuration object
    spi_config cfg;
    
    // Analysis port to forward transactions from monitor
    uvm_analysis_port #(spi_seq_item) item_observed_port;
    
    // Factory registration
    `uvm_component_utils_begin(spi_agent)
        `uvm_field_object(cfg, UVM_REFERENCE)
    `uvm_component_utils_end
    
    // Constructor
    function new(string name = "spi_agent", uvm_component parent = null);
        super.new(name, parent);
        
        // Create analysis port
        item_observed_port = new("item_observed_port", this);
    endfunction
    
    // Build phase - create components
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get configuration object
        if (!uvm_config_db#(spi_config)::get(this, "", "cfg", cfg)) begin
            // Create default config if not provided
            cfg = spi_config::type_id::create("cfg", this);
            `uvm_warning("SPI_AGENT", "No configuration object provided, using default")
        end
        
        // Always create monitor (both active and passive agents)
        monitor = spi_monitor::type_id::create("monitor", this);
        
        // Create driver and sequencer if active agent
        if (cfg.active == UVM_ACTIVE) begin
            driver    = spi_driver::type_id::create("driver", this);
            sequencer = spi_sequencer::type_id::create("sequencer", this);
        end
        
        // Set configuration for all components
        uvm_config_db#(spi_config)::set(this, "*", "cfg", cfg);
    endfunction
    
    // Connect phase - hook up components
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect monitor to analysis port
        monitor.item_collected_port.connect(item_observed_port);
        
        // Connect driver to sequencer if active
        if (cfg.active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
    
    // Get the transaction count from the driver
    virtual function int get_transaction_count();
        if (cfg.active == UVM_ACTIVE) begin
            return driver.get_transaction_count();
        end else begin
            return 0;
        end
    endfunction
    
endclass : spi_agent