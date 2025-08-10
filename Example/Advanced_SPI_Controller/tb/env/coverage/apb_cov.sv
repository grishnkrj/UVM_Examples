/**
 * APB Coverage Collector
 * 
 * This class collects functional coverage for APB transactions
 * targeting the SPI Controller registers.
 */
class apb_cov extends uvm_subscriber #(apb_seq_item);
    // Current transaction being processed
    apb_seq_item trans;
    
    // Factory registration
    `uvm_component_utils(apb_cov)
    
    // Coverage groups
    
    // APB register access coverage
    covergroup apb_reg_access_cg;
        // Register address coverage
        APB_ADDR: coverpoint trans.addr {
            // Explicit bins for each register
            bins spi_ctrl_reg      = {apb_seq_item::CTRL_REG};
            bins spi_status_reg    = {apb_seq_item::STATUS_REG};
            bins spi_clk_div_reg   = {apb_seq_item::CLK_DIV_REG};
            bins spi_cs_reg        = {apb_seq_item::CS_REG};
            bins spi_data_fmt_reg  = {apb_seq_item::DATA_FMT_REG};
            bins spi_tx_data_reg   = {apb_seq_item::TX_DATA_REG};
            bins spi_rx_data_reg   = {apb_seq_item::RX_DATA_REG};
            bins spi_intr_en_reg   = {apb_seq_item::INTR_EN_REG};
            bins spi_intr_stat_reg = {apb_seq_item::INTR_STAT_REG};
            bins spi_dma_ctrl_reg  = {apb_seq_item::DMA_CTRL_REG};
            bins spi_tx_fifo_lvl   = {apb_seq_item::TX_FIFO_LVL};
            bins spi_rx_fifo_lvl   = {apb_seq_item::RX_FIFO_LVL};
            
            // Illegal addresses
            illegal_bins illegal = default;
        }
        
        // Read/Write access coverage
        APB_DIRECTION: coverpoint trans.is_write {
            bins read = {0};
            bins write = {1};
            bins write_to_read = (1 => 0);
            bins read_to_write = (0 => 1);
        }
        
        // Error coverage
        APB_ERROR: coverpoint trans.resp_error {
            bins no_error = {0};
            bins error = {1};
        }
        
        // Important register value coverage - control register
        CTRL_REG_VALUES: coverpoint trans.data[6:0] iff (trans.is_write && trans.addr == apb_seq_item::CTRL_REG) {
            bins enable_bit      = {7'b0000001};   // Only enable bit set
            bins master_mode     = {7'b0000010};   // Only master bit set
            bins mode0           = {7'b0000000};   // SPI mode 0
            bins mode1           = {7'b0000100};   // SPI mode 1
            bins mode2           = {7'b0001000};   // SPI mode 2
            bins mode3           = {7'b0001100};   // SPI mode 3
            bins fifo_rst_bits   = {7'b0110000};   // TX and RX FIFO reset
            bins lsb_first       = {7'b1000000};   // LSB first bit set
            bins typical_config  = {7'b0000011};   // Enabled + master mode
            bins all_bits        = {7'b1111111};   // All bits set
        }
        
        // Clock divider values
        CLK_DIV_VALUES: coverpoint trans.data[7:0] iff (trans.is_write && trans.addr == apb_seq_item::CLK_DIV_REG) {
            bins min_div = {8'd1};
            bins max_div = {8'hFF};
            bins common_values[] = {8'd2, 8'd4, 8'd8, 8'd10, 8'd16, 8'd32, 8'd64};
            bins other_values = default;
        }
        
        // Cross coverage of register access
        APB_ACCESS_CROSS: cross APB_ADDR, APB_DIRECTION {
            // Verify all registers can be read and written properly
            bins ctrl_reg_write = binsof(APB_ADDR) intersect {apb_seq_item::CTRL_REG} && 
                                   binsof(APB_DIRECTION.write);
            bins ctrl_reg_read = binsof(APB_ADDR) intersect {apb_seq_item::CTRL_REG} && 
                                  binsof(APB_DIRECTION.read);
            
            // Focus on read-only registers
            bins status_reg_read = binsof(APB_ADDR) intersect {apb_seq_item::STATUS_REG} && 
                                    binsof(APB_DIRECTION.read);
            
            // Focus on write-only registers
            bins tx_data_reg_write = binsof(APB_ADDR) intersect {apb_seq_item::TX_DATA_REG} && 
                                      binsof(APB_DIRECTION.write);
            
            // Check read/write access to other registers
            bins important_registers = binsof(APB_ADDR) intersect {apb_seq_item::CLK_DIV_REG, 
                                                                  apb_seq_item::DATA_FMT_REG,
                                                                  apb_seq_item::CS_REG};
        }
        
        // Check for access errors
        APB_ADDR_X_ERROR: cross APB_ADDR, APB_ERROR;
    endgroup
    
    // Transaction sequence coverage
    covergroup apb_transaction_sequence_cg;
        // Common register access patterns for SPI configuration
        REG_ACCESS_SEQ: coverpoint trans.addr {
            // Configuration sequence: CTRL -> CLK_DIV -> CS -> DATA_FMT
            bins config_seq = (apb_seq_item::CTRL_REG => apb_seq_item::CLK_DIV_REG => 
                               apb_seq_item::CS_REG => apb_seq_item::DATA_FMT_REG);
            
            // Data transfer sequence: TX_DATA write -> STATUS read -> RX_DATA read
            bins data_transfer_seq = (apb_seq_item::TX_DATA_REG => apb_seq_item::STATUS_REG => 
                                      apb_seq_item::RX_DATA_REG);
            
            // Interrupt handling sequence
            bins interrupt_seq = (apb_seq_item::INTR_STAT_REG => apb_seq_item::INTR_EN_REG);
            
            // FIFO level checking sequence
            bins fifo_check_seq = (apb_seq_item::TX_FIFO_LVL => apb_seq_item::RX_FIFO_LVL);
        }
    endgroup
    
    // Constructor
    function new(string name = "apb_cov", uvm_component parent = null);
        super.new(name, parent);
        
        // Initialize coverage groups
        apb_reg_access_cg = new();
        apb_transaction_sequence_cg = new();
        
        // Initialize transaction
        trans = new();
    endfunction
    
    // Implementation of write function from subscriber
    function void write(apb_seq_item t);
        // Store transaction
        trans = t;
        
        // Sample coverage
        apb_reg_access_cg.sample();
        apb_transaction_sequence_cg.sample();
    endfunction
    
    // Sample coverage manually (useful for reference model)
    function void sample(apb_seq_item t);
        write(t);
    endfunction
    
    // Set transaction directly
    function void set_name(string name);
        this.set_name(name);
    endfunction
    
    // Report phase
    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("\nAPB Coverage Report:\n" 
                                           "  Register access coverage: %.2f%%\n" 
                                           "  Transaction sequence coverage: %.2f%%\n" 
                                           "  Combined coverage: %.2f%%",
                                           apb_reg_access_cg.get_coverage(),
                                           apb_transaction_sequence_cg.get_coverage(),
                                           $min(100.0, (apb_reg_access_cg.get_coverage() + 
                                                       apb_transaction_sequence_cg.get_coverage())/2)), 
                                           UVM_LOW)
    endfunction
    
endclass : apb_cov