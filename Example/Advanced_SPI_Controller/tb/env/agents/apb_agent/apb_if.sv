/**
 * APB Interface Definition for Advanced SPI Controller UVM testbench
 * 
 * This interface encapsulates APB bus signals and provides clocking blocks
 * for both driver and monitor components.
 *
 * Features:
 * - Parameterizable address and data width
 * - Driver clocking block for driving APB signals
 * - Monitor clocking block for sampling APB signals
 * - Protocol assertions for APB protocol checking
 */
interface apb_if #(
    parameter int APB_ADDR_WIDTH = 12,
    parameter int APB_DATA_WIDTH = 32
) (
    input logic clk,
    input logic rst_n
);
    // APB signals
    logic                       psel;
    logic                       penable;
    logic                       pwrite;
    logic [APB_ADDR_WIDTH-1:0]  paddr;
    logic [APB_DATA_WIDTH-1:0]  pwdata;
    logic [APB_DATA_WIDTH-1:0]  prdata;
    logic                       pready;
    logic                       pslverr;
    
    // Driver clocking block
    clocking drv_cb @(posedge clk);
        output psel, penable, pwrite, paddr, pwdata;
        input prdata, pready, pslverr;
    endclocking
    
    // Monitor clocking block
    clocking mon_cb @(posedge clk);
        input psel, penable, pwrite, paddr, pwdata, prdata, pready, pslverr;
    endclocking
    
    // Modports for driver and monitor
    modport driver (
        clocking drv_cb,
        input clk, rst_n
    );
    
    modport monitor (
        clocking mon_cb,
        input clk, rst_n
    );
    
    // APB protocol assertions
    // These assertions validate proper APB bus behavior
    
    // Property: SETUP->ENABLE sequence must be followed
    property p_setup_enable_seq;
        @(posedge clk) disable iff(!rst_n)
        psel && !penable |=> psel && penable;
    endproperty
    assert_setup_enable_seq: assert property(p_setup_enable_seq)
        else $error("APB Protocol Violation: SETUP must be followed by ENABLE");
    
    // Property: Cannot deassert psel while waiting for pready
    property p_psel_stable;
        @(posedge clk) disable iff(!rst_n)
        (psel && penable && !pready) |=> (psel && penable);
    endproperty
    assert_psel_stable: assert property(p_psel_stable)
        else $error("APB Protocol Violation: PSEL deasserted while waiting for PREADY");
    
    // Property: After ENABLE, if not ready, remain in ENABLE
    property p_enable_stable;
        @(posedge clk) disable iff(!rst_n)
        (psel && penable && !pready) |=> (psel && penable);
    endproperty
    assert_enable_stable: assert property(p_enable_stable)
        else $error("APB Protocol Violation: PENABLE deasserted while waiting for PREADY");
    
    // Property: When transfer completes, return to IDLE or SETUP
    property p_transfer_complete;
        @(posedge clk) disable iff(!rst_n)
        (psel && penable && pready) |=> (!penable);
    endproperty
    assert_transfer_complete: assert property(p_transfer_complete)
        else $error("APB Protocol Violation: PENABLE remains high after transfer complete");
    
    // Helper tasks for direct usage at the interface level
    
    // Wait for reset to complete
    task wait_for_reset();
        @(posedge clk);
        while (!rst_n) @(posedge clk);
    endtask
    
    // Execute a single APB write transaction
    task write(input logic [APB_ADDR_WIDTH-1:0] addr, 
               input logic [APB_DATA_WIDTH-1:0] data);
        // SETUP phase
        @(drv_cb);
        drv_cb.psel <= 1'b1;
        drv_cb.penable <= 1'b0;
        drv_cb.pwrite <= 1'b1;
        drv_cb.paddr <= addr;
        drv_cb.pwdata <= data;
        
        // ACCESS phase
        @(drv_cb);
        drv_cb.penable <= 1'b1;
        
        // Wait for slave to be ready
        do begin
            @(drv_cb);
        end while (!pready);
        
        // Return to IDLE
        @(drv_cb);
        drv_cb.psel <= 1'b0;
        drv_cb.penable <= 1'b0;
    endtask
    
    // Execute a single APB read transaction
    task read(input logic [APB_ADDR_WIDTH-1:0] addr,
              output logic [APB_DATA_WIDTH-1:0] data);
        // SETUP phase
        @(drv_cb);
        drv_cb.psel <= 1'b1;
        drv_cb.penable <= 1'b0;
        drv_cb.pwrite <= 1'b0;
        drv_cb.paddr <= addr;
        
        // ACCESS phase
        @(drv_cb);
        drv_cb.penable <= 1'b1;
        
        // Wait for slave to be ready
        do begin
            @(drv_cb);
        end while (!pready);
        
        // Capture read data
        data = prdata;
        
        // Return to IDLE
        @(drv_cb);
        drv_cb.psel <= 1'b0;
        drv_cb.penable <= 1'b0;
    endtask

endinterface : apb_if