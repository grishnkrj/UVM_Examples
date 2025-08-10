/**
 * SPI Controller Testbench Top
 * 
 * This is the top-level module for the SPI Controller testbench.
 * It instantiates the DUT, interfaces, and starts the UVM test.
 */
module spi_controller_tb_top;
    // Import UVM and testbench packages
    import uvm_pkg::*;
    import spi_controller_pkg::*;
    
    // Clock and reset signals
    logic clk;
    logic rst_n;
    
    // Generate clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Reset sequence
    initial begin
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
    end
    
    // Interfaces
    apb_if apb_if_inst(.clk(clk), .rst_n(rst_n));
    spi_if spi_if_inst(.clk(clk), .rst_n(rst_n));
    
    // Instantiate DUT
    advanced_spi_controller #(
        .APB_ADDR_WIDTH(12),
        .APB_DATA_WIDTH(32),
        .SPI_DATA_MAX_WIDTH(32),
        .FIFO_DEPTH(16),
        .CS_WIDTH(4)
    ) dut (
        // APB interface signals
        .clk(clk),                   // Changed from pclk
        .rst_n(rst_n),               // Changed from presetn
        .apb_psel(apb_if_inst.psel),
        .apb_penable(apb_if_inst.penable),
        .apb_pwrite(apb_if_inst.pwrite),
        .apb_paddr(apb_if_inst.paddr),
        .apb_pwdata(apb_if_inst.pwdata),
        .apb_prdata(apb_if_inst.prdata),
        .apb_pready(apb_if_inst.pready),
        .apb_pslverr(apb_if_inst.pslverr),
        
        // SPI interface signals
        .spi_clk(spi_if_inst.sclk),
        .spi_cs_n(spi_if_inst.cs_n),
        .spi_mosi(spi_if_inst.mosi),
        .spi_miso(spi_if_inst.miso),
        
        // Interrupt and DMA
        .irq(spi_if_inst.spi_irq),
        .dma_tx_req(),               // Not connected in testbench
        .dma_rx_req(),               // Not connected in testbench
        .dma_tx_ack(1'b0),           // Tied to inactive
        .dma_rx_ack(1'b0)            // Tied to inactive
    );
    
    // Drive MISO from outside (slave response)
    // In a real system, this would be driven by an external SPI slave
    // For testing, we'll generate random data
    initial begin
        spi_if_inst.miso = 1'b0;
        forever begin
            @(negedge spi_if_inst.sclk);
            if (!spi_if_inst.cs_n[0]) begin
                spi_if_inst.miso = $random;
            end
        end
    end
    
    // Start UVM test
    initial begin
        // Set virtual interfaces in config_db
        uvm_config_db#(virtual apb_if)::set(null, "*", "vif", apb_if_inst);
        uvm_config_db#(virtual spi_if)::set(null, "*", "vif", spi_if_inst);
        
        // Start test - default is basic test if not specified
        run_test("spi_basic_test");
    end
    
    // Dump waves (when running with simulator that supports it)
    initial begin
        $dumpfile("spi_controller_tb.vcd");
        $dumpvars(0, spi_controller_tb_top);
    end
    
    // Timeout watchdog
    initial begin
        #1000000; // 1ms timeout
        `uvm_fatal("TB_TOP", "Simulation timed out")
    end
    
endmodule