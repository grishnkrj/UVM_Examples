/**
 * APB Sequences for SPI Controller
 *
 * This file contains sequences for APB transactions to configure and operate
 * the SPI controller.
 */

// Base sequence for all APB sequences
class apb_base_seq extends uvm_sequence #(apb_seq_item);
    // Factory registration
    `uvm_object_utils(apb_base_seq)
    
    // Constructor
    function new(string name = "apb_base_seq");
        super.new(name);
    endfunction
    
    // Write to a register
    task write_reg(input bit[11:0] addr, input bit[31:0] data);
        apb_seq_item req;
        
        req = apb_seq_item::type_id::create("req");
        start_item(req);
        req.is_write = 1;
        req.addr = addr;
        req.data = data;
        finish_item(req);
    endtask
    
    // Read from a register
    task read_reg(input bit[11:0] addr, output bit[31:0] data);
        apb_seq_item req, rsp;
        
        req = apb_seq_item::type_id::create("req");
        start_item(req);
        req.is_write = 0;
        req.addr = addr;
        finish_item(req);
        
        get_response(rsp);
        data = rsp.rdata;
    endtask
    
    // Wait for a specific number of cycles
    task wait_cycles(int cycles);
        apb_seq_item req;
        
        req = apb_seq_item::type_id::create("req");
        req.delay = cycles;
        start_item(req);
        finish_item(req);
    endtask
endclass

// Sequence to reset the SPI controller
class apb_spi_reset_seq extends apb_base_seq;
    // Factory registration
    `uvm_object_utils(apb_spi_reset_seq)
    
    // Constructor
    function new(string name = "apb_spi_reset_seq");
        super.new(name);
    endfunction
    
    // Body task
    virtual task body();
        bit[31:0] data;
        
        // Disable SPI controller
        write_reg(apb_seq_item::CTRL_REG, 32'h0);
        
        // Reset TX and RX FIFOs - write with reset bits set
        write_reg(apb_seq_item::CTRL_REG, 32'h30); // bits 4 and 5 are reset bits
        
        // Read status to verify FIFOs are empty
        read_reg(apb_seq_item::STATUS_REG, data);
        
        if ((data & 32'h14) != 32'h14) begin // Check if tx_empty and rx_empty bits are set
            `uvm_error("SPI_RESET", $sformatf("FIFO reset failed. Status: 0x%0h", data))
        end
    endtask
endclass

// Sequence to configure the SPI controller
class apb_spi_config_seq extends apb_base_seq;
    // Configuration parameters with default values
    bit spi_enable = 1;
    bit [1:0] spi_mode = 0; // Mode 0
    bit lsb_first = 0;      // MSB first
    bit [7:0] tx_watermark = 2;
    bit [7:0] rx_watermark = 2;
    bit [31:0] clk_div = 10;
    bit [3:0] cs_value = 4'b0001;  // CS0 active
    bit [4:0] data_width = 8;      // 8-bit transfers
    bit cs_hold = 0;               // Don't hold CS between transfers
    
    // Factory registration with field macros
    `uvm_object_utils_begin(apb_spi_config_seq)
        `uvm_field_int(spi_enable, UVM_DEFAULT)
        `uvm_field_int(spi_mode, UVM_DEFAULT)
        `uvm_field_int(lsb_first, UVM_DEFAULT)
        `uvm_field_int(tx_watermark, UVM_DEFAULT)
        `uvm_field_int(rx_watermark, UVM_DEFAULT)
        `uvm_field_int(clk_div, UVM_DEFAULT)
        `uvm_field_int(cs_value, UVM_DEFAULT)
        `uvm_field_int(data_width, UVM_DEFAULT)
        `uvm_field_int(cs_hold, UVM_DEFAULT)
    `uvm_object_utils_end
    
    // Constructor
    function new(string name = "apb_spi_config_seq");
        super.new(name);
    endfunction
    
    // Body task
    virtual task body();
        bit[31:0] ctrl_val;
        bit[31:0] data_fmt_val;
        
        // Build control register value
        ctrl_val = {
            8'h0,                   // reserved
            rx_watermark,           // RX FIFO watermark
            tx_watermark,           // TX FIFO watermark
            3'h0,                   // reserved
            lsb_first,              // LSB/MSB first
            2'b00,                  // FIFO reset bits (not set)
            spi_mode,               // SPI mode (0-3)
            1'b1,                   // Master mode (always 1)
            spi_enable              // SPI enable bit
        };
        
        // Build data format register value
        data_fmt_val = {
            24'h0,                  // reserved
            1'b0,                   // reserved
            cs_hold,                // CS hold between transfers
            1'b0,                   // reserved
            data_width              // Data length (4-32 bits)
        };
        
        // Configure SPI controller
        write_reg(apb_seq_item::CTRL_REG, ctrl_val);
        write_reg(apb_seq_item::CLK_DIV_REG, clk_div);
        write_reg(apb_seq_item::CS_REG, cs_value);
        write_reg(apb_seq_item::DATA_FMT_REG, data_fmt_val);
        
        `uvm_info(get_type_name(), $sformatf("SPI configured: mode=%0d, data_width=%0d, clk_div=%0d", 
                                           spi_mode, data_width, clk_div), UVM_MEDIUM)
    endtask
endclass

// Sequence to transmit a single SPI data word
class apb_spi_single_transfer_seq extends apb_base_seq;
    // Transaction data
    rand bit[31:0] tx_data;
    bit[31:0] rx_data;
    
    // Factory registration
    `uvm_object_utils_begin(apb_spi_single_transfer_seq)
        `uvm_field_int(tx_data, UVM_DEFAULT)
        `uvm_field_int(rx_data, UVM_DEFAULT)
    `uvm_object_utils_end
    
    // Constructor
    function new(string name = "apb_spi_single_transfer_seq");
        super.new(name);
    endfunction
    
    // Body task
    virtual task body();
        bit[31:0] status;
        bit tx_empty, rx_empty;
        
        // Check if TX FIFO is full
        read_reg(apb_seq_item::STATUS_REG, status);
        if (status[1]) begin // tx_full bit
            `uvm_warning("SPI_TRANSFER", "TX FIFO is full, waiting...")
            // Wait for space in TX FIFO
            do begin
                wait_cycles(5);
                read_reg(apb_seq_item::STATUS_REG, status);
            end while (status[1]);
        end
        
        // Write data to TX FIFO
        write_reg(apb_seq_item::TX_DATA_REG, tx_data);
        
        `uvm_info(get_type_name(), $sformatf("Sent SPI data: 0x%0h", tx_data), UVM_HIGH)
        
        // Wait for transfer to complete and data to be available in RX FIFO
        // First wait for TX FIFO to empty (meaning data was sent)
        do begin
            wait_cycles(5);
            read_reg(apb_seq_item::STATUS_REG, status);
            tx_empty = status[2];
        end while (!tx_empty);
        
        // Then wait for RX FIFO to have data
        do begin
            wait_cycles(5);
            read_reg(apb_seq_item::STATUS_REG, status);
            rx_empty = status[4];
        end while (rx_empty);
        
        // Read received data
        read_reg(apb_seq_item::RX_DATA_REG, rx_data);
        
        `uvm_info(get_type_name(), $sformatf("Received SPI data: 0x%0h", rx_data), UVM_HIGH)
    endtask
endclass

// Sequence to transmit multiple SPI data words
class apb_spi_burst_transfer_seq extends apb_base_seq;
    // Transaction parameters
    rand int unsigned burst_length;
    rand bit[31:0] tx_data[];
    bit[31:0] rx_data[];
    
    // Constraints
    constraint c_burst_length { 
        burst_length inside {[1:10]}; 
        tx_data.size() == burst_length;
    }
    
    // Factory registration
    `uvm_object_utils_begin(apb_spi_burst_transfer_seq)
        `uvm_field_int(burst_length, UVM_DEFAULT)
        `uvm_field_array_int(tx_data, UVM_DEFAULT)
        `uvm_field_array_int(rx_data, UVM_DEFAULT)
    `uvm_object_utils_end
    
    // Constructor
    function new(string name = "apb_spi_burst_transfer_seq");
        super.new(name);
    endfunction
    
    // Customize post_randomize to allocate rx_data array
    function void post_randomize();
        rx_data = new[burst_length];
    endfunction
    
    // Body task
    virtual task body();
        apb_spi_single_transfer_seq single_seq;
        
        // Resize rx_data array if needed
        if (rx_data.size() != tx_data.size())
            rx_data = new[tx_data.size()];
        
        `uvm_info(get_type_name(), $sformatf("Starting burst transfer of %0d words", tx_data.size()), UVM_MEDIUM)
        
        // Send each data word
        for (int i = 0; i < tx_data.size(); i++) begin
            single_seq = apb_spi_single_transfer_seq::type_id::create("single_seq");
            single_seq.tx_data = tx_data[i];
            
            `uvm_info(get_type_name(), $sformatf("Sending word %0d: 0x%0h", i, tx_data[i]), UVM_HIGH)
            
            single_seq.start(m_sequencer);
            rx_data[i] = single_seq.rx_data;
            
            `uvm_info(get_type_name(), $sformatf("Received word %0d: 0x%0h", i, rx_data[i]), UVM_HIGH)
        end
        
        `uvm_info(get_type_name(), $sformatf("Completed burst transfer of %0d words", tx_data.size()), UVM_MEDIUM)
    endtask
endclass