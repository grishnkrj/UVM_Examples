/**
 * SPI Sequence Item Class
 * 
 * This class models SPI data transfers for the SPI Controller testbench.
 * It represents a single SPI transaction with configurable parameters.
 *
 * Features:
 * - Support for all SPI modes (0-3)
 * - Configurable data width
 * - LSB/MSB first support
 * - Multiple chip select support
 * - Pre/post-transfer delays
 */
class spi_seq_item extends uvm_sequence_item;
    // SPI transfer identification
    rand int unsigned transfer_id;
    
    // SPI mode configuration
    typedef enum bit[1:0] {
        SPI_MODE0 = 2'b00,  // CPOL=0, CPHA=0: Sample on rising edge, Shift on falling edge
        SPI_MODE1 = 2'b01,  // CPOL=0, CPHA=1: Sample on falling edge, Shift on rising edge
        SPI_MODE2 = 2'b10,  // CPOL=1, CPHA=0: Sample on falling edge, Shift on rising edge
        SPI_MODE3 = 2'b11   // CPOL=1, CPHA=1: Sample on rising edge, Shift on falling edge
    } spi_mode_t;
    
    rand spi_mode_t spi_mode;
    
    // Transfer data
    rand bit [31:0] tx_data;  // Data sent from master (MOSI)
    rand bit [31:0] rx_data;  // Data received by master (MISO)
    
    // Transfer characteristics
    rand bit [15:0] cs_select;   // One-hot encoded chip select (bit position)
    rand bit        lsb_first;   // 1 = LSB first, 0 = MSB first
    rand int        data_width;  // Actual data width in bits (1-32)
    
    // Transfer timing
    rand int        delay;       // Clock cycles to delay before transfer
    rand bit        hold_cs;     // Hold CS active between transfers
    
    // Constraints
    constraint c_valid_cs {
        $onehot(cs_select);      // Only one CS active at a time
    }
    
    constraint c_valid_width {
        data_width inside {[1:32]}; // 1 to 32 bits per transfer
    }
    
    constraint c_reasonable_delay {
        delay inside {[0:20]};   // Reasonable delay range
    }
    
    // Factory registration
    `uvm_object_utils_begin(spi_seq_item)
        `uvm_field_int(transfer_id, UVM_DEFAULT)
        `uvm_field_enum(spi_mode_t, spi_mode, UVM_DEFAULT)
        `uvm_field_int(tx_data, UVM_DEFAULT | UVM_HEX)
        `uvm_field_int(rx_data, UVM_DEFAULT | UVM_HEX)
        `uvm_field_int(cs_select, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(lsb_first, UVM_DEFAULT)
        `uvm_field_int(data_width, UVM_DEFAULT)
        `uvm_field_int(delay, UVM_DEFAULT)
        `uvm_field_int(hold_cs, UVM_DEFAULT)
    `uvm_object_utils_end
    
    // Constructor
    function new(string name = "spi_seq_item");
        super.new(name);
    endfunction
    
    // Helper method to get a specific bit from tx_data based on bit position
    // Handles LSB/MSB first data ordering
    function bit get_mosi_bit(int bit_position);
        if (bit_position >= data_width) return 0;
        
        if (lsb_first) begin
            return tx_data[bit_position];
        end else begin
            return tx_data[data_width-1-bit_position];
        end
    endfunction
    
    // Helper method to get a specific bit from rx_data based on bit position
    // Handles LSB/MSB first data ordering
    function bit get_miso_bit(int bit_position);
        if (bit_position >= data_width) return 0;
        
        if (lsb_first) begin
            return rx_data[bit_position];
        end else begin
            return rx_data[data_width-1-bit_position];
        end
    endfunction
    
    // Helper method to set a specific bit in rx_data
    // Handles LSB/MSB first data ordering
    function void set_miso_bit(int bit_position, bit value);
        if (bit_position >= data_width) return;
        
        if (lsb_first) begin
            rx_data[bit_position] = value;
        end else begin
            rx_data[data_width-1-bit_position] = value;
        end
    endfunction
    
    // Helper function to extract the CPOL from the SPI mode
    function bit get_cpol();
        return (spi_mode inside {SPI_MODE2, SPI_MODE3});
    endfunction
    
    // Helper function to extract the CPHA from the SPI mode
    function bit get_cpha();
        return (spi_mode inside {SPI_MODE1, SPI_MODE3});
    endfunction
    
    // Utility function to get the active chip select index
    function int get_cs_index();
        for (int i=0; i<16; i++) begin
            if (cs_select[i]) return i;
        end
        return 0;  // Default to CS0 if none found
    endfunction
    
    // String representation for better debugging
    virtual function string convert2string();
        string s;
        s = super.convert2string();
        s = {s, $sformatf("\n  Transfer ID: %0d", transfer_id)};
        s = {s, $sformatf("\n  SPI Mode: %s (CPOL=%0d,CPHA=%0d)", 
                          spi_mode.name(), get_cpol(), get_cpha())};
        s = {s, $sformatf("\n  Data: TX=0x%h, RX=0x%h", tx_data, rx_data)};
        s = {s, $sformatf("\n  Width: %0d bits, %s first", 
                          data_width, lsb_first ? "LSB" : "MSB")};
        s = {s, $sformatf("\n  CS: %0d (0x%h), Hold CS: %0d", 
                          get_cs_index(), cs_select, hold_cs)};
        return s;
    endfunction
    
endclass : spi_seq_item