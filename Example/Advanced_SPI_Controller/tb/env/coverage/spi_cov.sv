/**
 * SPI Coverage Collector
 * 
 * This class collects functional coverage for SPI transactions.
 * It provides more extensive coverage than the basic coverage in the scoreboard.
 */
class spi_cov extends uvm_subscriber #(spi_seq_item);
    // The transaction currently being processed
    spi_seq_item trans;
    
    // Factory registration
    `uvm_component_utils(spi_cov)
    
    // Coverage groups
    
    // SPI transaction coverage
    covergroup spi_transaction_cg;
        // SPI mode coverage
        SPI_MODE: coverpoint trans.spi_mode {
            bins mode0 = {spi_seq_item::SPI_MODE0};
            bins mode1 = {spi_seq_item::SPI_MODE1};
            bins mode2 = {spi_seq_item::SPI_MODE2};
            bins mode3 = {spi_seq_item::SPI_MODE3};
            
            // Add illegal values for verification
            illegal_bins illegal = default;
        }
        
        // Data width coverage
        DATA_WIDTH: coverpoint trans.data_width {
            bins min_width = {4};
            bins max_width = {32};
            bins common_widths[] = {8, 16, 24};
            bins other_widths = default;
        }
        
        // LSB/MSB first data ordering
        LSB_FIRST: coverpoint trans.lsb_first {
            bins msb_first = {0};
            bins lsb_first = {1};
        }
        
        // Chip select patterns - using one-hot encoding
        CS_SELECT: coverpoint trans.cs_select {
            bins single_cs[4] = {16'h0001, 16'h0002, 16'h0004, 16'h0008};
            bins no_cs = {16'h0000};
            bins other_cs = default;
        }
        
        // Hold CS between transfers
        HOLD_CS: coverpoint trans.hold_cs {
            bins no_hold = {0};
            bins hold = {1};
        }
        
        // Data patterns for TX
        TX_DATA_SPECIAL: coverpoint trans.tx_data {
            bins all_zeros = {32'h00000000};
            bins all_ones = {32'hFFFFFFFF};
            bins alternating1 = {32'h55555555};
            bins alternating2 = {32'hAAAAAAAA};
            bins other = default;
        }
        
        // Cross coverage
        SPI_MODE_X_DATA_WIDTH: cross SPI_MODE, DATA_WIDTH {
            // Focus on common combinations
            bins common_combos = binsof(SPI_MODE) && binsof(DATA_WIDTH.common_widths);
        }
        
        SPI_MODE_X_LSB: cross SPI_MODE, LSB_FIRST;
        
        DATA_WIDTH_X_LSB: cross DATA_WIDTH, LSB_FIRST {
            // Common combinations of data width and data ordering
            bins common_8bit_msb = binsof(DATA_WIDTH) intersect {8} && binsof(LSB_FIRST.msb_first);
            bins common_8bit_lsb = binsof(DATA_WIDTH) intersect {8} && binsof(LSB_FIRST.lsb_first);
        }
        
        FULL_CONFIG: cross SPI_MODE, DATA_WIDTH, LSB_FIRST, HOLD_CS {
            // Limit to avoid explosion of crosses
            option.cross_auto_bin_max = 64;
        }
    endgroup
    
    // SPI protocol state transitions
    covergroup spi_protocol_cg;
        // CPOL transitions
        CPOL: coverpoint (trans.spi_mode[1]) {
            bins cpol_0 = {0};
            bins cpol_1 = {1};
            bins cpol_transition_0_to_1 = (0 => 1);
            bins cpol_transition_1_to_0 = (1 => 0);
        }
        
        // CPHA transitions
        CPHA: coverpoint (trans.spi_mode[0]) {
            bins cpha_0 = {0};
            bins cpha_1 = {1};
            bins cpha_transition_0_to_1 = (0 => 1);
            bins cpha_transition_1_to_0 = (1 => 0);
        }
        
        // Data width transitions
        DATA_WIDTH_TRANS: coverpoint trans.data_width {
            bins width_transitions[] = (8 => 16 => 32 => 8);
            bins width_reduce[] = (32 => 16 => 8 => 4);
        }
    endgroup
    
    // Constructor
    function new(string name = "spi_cov", uvm_component parent = null);
        super.new(name, parent);
        
        // Initialize coverage groups
        spi_transaction_cg = new();
        spi_protocol_cg = new();
        
        // Initialize transaction
        trans = new();
    endfunction
    
    // Implementation of write function from subscriber
    function void write(spi_seq_item t);
        // Store transaction
        trans = t;
        
        // Sample coverage
        spi_transaction_cg.sample();
        spi_protocol_cg.sample();
    endfunction
    
    // Sample coverage manually (useful for reference model)
    function void sample(spi_seq_item t);
        write(t);
    endfunction
    
    // Set transaction directly
    function void set_trans(spi_seq_item t);
        trans = t;
    endfunction
    
    // Sample current transaction
    function void sample();
        spi_transaction_cg.sample();
        spi_protocol_cg.sample();
    endfunction
    
    // Report phase
    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("\nSPI Coverage Report:\n" 
                                           "  Transaction coverage: %.2f%%\n" 
                                           "  Protocol coverage: %.2f%%\n" 
                                           "  Combined coverage: %.2f%%",
                                           spi_transaction_cg.get_coverage(),
                                           spi_protocol_cg.get_coverage(),
                                           $min(100.0, (spi_transaction_cg.get_coverage() + spi_protocol_cg.get_coverage())/2)), 
                                           UVM_LOW)
    endfunction
    
endclass : spi_cov