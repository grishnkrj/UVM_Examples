/**
 * APB Sequencer Class
 * 
 * This class manages the flow of transactions to the APB driver.
 * It is a standard sequencer with no special functionality.
 */
class apb_sequencer extends uvm_sequencer #(apb_seq_item);
    // Configuration object
    protected apb_config cfg;
    
    // Factory registration
    `uvm_component_utils_begin(apb_sequencer)
        `uvm_field_object(cfg, UVM_REFERENCE)
    `uvm_component_utils_end
    
    // Constructor
    function new(string name = "apb_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build phase - get configuration
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get config object
        if (!uvm_config_db#(apb_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("APB_SEQUENCER", "Failed to get config object")
    endfunction
    
endclass : apb_sequencer