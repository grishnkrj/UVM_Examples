/**
 * SPI Controller Environment Configuration
 * 
 * This class configures the SPI controller verification environment.
 * It contains configuration for agents, test parameters, and feature enables.
 */
class spi_controller_env_config extends uvm_object;
    // Agent configurations
    apb_config apb_cfg;
    spi_config spi_cfg;
    
    // DUT parameters (matching RTL parameters)
    int unsigned APB_ADDR_WIDTH = 12;
    int unsigned APB_DATA_WIDTH = 32;
    int unsigned SPI_DATA_MAX_WIDTH = 32;
    int unsigned FIFO_DEPTH = 16;
    int unsigned CS_WIDTH = 4;
    
    // Feature enables
    bit has_spi_checker = 1;    // Enable scoreboard and reference model
    bit has_coverage = 1;       // Enable functional coverage collection
    bit has_reg_model = 0;      // Enable register model (future enhancement)
    
    // Test knobs
    int unsigned timeout = 100000;  // Default timeout for watchdog
    
    // Factory registration
    `uvm_object_utils_begin(spi_controller_env_config)
        `uvm_field_object(apb_cfg, UVM_DEFAULT)
        `uvm_field_object(spi_cfg, UVM_DEFAULT)
        `uvm_field_int(APB_ADDR_WIDTH, UVM_DEFAULT)
        `uvm_field_int(APB_DATA_WIDTH, UVM_DEFAULT)
        `uvm_field_int(SPI_DATA_MAX_WIDTH, UVM_DEFAULT)
        `uvm_field_int(FIFO_DEPTH, UVM_DEFAULT)
        `uvm_field_int(CS_WIDTH, UVM_DEFAULT)
        `uvm_field_int(has_spi_checker, UVM_DEFAULT)
        `uvm_field_int(has_coverage, UVM_DEFAULT)
        `uvm_field_int(has_reg_model, UVM_DEFAULT)
        `uvm_field_int(timeout, UVM_DEFAULT)
    `uvm_object_utils_end
    
    // Constructor
    function new(string name = "spi_controller_env_config");
        super.new(name);
        
        // Create default agent configurations
        apb_cfg = apb_config::type_id::create("apb_cfg");
        spi_cfg = spi_config::type_id::create("spi_cfg");
        
        // Set default agent parameters
        apb_cfg.is_active = UVM_ACTIVE;
        apb_cfg.addr_width = APB_ADDR_WIDTH;
        apb_cfg.data_width = APB_DATA_WIDTH;
        
        spi_cfg.is_active = UVM_PASSIVE;  // Default passive - just monitor SPI signals
    endfunction
    
    // Validate configuration
    function bit is_valid();
        bit valid = 1;
        
        // Check if agent configurations are valid
        valid &= apb_cfg.is_valid();
        valid &= spi_cfg.is_valid();
        
        // Check DUT parameter validity
        if (APB_ADDR_WIDTH < 8 || APB_ADDR_WIDTH > 64) begin
            `uvm_error("ENV_CONFIG", $sformatf("Invalid APB address width: %0d", APB_ADDR_WIDTH))
            valid = 0;
        end
        
        if (APB_DATA_WIDTH != 32) begin
            `uvm_error("ENV_CONFIG", $sformatf("Unsupported APB data width: %0d, only 32 supported", APB_DATA_WIDTH))
            valid = 0;
        end
        
        if (SPI_DATA_MAX_WIDTH < 4 || SPI_DATA_MAX_WIDTH > 32) begin
            `uvm_error("ENV_CONFIG", $sformatf("Invalid SPI data width: %0d, range is 4-32", SPI_DATA_MAX_WIDTH))
            valid = 0;
        end
        
        if (FIFO_DEPTH < 1 || !$onehot(FIFO_DEPTH)) begin
            `uvm_error("ENV_CONFIG", $sformatf("Invalid FIFO depth: %0d, must be power of 2", FIFO_DEPTH))
            valid = 0;
        end
        
        if (CS_WIDTH < 1 || CS_WIDTH > 16) begin
            `uvm_error("ENV_CONFIG", $sformatf("Invalid CS width: %0d, range is 1-16", CS_WIDTH))
            valid = 0;
        end
        
        return valid;
    endfunction
    
endclass : spi_controller_env_config