/**
 * APB Agent Configuration Class
 * 
 * This class contains configuration parameters for the APB agent.
 *
 * Features:
 * - Active/passive mode setting
 * - Address and data width configuration
 * - Clock timing configuration
 * - Configurable timeout
 */
class apb_config extends uvm_object;
    // APB configuration parameters
    uvm_active_passive_enum is_active = UVM_ACTIVE;  // Agent mode (active/passive)
    bit                     has_checks = 1;           // Enable protocol checking
    bit                     has_coverage = 1;         // Enable coverage collection
    
    // APB interface parameters
    int unsigned            addr_width = 12;          // APB address width
    int unsigned            data_width = 32;          // APB data width
    
    // Timing parameters (in clock cycles)
    int unsigned            timeout = 1000;           // Transaction timeout
    
    // Factory registration
    `uvm_object_utils_begin(apb_config)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
        `uvm_field_int(has_checks, UVM_DEFAULT)
        `uvm_field_int(has_coverage, UVM_DEFAULT)
        `uvm_field_int(addr_width, UVM_DEFAULT)
        `uvm_field_int(data_width, UVM_DEFAULT)
        `uvm_field_int(timeout, UVM_DEFAULT)
    `uvm_object_utils_end
    
    // Constructor
    function new(string name = "apb_config");
        super.new(name);
    endfunction
    
    // Check if configuration is valid
    function bit is_valid();
        bit valid = 1;
        
        // Address width must be reasonable
        if (addr_width < 8 || addr_width > 64) begin
            `uvm_error("APB_CONFIG", $sformatf("Invalid address width: %0d", addr_width))
            valid = 0;
        end
        
        // Data width must be reasonable
        if (data_width != 8 && data_width != 16 && data_width != 32 && data_width != 64) begin
            `uvm_error("APB_CONFIG", $sformatf("Invalid data width: %0d", data_width))
            valid = 0;
        end
        
        return valid;
    endfunction
    
    // Convert to string for debug
    function string convert2string();
        return $sformatf("APB Config: %s mode, addr_width=%0d, data_width=%0d, %s",
            is_active == UVM_ACTIVE ? "ACTIVE" : "PASSIVE", 
            addr_width, data_width,
            has_checks ? "with protocol checks" : "without protocol checks");
    endfunction
    
endclass : apb_config