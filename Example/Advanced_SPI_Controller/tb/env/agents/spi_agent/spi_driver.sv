/**
 * SPI Driver Class
 * 
 * This class is responsible for driving SPI slave responses to the DUT.
 * It handles the MISO line for responding to SPI master transactions.
 *
 * Features:
 * - SPI slave emulation (MISO only)
 * - Support for all SPI modes (0-3)
 * - LSB/MSB first data handling
 * - Variable data width support
 */
class spi_driver extends uvm_driver #(spi_seq_item);
    // Virtual interface
    protected virtual spi_if vif;
    
    // Configuration object
    protected spi_config cfg;
    
    // Transaction counter
    protected int unsigned transaction_count;
    
    // Factory registration
    `uvm_component_utils(spi_driver)
    
    // Constructor
    function new(string name = "spi_driver", uvm_component parent = null);
        super.new(name, parent);
        transaction_count = 0;
    endfunction
    
    // Build phase - get interface from config_db
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get config object
        if (!uvm_config_db#(spi_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("SPI_DRIVER", "Failed to get config object")
            
        // Get virtual interface
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif))
            `uvm_fatal("SPI_DRIVER", "Failed to get virtual interface")
    endfunction
    
    // Run phase - main driver functionality
    virtual task run_phase(uvm_phase phase);
        // Initialize signals
        vif.drv_cb.spi_miso <= 1'b0;
        
        // Wait for reset to complete
        @(posedge vif.rst_n);
        repeat(5) @(vif.drv_cb);
        
        `uvm_info(get_type_name(), "SPI driver running", UVM_MEDIUM)
        
        fork
            // Handle incoming transactions
            process_transactions();
            
            // Monitor for SPI activity and respond automatically if no specific transaction
            auto_respond_task();
        join
    endtask
    
    // Main transaction processing task
    virtual task process_transactions();
        forever begin
            spi_seq_item req;
            spi_seq_item rsp;
            
            // Get new transaction
            seq_item_port.get_next_item(req);
            
            // Create response transaction as a copy
            $cast(rsp, req.clone());
            rsp.set_id_info(req);
            
            // Wait for SPI transaction to begin
            wait_for_spi_transfer_start();
            
            // Drive the transaction
            drive_spi_miso(req);
            
            // Increment transaction counter
            transaction_count++;
            
            // Send response back to sequencer
            seq_item_port.item_done(rsp);
            
            `uvm_info(get_type_name(), $sformatf("Completed transaction: %s", 
                                               req.convert2string()), UVM_HIGH)
        end
    endtask
    
    // Auto-response task - respond with default data when no sequence item is available
    virtual task auto_respond_task();
        forever begin
            // Wait for any chip select to be activated
            wait_for_cs_active();
            
            // Check if we have a pending transaction
            if (seq_item_port.has_do_available()) begin
                // If we have a transaction, let process_transactions handle it
                @(vif.drv_cb);
            end else begin
                // Otherwise provide default response (all zeros)
                default_spi_response();
            end
        end
    endtask
    
    // Wait for any chip select to become active
    virtual task wait_for_cs_active();
        int timeout_count = 0;
        
        // Wait until any chip select becomes active (low)
        while (vif.spi_cs_n == {cfg.cs_width{1'b1}} && timeout_count < cfg.timeout) begin
            @(vif.drv_cb);
            timeout_count++;
        end
        
        if (timeout_count >= cfg.timeout)
            `uvm_error("SPI_DRIVER", "Timeout waiting for CS activation")
    endtask
    
    // Wait for SPI transfer to start
    virtual task wait_for_spi_transfer_start();
        int timeout_count = 0;
        
        // Wait for chip select to be active and a clock edge
        while ((!vif.spi_clk_posedge && !vif.spi_clk_negedge) || 
               vif.spi_cs_n == {cfg.cs_width{1'b1}}) begin
            @(vif.drv_cb);
            timeout_count++;
            if (timeout_count >= cfg.timeout) begin
                `uvm_error("SPI_DRIVER", "Timeout waiting for SPI transfer start")
                break;
            end
        end
    endtask
    
    // Drive MISO line based on transaction
    virtual task drive_spi_miso(spi_seq_item trans);
        // Detect active chip select
        int active_cs_idx = -1;
        
        for (int i = 0; i < cfg.cs_width; i++) begin
            if (!vif.spi_cs_n[i]) begin
                active_cs_idx = i;
                break;
            end
        end
        
        if (active_cs_idx == -1) begin
            `uvm_error("SPI_DRIVER", "No active CS detected")
            return;
        end
        
        // Determine which edge to drive data on based on SPI mode
        bit drive_on_posedge = (trans.spi_mode == spi_seq_item::SPI_MODE0 || 
                               trans.spi_mode == spi_seq_item::SPI_MODE3);
                               
        // Drive MISO for each bit in the transaction
        for (int bit_idx = 0; bit_idx < trans.data_width; bit_idx++) begin
            bit miso_bit;
            
            // Get the correct bit based on LSB/MSB first configuration
            miso_bit = trans.get_miso_bit(bit_idx);
            
            // Wait for the appropriate clock edge to drive data
            if (drive_on_posedge)
                wait_for_spi_posedge();
            else
                wait_for_spi_negedge();
                
            // Drive the data bit
            vif.drv_cb.spi_miso <= miso_bit;
            
            // Wait for the next edge to complete the bit
            if (drive_on_posedge)
                wait_for_spi_negedge();
            else
                wait_for_spi_posedge();
        end
        
        // Reset MISO to default state
        vif.drv_cb.spi_miso <= 1'b0;
    endtask
    
    // Default SPI response - send all zeros
    virtual task default_spi_response();
        // Continue sending zeros while CS is active
        while (vif.spi_cs_n != {cfg.cs_width{1'b1}}) begin
            vif.drv_cb.spi_miso <= 1'b0;
            @(vif.drv_cb);
        end
    endtask
    
    // Wait for positive edge on SPI clock
    virtual task wait_for_spi_posedge();
        int timeout_count = 0;
        
        while (!vif.spi_clk_posedge && timeout_count < cfg.timeout) begin
            @(vif.drv_cb);
            timeout_count++;
        end
        
        if (timeout_count >= cfg.timeout)
            `uvm_error("SPI_DRIVER", "Timeout waiting for SPI clock posedge")
    endtask
    
    // Wait for negative edge on SPI clock
    virtual task wait_for_spi_negedge();
        int timeout_count = 0;
        
        while (!vif.spi_clk_negedge && timeout_count < cfg.timeout) begin
            @(vif.drv_cb);
            timeout_count++;
        end
        
        if (timeout_count >= cfg.timeout)
            `uvm_error("SPI_DRIVER", "Timeout waiting for SPI clock negedge")
    endtask
    
    // Return transaction count
    function int unsigned get_transaction_count();
        return transaction_count;
    endfunction
    
endclass : spi_driver