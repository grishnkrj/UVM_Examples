/**
 * SPI Controller Virtual Sequences
 *
 * Virtual sequences coordinate activity across multiple interfaces in the SPI
 * controller testbench, orchestrating complex test scenarios.
 */

// Base virtual sequence for all SPI controller test sequences
class spi_controller_vseq_base extends uvm_sequence;
    // Handle to the environment
    spi_controller_env m_env;
    
    // Sequencer handles for each interface
    virtual apb_sequencer apb_seqr;
    
    // Factory registration
    `uvm_object_utils(spi_controller_vseq_base)
    
    // Constructor
    function new(string name = "spi_controller_vseq_base");
        super.new(name);
    endfunction
    
    // Pre-body - get environment and sequencers
    virtual task pre_body();
        // Get environment from config_db
        if (uvm_config_db#(spi_controller_env)::get(null, "uvm_test_top", "env", m_env)) begin
            // Get the sequencers
            apb_seqr = m_env.apb_agnt.sequencer;
        end
        else begin
            `uvm_fatal("VSEQ_NO_ENV", "Virtual sequencer could not get environment handle")
        end
    endtask
    
    // Reset the DUT
    virtual task reset_dut();
        apb_spi_reset_seq reset_seq;
        
        reset_seq = apb_spi_reset_seq::type_id::create("reset_seq");
        reset_seq.start(apb_seqr);
    endtask
    
    // Configure the SPI controller with default settings
    virtual task default_config();
        apb_spi_config_seq config_seq;
        
        config_seq = apb_spi_config_seq::type_id::create("config_seq");
        // Use default settings from the config sequence
        config_seq.start(apb_seqr);
    endtask
    
    // Configure the SPI controller with custom settings
    virtual task custom_config(
        input bit spi_enable,
        input bit [1:0] spi_mode,
        input bit lsb_first,
        input bit [7:0] tx_watermark,
        input bit [7:0] rx_watermark,
        input bit [31:0] clk_div,
        input bit [3:0] cs_value,
        input bit [4:0] data_width,
        input bit cs_hold
    );
        apb_spi_config_seq config_seq;
        
        config_seq = apb_spi_config_seq::type_id::create("config_seq");
        config_seq.spi_enable = spi_enable;
        config_seq.spi_mode = spi_mode;
        config_seq.lsb_first = lsb_first;
        config_seq.tx_watermark = tx_watermark;
        config_seq.rx_watermark = rx_watermark;
        config_seq.clk_div = clk_div;
        config_seq.cs_value = cs_value;
        config_seq.data_width = data_width;
        config_seq.cs_hold = cs_hold;
        
        config_seq.start(apb_seqr);
    endtask
    
    // Single SPI transfer
    virtual task single_transfer(input bit[31:0] tx_data, output bit[31:0] rx_data);
        apb_spi_single_transfer_seq transfer_seq;
        
        transfer_seq = apb_spi_single_transfer_seq::type_id::create("transfer_seq");
        transfer_seq.tx_data = tx_data;
        transfer_seq.start(apb_seqr);
        rx_data = transfer_seq.rx_data;
    endtask
    
    // Burst SPI transfer with random data
    virtual task random_burst_transfer(input int burst_length);
        apb_spi_burst_transfer_seq burst_seq;
        
        burst_seq = apb_spi_burst_transfer_seq::type_id::create("burst_seq");
        burst_seq.burst_length = burst_length;
        assert(burst_seq.randomize());
        burst_seq.start(apb_seqr);
    endtask
endclass

