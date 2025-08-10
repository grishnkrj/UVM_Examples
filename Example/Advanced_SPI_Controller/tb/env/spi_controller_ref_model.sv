/**
 * SPI Controller Reference Model
 * 
 * This class predicts expected behavior of the SPI controller based on APB transactions.
 * It produces expected SPI transactions for comparison in the scoreboard.
 */
class spi_controller_ref_model extends uvm_component;
    // Analysis export to receive APB transactions
    uvm_analysis_export #(apb_seq_item) apb_analysis_export;
    
    // Analysis port to send predicted SPI transactions
    uvm_analysis_port #(spi_seq_item) spi_analysis_port;
    
    // TLM FIFO to handle incoming APB transactions
    uvm_tlm_analysis_fifo #(apb_seq_item) apb_fifo;
    
    // Internal model state - mirrors DUT registers
    protected bit [31:0] ctrl_reg;
    protected bit [31:0] status_reg;
    protected bit [31:0] clk_div_reg;
    protected bit [31:0] cs_reg;
    protected bit [31:0] data_fmt_reg;
    protected bit [31:0] intr_en_reg;
    protected bit [31:0] intr_stat_reg;
    protected bit [31:0] dma_ctrl_reg;
    
    // FIFO representations
    protected bit [31:0] tx_fifo[$];
    protected bit [31:0] rx_fifo[$];
    
    // FIFO size limit - must match DUT parameter
    protected int FIFO_DEPTH = 16;
    
    // Factory registration
    `uvm_component_utils(spi_controller_ref_model)
    
    // Constructor
    function new(string name = "spi_controller_ref_model", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build phase - create ports and FIFOs
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        apb_analysis_export = new("apb_analysis_export", this);
        spi_analysis_port = new("spi_analysis_port", this);
        apb_fifo = new("apb_fifo", this);
        
        // Initialize registers to reset values
        reset_model();
    endfunction
    
    // Connect phase - connect ports to FIFOs
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        apb_analysis_export.connect(apb_fifo.analysis_export);
    endfunction
    
    // Run phase - process incoming transactions
    virtual task run_phase(uvm_phase phase);
        apb_seq_item apb_tx;
        
        forever begin
            // Wait for APB transaction
            apb_fifo.get(apb_tx);
            
            // Process the transaction
            process_apb_transaction(apb_tx);
        end
    endtask
    
    // Process APB transaction
    protected virtual function void process_apb_transaction(apb_seq_item tx);
        // Process based on transaction type (read/write)
        if (tx.is_write) begin
            process_apb_write(tx);
        end
        else begin
            process_apb_read(tx);
        end
    endfunction
    
    // Process APB write transaction
    protected virtual function void process_apb_write(apb_seq_item tx);
        bit [31:0] data = tx.data;
        
        case (tx.addr)
            apb_seq_item::CTRL_REG: begin
                // Handle TX/RX FIFO reset bits
                if (data[4]) begin // tx_fifo_rst
                    tx_fifo.delete();
                    status_reg[2] = 1'b1; // tx_empty = 1
                    status_reg[1] = 1'b0; // tx_full = 0
                end
                
                if (data[5]) begin // rx_fifo_rst
                    rx_fifo.delete();
                    status_reg[4] = 1'b1; // rx_empty = 1
                    status_reg[3] = 1'b0; // rx_full = 0
                end
                
                // Clear reset bits (write-once semantics)
                ctrl_reg = data;
                ctrl_reg[4] = 1'b0;
                ctrl_reg[5] = 1'b0;
                
                // Check if a transmission should start
                check_for_spi_transfer();
            end
            
            apb_seq_item::CLK_DIV_REG: begin
                clk_div_reg = data;
            end
            
            apb_seq_item::CS_REG: begin
                cs_reg = data;
                
                // If SPI is enabled and CS changes, generate a SPI transaction
                if (ctrl_reg[0]) begin
                    predict_spi_cs_change();
                end
            end
            
            apb_seq_item::DATA_FMT_REG: begin
                data_fmt_reg = data;
            end
            
            apb_seq_item::TX_DATA_REG: begin
                // Write to TX FIFO if not full
                if (tx_fifo.size() < FIFO_DEPTH) begin
                    tx_fifo.push_back(data);
                    
                    // Update status register
                    status_reg[2] = (tx_fifo.size() == 0); // tx_empty
                    status_reg[1] = (tx_fifo.size() == FIFO_DEPTH); // tx_full
                    status_reg[5] = (tx_fifo.size() <= ctrl_reg[17:10]); // tx_watermark_hit
                    
                    // Check if a transmission should start
                    check_for_spi_transfer();
                end
            end
            
            apb_seq_item::INTR_EN_REG: begin
                intr_en_reg = data;
                
                // Update interrupt output
                update_interrupt();
            end
            
            apb_seq_item::INTR_STAT_REG: begin
                // Write 1 to clear
                intr_stat_reg &= ~data;
                
                // Update interrupt output
                update_interrupt();
            end
            
            apb_seq_item::DMA_CTRL_REG: begin
                dma_ctrl_reg = data;
            end
        endcase
    endfunction
    
    // Process APB read transaction
    protected virtual function void process_apb_read(apb_seq_item tx);
        case (tx.addr)
            apb_seq_item::CTRL_REG: begin
                tx.rdata = ctrl_reg;
            end
            
            apb_seq_item::STATUS_REG: begin
                tx.rdata = status_reg;
            end
            
            apb_seq_item::CLK_DIV_REG: begin
                tx.rdata = clk_div_reg;
            end
            
            apb_seq_item::CS_REG: begin
                tx.rdata = cs_reg;
            end
            
            apb_seq_item::DATA_FMT_REG: begin
                tx.rdata = data_fmt_reg;
            end
            
            apb_seq_item::RX_DATA_REG: begin
                // Read from RX FIFO if not empty
                if (rx_fifo.size() > 0) begin
                    tx.rdata = rx_fifo.pop_front();
                    
                    // Update status register
                    status_reg[4] = (rx_fifo.size() == 0); // rx_empty
                    status_reg[3] = (rx_fifo.size() == FIFO_DEPTH); // rx_full
                    status_reg[6] = (rx_fifo.size() >= ctrl_reg[25:18]); // rx_watermark_hit
                end
                else begin
                    tx.rdata = 32'h0;
                end
            end
            
            apb_seq_item::INTR_EN_REG: begin
                tx.rdata = intr_en_reg;
            end
            
            apb_seq_item::INTR_STAT_REG: begin
                tx.rdata = intr_stat_reg;
            end
            
            apb_seq_item::DMA_CTRL_REG: begin
                tx.rdata = dma_ctrl_reg;
            end
            
            apb_seq_item::TX_FIFO_LVL: begin
                tx.rdata = tx_fifo.size();
            end
            
            apb_seq_item::RX_FIFO_LVL: begin
                tx.rdata = rx_fifo.size();
            end
            
            default: begin
                tx.rdata = 32'h0;
                tx.resp_error = 1'b1;
            end
        endcase
    endfunction
    
    // Reset the model to initial state
    protected virtual function void reset_model();
        ctrl_reg = 32'h0;
        ctrl_reg[1] = 1'b1; // Default master mode
        
        status_reg = 32'h0;
        status_reg[2] = 1'b1; // tx_empty = 1
        status_reg[4] = 1'b1; // rx_empty = 1
        
        clk_div_reg = 32'd10;  // Default clock divider
        cs_reg = 32'hFFFFFFFF; // All CS lines inactive
        
        data_fmt_reg = 32'h0;
        data_fmt_reg[4:0] = 5'd8; // Default to 8-bit data
        
        intr_en_reg = 32'h0;
        intr_stat_reg = 32'h0;
        dma_ctrl_reg = 32'h0;
        
        tx_fifo.delete();
        rx_fifo.delete();
    endfunction
    
    // Check if conditions are right for an SPI transfer and generate prediction
    protected virtual function void check_for_spi_transfer();
        // SPI enabled, TX FIFO not empty, and we're in IDLE state
        if (ctrl_reg[0] && tx_fifo.size() > 0 && !status_reg[0]) begin
            predict_spi_transfer();
        end
    endfunction
    
    // Predict SPI transaction based on current model state
    protected virtual function void predict_spi_transfer();
        spi_seq_item spi_tx;
        bit [31:0] tx_data;
        
        // Mark SPI as busy
        status_reg[0] = 1'b1; // busy = 1
        
        // Get data from TX FIFO
        tx_data = tx_fifo.pop_front();
        
        // Update status register
        status_reg[2] = (tx_fifo.size() == 0); // tx_empty
        status_reg[1] = (tx_fifo.size() == FIFO_DEPTH); // tx_full
        status_reg[5] = (tx_fifo.size() <= ctrl_reg[17:10]); // tx_watermark_hit
        
        // Create SPI transaction
        spi_tx = spi_seq_item::type_id::create("spi_tx");
        
        // Configure SPI transaction based on register settings
        spi_tx.spi_mode = spi_seq_item::spi_mode_t'(ctrl_reg[3:2]);
        spi_tx.tx_data = tx_data;
        // Set dummy rx_data - this would come from the slave in reality
        spi_tx.rx_data = 32'h0;
        spi_tx.cs_select = cs_reg;
        spi_tx.lsb_first = ctrl_reg[6];
        spi_tx.data_width = data_fmt_reg[4:0];
        spi_tx.hold_cs = data_fmt_reg[6];
        
        // Send predicted transaction to scoreboard
        spi_analysis_port.write(spi_tx);
        
        // Simulate data being received (in a real system this would come from slave)
        if (rx_fifo.size() < FIFO_DEPTH) begin
            rx_fifo.push_back(32'h0); // Push dummy data
            
            // Update status register
            status_reg[4] = (rx_fifo.size() == 0); // rx_empty
            status_reg[3] = (rx_fifo.size() == FIFO_DEPTH); // rx_full
            status_reg[6] = (rx_fifo.size() >= ctrl_reg[25:18]); // rx_watermark_hit
        end
        
        // Mark SPI as not busy when transfer completes
        status_reg[0] = 1'b0; // busy = 0
        
        // Update interrupt status register
        if (status_reg[2]) intr_stat_reg[0] = 1'b1; // tx_empty_st
        if (status_reg[5]) intr_stat_reg[1] = 1'b1; // tx_watermark_st
        if (status_reg[3]) intr_stat_reg[2] = 1'b1; // rx_full_st
        if (status_reg[6]) intr_stat_reg[3] = 1'b1; // rx_watermark_st
        intr_stat_reg[4] = !status_reg[0]; // spi_idle_st
        
        // Update interrupt output
        update_interrupt();
        
        // If CS hold is enabled and there's more data, start another transfer
        if (data_fmt_reg[6] && tx_fifo.size() > 0) begin
            predict_spi_transfer();
        end
    endfunction
    
    // Predict SPI behavior when chip select changes
    protected virtual function void predict_spi_cs_change();
        spi_seq_item spi_tx;
        
        // Create SPI transaction just for CS change
        spi_tx = spi_seq_item::type_id::create("spi_tx");
        
        // Configure with minimal information for CS change
        spi_tx.spi_mode = spi_seq_item::spi_mode_t'(ctrl_reg[3:2]);
        spi_tx.cs_select = cs_reg;
        
        // Send predicted transaction to scoreboard
        spi_analysis_port.write(spi_tx);
    endfunction
    
    // Update interrupt output based on status and enables
    protected virtual function void update_interrupt();
        // Mask interrupt status with enables
        bit [31:0] masked_ints = intr_stat_reg & intr_en_reg;
        
        // Generate interrupt if any enabled status bit is set
        // In a real implementation, this would drive the irq output
        // For the reference model, we just track the state
        bit irq_state = (|masked_ints) ? 1'b1 : 1'b0;
        
        // Log interrupt state changes for debug
        if (irq_state)
            `uvm_info(get_type_name(), $sformatf("Interrupt asserted: status=0x%08h, enable=0x%08h", 
                                                intr_stat_reg, intr_en_reg), UVM_HIGH)
    endfunction
    
endclass : spi_controller_ref_model