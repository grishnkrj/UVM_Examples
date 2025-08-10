/**
 * Advanced SPI Controller
 * 
 * Features:
 * - APB3 slave interface for register access
 * - Configurable SPI modes (0,1,2,3)
 * - Programmable clock divider
 * - Multiple chip select lines
 * - FIFO-based TX and RX buffers
 * - Interrupt generation
 * - DMA support
 * - Configurable data width (4-32 bits)
 * - Master mode operation
 * 
 * Author: Training Example
 * Version: 1.0
 * Date: 2025-08-10
 */

module advanced_spi_controller #(
    parameter int APB_ADDR_WIDTH = 12,       // APB address width
    parameter int APB_DATA_WIDTH = 32,       // APB data width
    parameter int SPI_DATA_MAX_WIDTH = 32,   // Maximum SPI data width
    parameter int FIFO_DEPTH = 16,           // TX/RX FIFO depth
    parameter int CS_WIDTH = 4               // Number of chip select lines
) (
    // Clock and reset
    input  logic                      clk,               // System clock
    input  logic                      rst_n,             // Active low reset
    
    // APB3 slave interface
    input  logic                      apb_psel,          // APB select
    input  logic                      apb_penable,       // APB enable
    input  logic                      apb_pwrite,        // APB write enable
    input  logic [APB_ADDR_WIDTH-1:0] apb_paddr,         // APB address
    input  logic [APB_DATA_WIDTH-1:0] apb_pwdata,        // APB write data
    output logic [APB_DATA_WIDTH-1:0] apb_prdata,        // APB read data
    output logic                      apb_pready,        // APB ready
    output logic                      apb_pslverr,       // APB slave error
    
    // SPI interface
    output logic                      spi_clk,           // SPI clock
    output logic [CS_WIDTH-1:0]       spi_cs_n,          // SPI chip select (active low)
    output logic                      spi_mosi,          // SPI master out slave in
    input  logic                      spi_miso,          // SPI master in slave out
    
    // Interrupt and DMA
    output logic                      irq,               // Interrupt request
    output logic                      dma_tx_req,        // DMA TX request
    output logic                      dma_rx_req,        // DMA RX request
    input  logic                      dma_tx_ack,        // DMA TX acknowledge
    input  logic                      dma_rx_ack         // DMA RX acknowledge
);

    //----------------------------------------
    // Internal registers and signals
    //----------------------------------------
    
    // Register map offsets
    localparam CTRL_REG      = 12'h000;  // Control register
    localparam STATUS_REG    = 12'h004;  // Status register
    localparam CLK_DIV_REG   = 12'h008;  // Clock divider register
    localparam CS_REG        = 12'h00C;  // Chip select register
    localparam DATA_FMT_REG  = 12'h010;  // Data format register
    localparam TX_DATA_REG   = 12'h014;  // TX data register
    localparam RX_DATA_REG   = 12'h018;  // RX data register
    localparam INTR_EN_REG   = 12'h01C;  // Interrupt enable register
    localparam INTR_STAT_REG = 12'h020;  // Interrupt status register
    localparam DMA_CTRL_REG  = 12'h024;  // DMA control register
    localparam TX_FIFO_LVL   = 12'h028;  // TX FIFO level register
    localparam RX_FIFO_LVL   = 12'h02C;  // RX FIFO level register
    
    // Control register bits
    typedef struct packed {
        logic       enable;            // SPI enable
        logic       master;            // 1: master mode, 0: slave mode
        logic [1:0] spi_mode;          // SPI mode (0-3)
        logic       tx_fifo_rst;       // TX FIFO reset
        logic       rx_fifo_rst;       // RX FIFO reset
        logic       lsb_first;         // LSB first transfer
        logic [2:0] reserved;          // Reserved
        logic [7:0] tx_watermark;      // TX FIFO watermark
        logic [7:0] rx_watermark;      // RX FIFO watermark
        logic [7:0] reserved2;         // Reserved
    } ctrl_reg_t;
    
    // Status register bits
    typedef struct packed {
        logic       busy;              // SPI busy flag
        logic       tx_full;           // TX FIFO full
        logic       tx_empty;          // TX FIFO empty
        logic       rx_full;           // RX FIFO full
        logic       rx_empty;          // RX FIFO empty
        logic       tx_watermark_hit;  // TX FIFO watermark hit
        logic       rx_watermark_hit;  // RX FIFO watermark hit
        logic [25:0] reserved;         // Reserved
    } status_reg_t;
    
    // Data format register bits
    typedef struct packed {
        logic [4:0] data_len;          // Data length (4-32 bits)
        logic       reserved;          // Reserved
        logic       cs_hold;           // Hold chip select between transfers
        logic       reserved2;         // Reserved
        logic [23:0] reserved3;        // Reserved
    } data_fmt_reg_t;
    
    // Interrupt enable register bits
    typedef struct packed {
        logic       tx_empty_en;       // TX FIFO empty interrupt enable
        logic       tx_watermark_en;   // TX FIFO watermark interrupt enable
        logic       rx_full_en;        // RX FIFO full interrupt enable
        logic       rx_watermark_en;   // RX FIFO watermark interrupt enable
        logic       spi_idle_en;       // SPI idle interrupt enable
        logic [26:0] reserved;         // Reserved
    } intr_en_reg_t;
    
    // Interrupt status register bits - same structure as enable but for status
    typedef struct packed {
        logic       tx_empty_st;       // TX FIFO empty interrupt status
        logic       tx_watermark_st;   // TX FIFO watermark interrupt status
        logic       rx_full_st;        // RX FIFO full interrupt status
        logic       rx_watermark_st;   // RX FIFO watermark interrupt status
        logic       spi_idle_st;       // SPI idle interrupt status
        logic [26:0] reserved;         // Reserved
    } intr_status_reg_t;
    
    // DMA control register bits
    typedef struct packed {
        logic       tx_dma_en;         // TX DMA enable
        logic       rx_dma_en;         // RX DMA enable
        logic [29:0] reserved;         // Reserved
    } dma_ctrl_reg_t;
    
    // Register instances
    ctrl_reg_t        ctrl_reg;
    status_reg_t      status_reg;
    logic [31:0]      clk_div_reg;
    logic [CS_WIDTH-1:0] cs_reg;
    data_fmt_reg_t    data_fmt_reg;
    intr_en_reg_t     intr_en_reg;
    intr_status_reg_t intr_status_reg;
    dma_ctrl_reg_t    dma_ctrl_reg;
    
    // FIFOs
    logic [SPI_DATA_MAX_WIDTH-1:0] tx_fifo [FIFO_DEPTH-1:0];
    logic [SPI_DATA_MAX_WIDTH-1:0] rx_fifo [FIFO_DEPTH-1:0];
    logic [$clog2(FIFO_DEPTH):0] tx_fifo_count;
    logic [$clog2(FIFO_DEPTH):0] rx_fifo_count;
    logic [$clog2(FIFO_DEPTH)-1:0] tx_rd_ptr;
    logic [$clog2(FIFO_DEPTH)-1:0] tx_wr_ptr;
    logic [$clog2(FIFO_DEPTH)-1:0] rx_rd_ptr;
    logic [$clog2(FIFO_DEPTH)-1:0] rx_wr_ptr;
    
    // SPI clock divider
    logic [31:0] spi_clk_counter;
    logic spi_clk_internal;
    
    // SPI shift registers
    logic [SPI_DATA_MAX_WIDTH-1:0] tx_shift_reg;
    logic [SPI_DATA_MAX_WIDTH-1:0] rx_shift_reg;
    logic [$clog2(SPI_DATA_MAX_WIDTH):0] bit_counter;
    
    // State machine
    typedef enum logic [2:0] {
        IDLE, LOAD, TRANSFER, CS_WAIT, COMPLETE
    } spi_state_t;
    spi_state_t current_state, next_state;
    
    // Convenience signals
    logic apb_write_valid;
    logic apb_read_valid;
    logic tx_pop;
    logic rx_push;
    logic transfer_complete;
    logic transfer_active;
    logic [4:0] current_data_len;
    logic [1:0] current_spi_mode;
    
    //----------------------------------------
    // APB Interface Logic
    //----------------------------------------
    
    // APB write/read validation
    assign apb_write_valid = apb_psel && apb_penable && apb_pwrite;
    assign apb_read_valid = apb_psel && apb_penable && !apb_pwrite;
    
    // APB write handler
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers to default values
            ctrl_reg <= '0;
            ctrl_reg.master <= 1'b1; // Default to master mode
            clk_div_reg <= 32'd10;   // Default clock divider
            cs_reg <= '1;            // All CS lines high (inactive)
            data_fmt_reg <= '0;
            data_fmt_reg.data_len <= 5'd8; // Default to 8-bit data
            intr_en_reg <= '0;
            dma_ctrl_reg <= '0;
        end
        else if (apb_write_valid) begin
            case (apb_paddr)
                CTRL_REG: begin
                    ctrl_reg <= apb_pwdata;
                    // Handle TX/RX FIFO reset
                    if (apb_pwdata[4]) begin // tx_fifo_rst
                        tx_rd_ptr <= '0;
                        tx_wr_ptr <= '0;
                        tx_fifo_count <= '0;
                    end
                    if (apb_pwdata[5]) begin // rx_fifo_rst
                        rx_rd_ptr <= '0;
                        rx_wr_ptr <= '0;
                        rx_fifo_count <= '0;
                    end
                end
                CLK_DIV_REG: clk_div_reg <= apb_pwdata;
                CS_REG: cs_reg <= apb_pwdata[CS_WIDTH-1:0];
                DATA_FMT_REG: data_fmt_reg <= apb_pwdata;
                TX_DATA_REG: begin
                    // Write to TX FIFO if not full
                    if (!status_reg.tx_full) begin
                        tx_fifo[tx_wr_ptr] <= apb_pwdata[SPI_DATA_MAX_WIDTH-1:0];
                        tx_wr_ptr <= tx_wr_ptr + 1'b1;
                        tx_fifo_count <= tx_fifo_count + 1'b1;
                    end
                end
                INTR_EN_REG: intr_en_reg <= apb_pwdata;
                INTR_STAT_REG: intr_status_reg <= intr_status_reg & ~apb_pwdata; // Clear on write-1
                DMA_CTRL_REG: dma_ctrl_reg <= apb_pwdata;
                default: ; // Do nothing for unrecognized addresses
            endcase
        end
    end
    
    // Update status register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_reg <= '0;
            status_reg.tx_empty <= 1'b1;
            status_reg.rx_empty <= 1'b1;
        end
        else begin
            // Update FIFO status flags
            status_reg.tx_full <= (tx_fifo_count == FIFO_DEPTH);
            status_reg.tx_empty <= (tx_fifo_count == 0);
            status_reg.rx_full <= (rx_fifo_count == FIFO_DEPTH);
            status_reg.rx_empty <= (rx_fifo_count == 0);
            
            // Update watermark flags
            status_reg.tx_watermark_hit <= (tx_fifo_count <= ctrl_reg.tx_watermark);
            status_reg.rx_watermark_hit <= (rx_fifo_count >= ctrl_reg.rx_watermark);
            
            // Update busy flag
            status_reg.busy <= transfer_active;
        end
    end
    
    // APB read handler
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            apb_prdata <= '0;
            apb_pready <= 1'b0;
            apb_pslverr <= 1'b0;
        end
        else begin
            // Default ready and no error
            apb_pready <= apb_psel;
            apb_pslverr <= 1'b0;
            
            if (apb_read_valid) begin
                case (apb_paddr)
                    CTRL_REG: apb_prdata <= ctrl_reg;
                    STATUS_REG: apb_prdata <= status_reg;
                    CLK_DIV_REG: apb_prdata <= clk_div_reg;
                    CS_REG: apb_prdata <= {{(APB_DATA_WIDTH-CS_WIDTH){1'b0}}, cs_reg};
                    DATA_FMT_REG: apb_prdata <= data_fmt_reg;
                    RX_DATA_REG: begin
                        // Read from RX FIFO if not empty
                        if (!status_reg.rx_empty) begin
                            apb_prdata <= {{(APB_DATA_WIDTH-SPI_DATA_MAX_WIDTH){1'b0}}, rx_fifo[rx_rd_ptr]};
                            rx_rd_ptr <= rx_rd_ptr + 1'b1;
                            rx_fifo_count <= rx_fifo_count - 1'b1;
                        end
                        else begin
                            apb_prdata <= '0;
                        end
                    end
                    INTR_EN_REG: apb_prdata <= intr_en_reg;
                    INTR_STAT_REG: apb_prdata <= intr_status_reg;
                    DMA_CTRL_REG: apb_prdata <= dma_ctrl_reg;
                    TX_FIFO_LVL: apb_prdata <= {{(APB_DATA_WIDTH-$bits(tx_fifo_count)){1'b0}}, tx_fifo_count};
                    RX_FIFO_LVL: apb_prdata <= {{(APB_DATA_WIDTH-$bits(rx_fifo_count)){1'b0}}, rx_fifo_count};
                    default: begin
                        apb_prdata <= '0;
                        apb_pslverr <= 1'b1; // Error for invalid address
                    end
                endcase
            end
            else begin
                apb_prdata <= '0;
            end
        end
    end
    
    //----------------------------------------
    // SPI Clock Generation
    //----------------------------------------
    
    // Generate SPI clock based on clock divider
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_clk_counter <= '0;
            spi_clk_internal <= 1'b0;
        end
        else if (!ctrl_reg.enable) begin
            // Keep clock inactive when SPI is disabled
            spi_clk_counter <= '0;
            spi_clk_internal <= (current_spi_mode[1]) ? 1'b1 : 1'b0;
        end
        else if (transfer_active) begin
            // Clock generation during active transfer
            if (spi_clk_counter >= clk_div_reg - 1) begin
                spi_clk_counter <= '0;
                spi_clk_internal <= ~spi_clk_internal;
            end
            else begin
                spi_clk_counter <= spi_clk_counter + 1'b1;
            end
        end
        else begin
            // Idle state - no clock toggling
            spi_clk_counter <= '0;
            spi_clk_internal <= (current_spi_mode[1]) ? 1'b1 : 1'b0;
        end
    end
    
    // SPI clock output based on mode
    assign current_spi_mode = ctrl_reg.spi_mode;
    assign spi_clk = spi_clk_internal ^ current_spi_mode[1];
    
    //----------------------------------------
    // SPI State Machine
    //----------------------------------------
    
    // Current data length in bits
    assign current_data_len = data_fmt_reg.data_len;
    
    // State machine - sequential part
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            bit_counter <= '0;
        end
        else begin
            current_state <= next_state;
            
            // Bit counter for transfer
            if (current_state == LOAD) begin
                bit_counter <= '0;
            end
            else if (current_state == TRANSFER && !spi_clk_internal && spi_clk_counter == clk_div_reg - 1) begin
                bit_counter <= bit_counter + 1'b1;
            end
        end
    end
    
    // State machine - combinational part
    always_comb begin
        // Default next state and signals
        next_state = current_state;
        transfer_active = 1'b0;
        tx_pop = 1'b0;
        rx_push = 1'b0;
        transfer_complete = 1'b0;
        
        case (current_state)
            IDLE: begin
                if (ctrl_reg.enable && !status_reg.tx_empty) begin
                    next_state = LOAD;
                end
            end
            
            LOAD: begin
                next_state = TRANSFER;
                tx_pop = 1'b1; // Pop data from TX FIFO
            end
            
            TRANSFER: begin
                transfer_active = 1'b1;
                
                // Complete when all bits transferred
                if (bit_counter >= current_data_len) begin
                    next_state = CS_WAIT;
                    transfer_complete = 1'b1;
                    rx_push = 1'b1; // Push received data to RX FIFO
                end
            end
            
            CS_WAIT: begin
                // Wait state for CS timing if needed
                next_state = COMPLETE;
            end
            
            COMPLETE: begin
                // Check if we should start another transfer or go to idle
                if (ctrl_reg.enable && !status_reg.tx_empty && data_fmt_reg.cs_hold) begin
                    next_state = LOAD;
                end
                else begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
        
        // Override for SPI disable
        if (!ctrl_reg.enable) begin
            next_state = IDLE;
        end
    end
    
    // TX FIFO read control
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_rd_ptr <= '0;
            tx_shift_reg <= '0;
        end
        else if (tx_pop) begin
            tx_fifo_count <= tx_fifo_count - 1'b1;
            tx_rd_ptr <= tx_rd_ptr + 1'b1;
            tx_shift_reg <= tx_fifo[tx_rd_ptr];
        end
        else if (current_state == TRANSFER && !spi_clk_internal && spi_clk_counter == clk_div_reg - 1) begin
            // Shift out data bit by bit
            if (ctrl_reg.lsb_first) begin
                tx_shift_reg <= {1'b0, tx_shift_reg[SPI_DATA_MAX_WIDTH-1:1]};
            end
            else begin
                tx_shift_reg <= {tx_shift_reg[SPI_DATA_MAX_WIDTH-2:0], 1'b0};
            end
        end
    end
    
    // RX FIFO and shift register control
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_wr_ptr <= '0;
            rx_shift_reg <= '0;
        end
        else if (current_state == TRANSFER && spi_clk_internal && spi_clk_counter == clk_div_reg - 1) begin
            // Sample data on appropriate clock edge
            if (ctrl_reg.lsb_first) begin
                rx_shift_reg <= {spi_miso, rx_shift_reg[SPI_DATA_MAX_WIDTH-1:1]};
            end
            else begin
                rx_shift_reg <= {rx_shift_reg[SPI_DATA_MAX_WIDTH-2:0], spi_miso};
            end
        end
        else if (rx_push && rx_fifo_count < FIFO_DEPTH) begin
            rx_fifo[rx_wr_ptr] <= rx_shift_reg;
            rx_wr_ptr <= rx_wr_ptr + 1'b1;
            rx_fifo_count <= rx_fifo_count + 1'b1;
        end
    end
    
    // MOSI output logic - depends on transfer mode and direction
    always_comb begin
        if (ctrl_reg.lsb_first) begin
            spi_mosi = tx_shift_reg[0];
        end
        else begin
            spi_mosi = tx_shift_reg[SPI_DATA_MAX_WIDTH-1];
        end
    end
    
    // Chip select logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_cs_n <= '1; // All inactive
        end
        else if (!ctrl_reg.enable || current_state == IDLE) begin
            spi_cs_n <= '1; // All inactive when disabled or idle
        end
        else begin
            spi_cs_n <= ~cs_reg; // Active low, so invert
        end
    end
    
    //----------------------------------------
    // Interrupt Generation
    //----------------------------------------
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intr_status_reg <= '0;
            irq <= 1'b0;
        end
        else begin
            // Set interrupt status bits based on conditions
            intr_status_reg.tx_empty_st <= status_reg.tx_empty;
            intr_status_reg.tx_watermark_st <= status_reg.tx_watermark_hit;
            intr_status_reg.rx_full_st <= status_reg.rx_full;
            intr_status_reg.rx_watermark_st <= status_reg.rx_watermark_hit;
            intr_status_reg.spi_idle_st <= (current_state == IDLE);
            
            // Generate interrupt if any enabled status bit is set
            irq <= |(intr_status_reg & intr_en_reg);
        end
    end
    
    //----------------------------------------
    // DMA Control
    //----------------------------------------
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_tx_req <= 1'b0;
            dma_rx_req <= 1'b0;
        end
        else begin
            // TX DMA request when TX FIFO has space and DMA is enabled
            dma_tx_req <= dma_ctrl_reg.tx_dma_en && !status_reg.tx_full;
            
            // RX DMA request when RX FIFO has data and DMA is enabled
            dma_rx_req <= dma_ctrl_reg.rx_dma_en && !status_reg.rx_empty;
        end
    end
    
endmodule