// Basic SPI test virtual sequence
class spi_basic_test_vseq extends spi_controller_vseq_base;
    // Factory registration
    `uvm_object_utils(spi_basic_test_vseq)
    
    // Constructor
    function new(string name = "spi_basic_test_vseq");
        super.new(name);
    endfunction
    
    // Body task
    virtual task body();
        bit[31:0] rx_data;
        
        `uvm_info(get_type_name(), "Starting basic SPI test sequence", UVM_MEDIUM)
        
        // Reset the DUT
        reset_dut();
        
        // Configure with default settings
        default_config();
        
        // Perform a single transfer
        single_transfer(32'hA5A5A5A5, rx_data);
        
        `uvm_info(get_type_name(), $sformatf("SPI transfer result: 0x%0h", rx_data), UVM_MEDIUM)
        
        // Reset the DUT to clean state
        reset_dut();
        
        `uvm_info(get_type_name(), "Completed basic SPI test sequence", UVM_MEDIUM)
    endtask
endclass

// SPI mode test virtual sequence - tests all four SPI modes
class spi_mode_test_vseq extends spi_controller_vseq_base;
    // Factory registration
    `uvm_object_utils(spi_mode_test_vseq)
    
    // Constructor
    function new(string name = "spi_mode_test_vseq");
        super.new(name);
    endfunction
    
    // Body task
    virtual task body();
        bit[31:0] rx_data;
        bit[31:0] test_data = 32'h5A5A5A5A;
        
        `uvm_info(get_type_name(), "Starting SPI mode test sequence", UVM_MEDIUM)
        
        // Test all four SPI modes
        for (int mode = 0; mode < 4; mode++) begin
            `uvm_info(get_type_name(), $sformatf("Testing SPI Mode %0d", mode), UVM_MEDIUM)
            
            // Reset the DUT
            reset_dut();
            
            // Configure with specific mode
            custom_config(
                1,                  // spi_enable
                mode[1:0],          // spi_mode (0-3)
                0,                  // lsb_first (MSB first)
                2,                  // tx_watermark
                2,                  // rx_watermark
                10,                 // clk_div
                4'b0001,            // cs_value (CS0 active)
                8,                  // data_width (8-bit)
                0                   // cs_hold
            );
            
            // Perform a transfer with test data
            single_transfer(test_data, rx_data);
            
            `uvm_info(get_type_name(), 
                     $sformatf("SPI Mode %0d transfer result: 0x%0h", mode, rx_data), UVM_MEDIUM)
        end
        
        // Reset the DUT to clean state
        reset_dut();
        
        `uvm_info(get_type_name(), "Completed SPI mode test sequence", UVM_MEDIUM)
    endtask
endclass

// SPI width test virtual sequence - tests different data widths
class spi_width_test_vseq extends spi_controller_vseq_base;
    // Factory registration
    `uvm_object_utils(spi_width_test_vseq)
    
    // Constructor
    function new(string name = "spi_width_test_vseq");
        super.new(name);
    endfunction
    
    // Body task
    virtual task body();
        bit[31:0] rx_data;
        bit[31:0] test_data;
        bit[4:0] widths[] = '{8, 16, 24, 32}; // Test common data widths
        
        `uvm_info(get_type_name(), "Starting SPI width test sequence", UVM_MEDIUM)
        
        // Test multiple data widths
        foreach (widths[i]) begin
            `uvm_info(get_type_name(), $sformatf("Testing %0d-bit data width", widths[i]), UVM_MEDIUM)
            
            // Reset the DUT
            reset_dut();
            
            // Generate appropriate test pattern based on width
            test_data = (1 << widths[i]) - 1; // All 1's for the given width
            
            // Configure with specific width
            custom_config(
                1,                  // spi_enable
                0,                  // spi_mode (Mode 0)
                0,                  // lsb_first (MSB first)
                2,                  // tx_watermark
                2,                  // rx_watermark
                10,                 // clk_div
                4'b0001,            // cs_value (CS0 active)
                widths[i],          // data_width
                0                   // cs_hold
            );
            
            // Perform a transfer with test data
            single_transfer(test_data, rx_data);
            
            `uvm_info(get_type_name(), 
                     $sformatf("%0d-bit transfer result: 0x%0h", widths[i], rx_data), UVM_MEDIUM)
        end
        
        // Reset the DUT to clean state
        reset_dut();
        
        `uvm_info(get_type_name(), "Completed SPI width test sequence", UVM_MEDIUM)
    endtask
endclass

// SPI burst test virtual sequence - tests burst transfers
class spi_burst_test_vseq extends spi_controller_vseq_base;
    // Factory registration
    `uvm_object_utils(spi_burst_test_vseq)
    
    // Constructor
    function new(string name = "spi_burst_test_vseq");
        super.new(name);
    endfunction
    
    // Body task
    virtual task body();
        `uvm_info(get_type_name(), "Starting SPI burst test sequence", UVM_MEDIUM)
        
        // Reset the DUT
        reset_dut();
        
        // Configure with CS hold enabled for burst transfers
        custom_config(
            1,                  // spi_enable
            0,                  // spi_mode (Mode 0)
            0,                  // lsb_first (MSB first)
            2,                  // tx_watermark
            2,                  // rx_watermark
            10,                 // clk_div
            4'b0001,            // cs_value (CS0 active)
            8,                  // data_width (8-bit)
            1                   // cs_hold (enabled)
        );
        
        // Perform burst transfer with random data
        random_burst_transfer(8); // 8 words burst
        
        // Reset the DUT to clean state
        reset_dut();
        
        `uvm_info(get_type_name(), "Completed SPI burst test sequence", UVM_MEDIUM)
    endtask
endclass

// SPI interrupt test virtual sequence - tests interrupt functionality
class spi_interrupt_test_vseq extends spi_controller_vseq_base;
    // Factory registration
    `uvm_object_utils(spi_interrupt_test_vseq)
    
    // Constructor
    function new(string name = "spi_interrupt_test_vseq");
        super.new(name);
    endfunction
    
    // Body task
    virtual task body();
        bit[31:0] data;
        
        `uvm_info(get_type_name(), "Starting SPI interrupt test sequence", UVM_MEDIUM)
        
        // Reset the DUT
        reset_dut();
        
        // Configure SPI with default settings
        default_config();
        
        // Enable TX empty interrupt
        apb_seqr.write_reg(apb_seq_item::INTR_EN_REG, 32'h00000001);
        
        // Verify interrupt is not set yet
        apb_seqr.read_reg(apb_seq_item::INTR_STAT_REG, data);
        `uvm_info(get_type_name(), $sformatf("Initial interrupt status: 0x%0h", data), UVM_MEDIUM)
        
        // Write to TX FIFO
        apb_seqr.write_reg(apb_seq_item::TX_DATA_REG, 32'h55AA55AA);
        
        // Wait for TX FIFO to empty
        do begin
            apb_seqr.read_reg(apb_seq_item::STATUS_REG, data);
        end while(!(data & 32'h00000004)); // TX empty bit
        
        // Check that interrupt was triggered
        apb_seqr.read_reg(apb_seq_item::INTR_STAT_REG, data);
        `uvm_info(get_type_name(), $sformatf("Interrupt status after TX: 0x%0h", data), UVM_MEDIUM)
        
        // Clear the interrupt
        apb_seqr.write_reg(apb_seq_item::INTR_STAT_REG, 32'h00000001);
        
        // Verify interrupt was cleared
        apb_seqr.read_reg(apb_seq_item::INTR_STAT_REG, data);
        `uvm_info(get_type_name(), $sformatf("Interrupt status after clear: 0x%0h", data), UVM_MEDIUM)
        
        // Reset the DUT to clean state
        reset_dut();
        
        `uvm_info(get_type_name(), "Completed SPI interrupt test sequence", UVM_MEDIUM)
    endtask
endclass