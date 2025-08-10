/**
 * APB Monitor Class
 * 
 * This class monitors the APB interface and converts pin-level activity
 * to APB transactions for analysis.
 *
 * Features:
 * - Observes pin-level activity without driving
 * - Converts to transaction-level activity
 * - Analysis port for sending observed transactions
 * - Protocol checking (optional)
 * - Coverage collection (optional)
 */
class apb_monitor extends uvm_monitor;
    // Virtual interface
    protected virtual apb_if vif;
    
    // Configuration object
    protected apb_config cfg;
    
    // Analysis port to broadcast transactions
    uvm_analysis_port #(apb_seq_item) item_collected_port;
    
    // Transaction coverage
    protected bit coverage_enable = 0;
    
    // Factory registration
    `uvm_component_utils_begin(apb_monitor)
        `uvm_field_object(cfg, UVM_REFERENCE)
    `uvm_component_utils_end
    
    // Constructor
    function new(string name = "apb_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction
    
    // Build phase - get interface from config_db
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get config object
        if (!uvm_config_db#(apb_config)::get(this, "", "cfg", cfg))
            `uvm_fatal("APB_MONITOR", "Failed to get config object")
            
        // Get virtual interface
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("APB_MONITOR", "Failed to get virtual interface")
            
        // Enable coverage collection if configured
        void'(uvm_config_db#(bit)::get(this, "", "coverage_enable", coverage_enable));
        if (coverage_enable) begin
            apb_cov = new();
            apb_cov.set_name("apb_cov");
        end
    endfunction
    
    // Run phase - main monitoring functionality
    virtual task run_phase(uvm_phase phase);
        // Wait for reset to complete
        @(posedge vif.rst_n);
        
        `uvm_info(get_type_name(), "APB monitor running", UVM_MEDIUM)
        
        forever begin
            apb_seq_item trans;
            
            // Detect start of APB transaction (SETUP phase)
            @(vif.mon_cb);
            if (vif.mon_cb.psel && !vif.mon_cb.penable) begin
                // Create new transaction
                trans = apb_seq_item::type_id::create("trans");
                
                // Capture address and direction
                trans.addr = vif.mon_cb.paddr;
                trans.is_write = vif.mon_cb.pwrite;
                
                if (trans.is_write) begin
                    // For write, capture data in SETUP phase
                    trans.data = vif.mon_cb.pwdata;
                end
                
                // Wait for ACCESS phase
                @(vif.mon_cb);
                
                // Ensure valid protocol behavior
                if (!vif.mon_cb.penable) begin
                    `uvm_error("APB_MONITOR", "Invalid APB protocol: missing ACCESS phase")
                    continue;
                end
                
                // Wait for transfer to complete
                do begin
                    @(vif.mon_cb);
                end while (!vif.mon_cb.pready);
                
                // Capture response
                trans.resp_error = vif.mon_cb.pslverr;
                
                // For read transactions, capture read data
                if (!trans.is_write) begin
                    trans.rdata = vif.mon_cb.prdata;
                end
                
                // Send transaction through analysis port
                item_collected_port.write(trans);
                
                // Sample coverage if enabled
                if (coverage_enable) begin
                    apb_cov.sample(trans);
                end
                
                `uvm_info(get_type_name(), $sformatf("Collected transaction: %s", 
                                                  trans.convert2string()), UVM_HIGH)
            end
        end
    endtask
    
    // Optional covergroup
    covergroup apb_cov;
        APB_ADDR: coverpoint trans.addr {
            bins spi_ctrl_reg    = {12'h000};
            bins spi_status_reg  = {12'h004};
            bins spi_clk_div_reg = {12'h008};
            bins spi_cs_reg      = {12'h00C};
            bins spi_data_fmt    = {12'h010};
            bins spi_tx_data     = {12'h014};
            bins spi_rx_data     = {12'h018};
            bins spi_intr_en     = {12'h01C};
            bins spi_intr_stat   = {12'h020};
            bins spi_dma_ctrl    = {12'h024};
            bins spi_tx_fifo_lvl = {12'h028};
            bins spi_rx_fifo_lvl = {12'h02C};
            bins others = default;
        }
        
        APB_DIRECTION: coverpoint trans.is_write {
            bins read = {0};
            bins write = {1};
        }
        
        APB_ERROR: coverpoint trans.resp_error {
            bins no_error = {0};
            bins error = {1};
        }
        
        APB_ADDR_X_DIRECTION: cross APB_ADDR, APB_DIRECTION;
    endgroup
    
endclass : apb_monitor