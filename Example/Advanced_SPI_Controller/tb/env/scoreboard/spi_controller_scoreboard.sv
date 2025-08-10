/**
 * SPI Controller Scoreboard
 *
 * This class compares expected SPI transactions from the reference model
 * against actual SPI transactions observed from the DUT.
 */
class spi_controller_scoreboard extends uvm_scoreboard;
    // Analysis exports
    uvm_analysis_export #(spi_seq_item) expected_export;
    uvm_analysis_export #(spi_seq_item) actual_export;
    
    // TLM FIFOs to store transactions
    uvm_tlm_analysis_fifo #(spi_seq_item) expected_fifo;
    uvm_tlm_analysis_fifo #(spi_seq_item) actual_fifo;
    
    // Counters
    int match_count;
    int mismatch_count;
    int ignored_count;
    
    // Queue to store expected and actual transactions for reporting
    spi_seq_item expected_queue[$];
    spi_seq_item actual_queue[$];
    
    // Configuration
    bit checks_enable = 1;
    bit coverage_enable = 1;
    int max_queue_depth = 1000;
    
    // Coverage
    covergroup spi_cg;
        SPI_MODE: coverpoint trans_collected.spi_mode {
            bins mode0 = {spi_seq_item::SPI_MODE0};
            bins mode1 = {spi_seq_item::SPI_MODE1};
            bins mode2 = {spi_seq_item::SPI_MODE2};
            bins mode3 = {spi_seq_item::SPI_MODE3};
        }
        
        DATA_WIDTH: coverpoint trans_collected.data_width {
            bins standard_widths[] = {8, 16, 32};
            bins other_widths = default;
        }
        
        LSB_FIRST: coverpoint trans_collected.lsb_first {
            bins msb_first = {0};
            bins lsb_first = {1};
        }
        
        CS_HOLD: coverpoint trans_collected.hold_cs {
            bins no_hold = {0};
            bins hold = {1};
        }
        
        // Cross coverages
        SPI_MODE_X_WIDTH: cross SPI_MODE, DATA_WIDTH;
        SPI_MODE_X_LSB: cross SPI_MODE, LSB_FIRST;
    endgroup
    
    // Transaction being collected for coverage
    protected spi_seq_item trans_collected;
    
    // Factory registration
    `uvm_component_utils_begin(spi_controller_scoreboard)
        `uvm_field_int(checks_enable, UVM_DEFAULT)
        `uvm_field_int(coverage_enable, UVM_DEFAULT)
    `uvm_component_utils_end
    
    // Constructor
    function new(string name = "spi_controller_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        
        // Initialize coverage
        trans_collected = new();
        spi_cg = new();
        
        // Initialize counters
        match_count = 0;
        mismatch_count = 0;
        ignored_count = 0;
    endfunction
    
    // Build phase - create analysis exports and FIFOs
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        expected_export = new("expected_export", this);
        actual_export = new("actual_export", this);
        expected_fifo = new("expected_fifo", this);
        actual_fifo = new("actual_fifo", this);
    endfunction
    
    // Connect phase - connect exports to FIFOs
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        expected_export.connect(expected_fifo.analysis_export);
        actual_export.connect(actual_fifo.analysis_export);
    endfunction
    
    // Run phase - compare transactions
    virtual task run_phase(uvm_phase phase);
        spi_seq_item expected_txn, actual_txn;
        
        forever begin
            // Fork to wait for both expected and actual transactions
            fork
                expected_fifo.get(expected_txn);
                actual_fifo.get(actual_txn);
            join
            
            // Store transactions for potential debug
            store_transaction(expected_txn, actual_txn);
            
            // Compare if checks are enabled
            if (checks_enable) begin
                compare_transactions(expected_txn, actual_txn);
            end
            
            // Collect coverage if enabled
            if (coverage_enable) begin
                trans_collected = actual_txn;
                spi_cg.sample();
            end
        end
    endtask
    
    // Store transactions for reporting, with queue management
    protected virtual function void store_transaction(spi_seq_item expected, spi_seq_item actual);
        // Add to queues
        expected_queue.push_back(expected);
        actual_queue.push_back(actual);
        
        // Manage queue size
        if (expected_queue.size() > max_queue_depth) begin
            void'(expected_queue.pop_front());
            void'(actual_queue.pop_front());
        end
    endfunction
    
    // Compare expected and actual transactions
    protected virtual function void compare_transactions(spi_seq_item expected, spi_seq_item actual);
        bit match = 1;
        
        // Basic comparison - ignore rx_data as that's set by the external environment
        if (expected.spi_mode != actual.spi_mode) begin
            `uvm_error(get_type_name(), $sformatf("SPI Mode mismatch: Expected %s, Got %s",
                                                 expected.spi_mode.name(), actual.spi_mode.name()))
            match = 0;
        end
        
        if (expected.tx_data != actual.tx_data) begin
            `uvm_error(get_type_name(), $sformatf("TX Data mismatch: Expected 0x%0h, Got 0x%0h",
                                                 expected.tx_data, actual.tx_data))
            match = 0;
        end
        
        if (expected.cs_select != actual.cs_select) begin
            `uvm_error(get_type_name(), $sformatf("CS Select mismatch: Expected 0x%0h, Got 0x%0h",
                                                 expected.cs_select, actual.cs_select))
            match = 0;
        end
        
        if (expected.lsb_first != actual.lsb_first) begin
            `uvm_error(get_type_name(), $sformatf("LSB First mismatch: Expected %0d, Got %0d",
                                                 expected.lsb_first, actual.lsb_first))
            match = 0;
        end
        
        if (expected.data_width != actual.data_width) begin
            `uvm_error(get_type_name(), $sformatf("Data Width mismatch: Expected %0d, Got %0d",
                                                 expected.data_width, actual.data_width))
            match = 0;
        end
        
        if (expected.hold_cs != actual.hold_cs) begin
            `uvm_error(get_type_name(), $sformatf("Hold CS mismatch: Expected %0d, Got %0d",
                                                 expected.hold_cs, actual.hold_cs))
            match = 0;
        end
        
        // Update counters
        if (match)
            match_count++;
        else
            mismatch_count++;
    endfunction
    
    // Report phase - print statistics
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info(get_type_name(), $sformatf("\n--- SPI Controller Scoreboard Report ---\n" 
                                           "Matches:    %0d\n" 
                                           "Mismatches: %0d\n" 
                                           "Ignored:    %0d\n" 
                                           "-------------------------------------",
                                           match_count, mismatch_count, ignored_count), UVM_LOW)
                                           
        // Report failure if mismatches occurred
        if (mismatch_count > 0) begin
            `uvm_error(get_type_name(), $sformatf("Scoreboard detected %0d mismatches", mismatch_count))
        end
    endfunction
    
endclass : spi_controller_scoreboard