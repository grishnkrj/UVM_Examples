/**
 * APB Driver Class
 * 
 * This class is responsible for driving APB transactions to the DUT.
 * It converts sequence items to pin-level activity on the APB interface.
 *
 * Features:
 * - APB3 protocol implementation
 * - Proper handling of delays and protocol phases
 * - Error handling
 * - Transaction response collection
 */
class apb_driver extends uvm_driver #(apb_seq_item);
    // Virtual interface
    protected virtual apb_if vif;
    
    // Configuration object
    protected apb_config cfg;
    
    // Transaction counter
    protected int unsigned transaction_count;
    
    // Factory registration
    `uvm_component_utils(apb_driver)
    
    // Constructor
    function new(string name = "apb_driver", uvm_component parent = null);
        super.new(name, parent);
        transaction_count = 0;
    endfunction
    
    // Build phase - get interface from config_db
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get config object
        if (!uvm_config_db#(apb_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("APB_DRIVER", "Failed to get config object")
            
        // Get virtual interface
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("APB_DRIVER", "Failed to get virtual interface")
    endfunction
    
    // Run phase - main driver functionality
    virtual task run_phase(uvm_phase phase);
        // Initialize signals
        vif.drv_cb.psel <= 0;
        vif.drv_cb.penable <= 0;
        
        // Wait for reset to complete
        wait_for_reset();
        
        `uvm_info(get_type_name(), "APB driver running", UVM_MEDIUM)
        
        forever begin
            apb_seq_item req;
            apb_seq_item rsp;
            
            // Get new transaction
            seq_item_port.get_next_item(req);
            
            // Create response transaction as a copy
            $cast(rsp, req.clone());
            rsp.set_id_info(req);
            
            // Apply requested delay before starting transaction
            repeat(req.delay) @(vif.drv_cb);
            
            // Execute the APB transaction
            if (req.is_write) begin
                do_write(req);
                rsp.resp_error = vif.pslverr;
            end else begin
                do_read(req);
                rsp.rdata = vif.prdata;
                rsp.resp_error = vif.pslverr;
            end
            
            // Increment transaction counter
            transaction_count++;
            
            // Send response back to sequencer
            seq_item_port.item_done(rsp);
            
            `uvm_info(get_type_name(), $sformatf("Completed transaction: %s", 
                                               req.convert2string()), UVM_HIGH)
        end
    endtask
    
    // Helper task to wait for reset completion
    protected task wait_for_reset();
        @(posedge vif.rst_n);
        // Add a small delay after reset
        repeat(5) @(vif.drv_cb);
    endtask
    
    // Execute APB write transaction
    protected task do_write(apb_seq_item req);
        // SETUP phase
        @(vif.drv_cb);
        vif.drv_cb.psel <= 1'b1;
        vif.drv_cb.penable <= 1'b0;
        vif.drv_cb.pwrite <= 1'b1;
        vif.drv_cb.paddr <= req.addr;
        vif.drv_cb.pwdata <= req.data;
        
        // ACCESS phase
        @(vif.drv_cb);
        vif.drv_cb.penable <= 1'b1;
        
        // Wait for slave to be ready
        do begin
            @(vif.drv_cb);
        end while (!vif.pready);
        
        // Check for errors
        if (vif.pslverr)
            `uvm_warning("APB_DRIVER", $sformatf("APB SLAVE ERROR: addr=0x%0h", req.addr))
        
        // Return to IDLE
        @(vif.drv_cb);
        vif.drv_cb.psel <= 1'b0;
        vif.drv_cb.penable <= 1'b0;
    endtask
    
    // Execute APB read transaction
    protected task do_read(apb_seq_item req);
        // SETUP phase
        @(vif.drv_cb);
        vif.drv_cb.psel <= 1'b1;
        vif.drv_cb.penable <= 1'b0;
        vif.drv_cb.pwrite <= 1'b0;
        vif.drv_cb.paddr <= req.addr;
        
        // ACCESS phase
        @(vif.drv_cb);
        vif.drv_cb.penable <= 1'b1;
        
        // Wait for slave to be ready
        do begin
            @(vif.drv_cb);
        end while (!vif.pready);
        
        // Check for errors
        if (vif.pslverr)
            `uvm_warning("APB_DRIVER", $sformatf("APB SLAVE ERROR: addr=0x%0h", req.addr))
        
        // Return to IDLE
        @(vif.drv_cb);
        vif.drv_cb.psel <= 1'b0;
        vif.drv_cb.penable <= 1'b0;
    endtask
    
    // Return transaction count
    function int unsigned get_transaction_count();
        return transaction_count;
    endfunction
    
endclass : apb_driver