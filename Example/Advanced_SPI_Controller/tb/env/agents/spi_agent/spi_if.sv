/**
 * SPI Interface
 * 
 * This interface defines the signals for SPI communication and provides clocking blocks
 * for synchronizing driver and monitor activities.
 * 
 * Features:
 * - Support for 4-wire SPI protocol (SCLK, MOSI, MISO, CS)
 * - Multiple chip select support (up to 4)
 * - Clocking blocks for driver and monitor
 * - Helper tasks for bit-level operations
 */
interface spi_if (input logic clk, input logic rst_n);
    // SPI signals
    logic        sclk;     // Serial clock
    logic        mosi;     // Master Out Slave In
    logic        miso;     // Master In Slave Out
    logic [3:0]  cs_n;     // Chip select (active low, support for up to 4 devices)
    
    // Control signals
    logic        spi_idle; // Indicates the SPI bus is idle
    logic        spi_irq;  // SPI interrupt request signal
    
    // Define clocking blocks for synchronization
    // Driver clocking block
    clocking spi_drv_cb @(posedge clk);
        output sclk;
        output mosi;
        input  miso;
        output cs_n;
    endclocking
    
    // Monitor clocking block
    clocking spi_mon_cb @(posedge clk);
        input sclk;
        input mosi;
        input miso;
        input cs_n;
        input spi_irq;
    endclocking
    
    // Modport declarations
    modport DRIVER (
        clocking spi_drv_cb,
        input   rst_n,
        output  spi_idle,
        input   spi_irq
    );
    
    modport MONITOR (
        clocking spi_mon_cb,
        input   rst_n,
        input   spi_idle,
        input   spi_irq
    );
    
    // Helper tasks and functions
    
    // Drive a single SPI bit
    task drive_bit(
        input bit data_bit,      // Bit to send on MOSI
        input bit cpol,          // Clock polarity
        input bit cpha,          // Clock phase
        input int clk_period,    // Clock period in timeunits
        output bit received_bit  // Bit received on MISO
    );
        // Default idle state depends on CPOL
        sclk = cpol;
        
        // Half clock period
        int half_period = clk_period / 2;
        
        // First edge - may be sampling or shifting edge depending on CPHA
        if (cpha == 0) begin
            // In CPHA=0, first edge is for shifting out data
            mosi = data_bit;
            #half_period;
            sclk = ~sclk; // First clock edge
        end else begin
            // In CPHA=1, first edge is for sampling data
            #half_period;
            sclk = ~sclk; // First clock edge
            mosi = data_bit;
        end
        
        // Second edge - complementary to first edge
        #half_period;
        
        // Sample MISO on appropriate edge based on mode
        if (cpha == 0) begin
            // Sample on second edge for CPHA=0
            received_bit = miso;
        end else begin
            // Sample before second edge for CPHA=1
            received_bit = miso;
        end
        
        sclk = ~sclk; // Second clock edge
        
        // Return to idle state if needed
        if (sclk != cpol) begin
            #half_period;
            sclk = cpol;
        end
    endtask
    
    // Assert a specific chip select line
    task assert_cs(input int cs_index);
        cs_n = 4'b1111;       // All inactive
        cs_n[cs_index] = 0;   // Selected CS active low
    endtask
    
    // Deassert all chip selects
    task deassert_all_cs();
        cs_n = 4'b1111;       // All inactive
    endtask
    
    // Initial state for simulation
    initial begin
        sclk = 0;
        mosi = 0;
        miso = 0;
        cs_n = 4'b1111;  // All CS lines inactive
        spi_idle = 1;    // Initially idle
        spi_irq = 0;     // No interrupt initially
    end

endinterface : spi_if