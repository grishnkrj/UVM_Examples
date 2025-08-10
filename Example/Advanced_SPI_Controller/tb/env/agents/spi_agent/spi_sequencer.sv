/**
 * SPI Sequencer Class
 * 
 * This class manages and distributes SPI sequences to the driver.
 * It serves as a transaction request/response manager for the SPI agent.
 *
 * Features:
 * - Standard sequencer functionality for SPI transactions
 * - Parameterized for flexibility
 */
class spi_sequencer extends uvm_sequencer #(spi_seq_item);
    // Configuration object reference
    spi_config cfg;
    
    // Factory registration
    `uvm_component_utils_begin(spi_sequencer)
        `uvm_field_object(cfg, UVM_REFERENCE)
    `uvm_component_utils_end
    
    // Constructor
    function new(string name = "spi_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get the configuration object
        if (!uvm_config_db#(spi_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("SPI_SEQUENCER", "Failed to get config object")
    endfunction
    
    // Custom methods for advanced sequencer functionality can be added here
    
endclass : spi_sequencer