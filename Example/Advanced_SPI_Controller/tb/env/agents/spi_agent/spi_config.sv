/**
 * SPI Agent Configuration Class
 * 
 * This class contains configuration parameters for the SPI agent.
 *
 * Features:
 * - Active/passive mode setting
 * - SPI mode and timing configuration
 * - Chip select width configuration
 * - Protocol checking and coverage control
 */
class spi_config extends uvm_object;
    // Agent configuration parameters
    uvm_active_passive_enum is_active = UVM_PASSIVE;  // Default to passive (monitor only)
    bit                     has_checks = 1;           // Enable protocol checking
    bit                     has_coverage = 1;         // Enable coverage collection
    
    // SPI interface parameters
    int unsigned            cs_width = 4;             // Number of chip select lines
    int unsigned            max_data_width = 32;      // Maximum data width
    
    // SPI protocol configuration
    typedef enum bit[1:0] {
        SPI_MODE0 = 2'b00,  // CPOL=0, CPHA=0: Sample on rising edge, Shift on falling edge
        SPI_MODE1 = 2'b01,  // CPOL=0, CPHA=1: Sample on falling edge, Shift on rising edge
        SPI_MODE2 = 2'b10,  // CPOL=1, CPHA=0: Sample on falling edge, Shift on rising edge
        SPI_MODE3 = 2'b11   // CPOL=1, CPHA=1: Sample on rising edge, Shift on falling edge
    } spi_mode_t;
    
    spi_mode_t              default_spi_mode = SPI_MODE0; // Default SPI mode
    bit                     default_lsb_first = 0;       // Default MSB first
    
    // Timing parameters (in clock cycles)
    int unsigned            timeout = 100000;           // Transaction timeout
    int unsigned            inter_transfer_gap = 5;     // Min clock cycles between transfers
    
    // Factory registration
    `uvm_object_utils_begin(spi_config)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
        `uvm_field_int(has_checks, UVM_DEFAULT)
        `uvm_field_int(has_coverage, UVM_DEFAULT)
        `uvm_field_int(cs_width, UVM_DEFAULT)
        `uvm_field_int(max_data_width, UVM_DEFAULT)
        `uvm_field_enum(spi_mode_t, default_spi_mode, UVM_DEFAULT)
        `uvm_field_int(default_lsb_first, UVM_DEFAULT)
        `uvm_field_int(timeout, UVM_DEFAULT)
        `uvm_field_int(inter_transfer_gap, UVM_DEFAULT)
    `uvm_object_utils_end
    
    // Constructor
    function new(string name = "spi_config");
        super.new(name);
    endfunction
    
    // Check if configuration is valid
    function bit is_valid();
        bit valid = 1;
        
        // CS width must be reasonable
        if (cs_width <= 0 || cs_width > 16) begin
            `uvm_error("SPI_CONFIG", $sformatf("Invalid CS width: %0d", cs_width))
            valid = 0;
        end
        
        // Data width must be reasonable
        if (max_data_width <= 0 || max_data_width > 64) begin
            `uvm_error("SPI_CONFIG", $sformatf("Invalid max data width: %0d", max_data_width))
            valid = 0;
        end
        
        // Inter-transfer gap must be reasonable
        if (inter_transfer_gap < 0) begin
            `uvm_error("SPI_CONFIG", $sformatf("Invalid inter-transfer gap: %0d", inter_transfer_gap))
            valid = 0;
        end
        
        return valid;
    endfunction
    
    // Convert to string for debug
    function string convert2string();
        string mode_str;
        
        case (default_spi_mode)
            SPI_MODE0: mode_str = "MODE0";
            SPI_MODE1: mode_str = "MODE1";
            SPI_MODE2: mode_str = "MODE2";
            SPI_MODE3: mode_str = "MODE3";
        endcase
        
        return $sformatf("SPI Config: %s mode, CS width=%0d, max data width=%0d, %s, default SPI mode=%s", 
            is_active == UVM_ACTIVE ? "ACTIVE" : "PASSIVE", 
            cs_width, max_data_width,
            has_checks ? "with protocol checks" : "without protocol checks",
            mode_str);
    endfunction
    
endclass : spi_config