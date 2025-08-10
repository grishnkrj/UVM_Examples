# Advanced SPI Controller Specification

## Overview

The Advanced SPI Controller is a highly configurable Serial Peripheral Interface (SPI) module that connects to an APB3 bus for register access. It supports master mode operations with multiple configurable features suitable for a wide range of SPI device communications.

## Features

- APB3 slave interface for register configuration
- Master mode SPI operation
- Configurable SPI modes (0, 1, 2, 3)
- Programmable clock divider for flexible SPI clock rates
- Multiple chip select lines
- TX and RX FIFOs for efficient data transfer
- Interrupt generation for various events
- DMA support for high-speed data transfer
- Configurable data width (4-32 bits)
- LSB/MSB first data transfer support
- Chip select hold capability

## Interfaces

### APB3 Slave Interface

| Signal        | Direction | Width            | Description                     |
|---------------|-----------|------------------|---------------------------------|
| clk           | Input     | 1                | System clock                    |
| rst_n         | Input     | 1                | Active low reset                |
| apb_psel      | Input     | 1                | Peripheral select               |
| apb_penable   | Input     | 1                | Enable signal                   |
| apb_pwrite    | Input     | 1                | Write/read control (1=write)    |
| apb_paddr     | Input     | APB_ADDR_WIDTH   | Address bus                     |
| apb_pwdata    | Input     | APB_DATA_WIDTH   | Write data bus                  |
| apb_prdata    | Output    | APB_DATA_WIDTH   | Read data bus                   |
| apb_pready    | Output    | 1                | Ready signal                    |
| apb_pslverr   | Output    | 1                | Error signal                    |

### SPI Master Interface

| Signal        | Direction | Width            | Description                     |
|---------------|-----------|------------------|---------------------------------|
| spi_clk       | Output    | 1                | SPI clock                       |
| spi_cs_n      | Output    | CS_WIDTH         | Chip select lines (active low)  |
| spi_mosi      | Output    | 1                | Master out, slave in data line  |
| spi_miso      | Input     | 1                | Master in, slave out data line  |

### Interrupt and DMA Interface

| Signal        | Direction | Width            | Description                     |
|---------------|-----------|------------------|---------------------------------|
| irq           | Output    | 1                | Interrupt request               |
| dma_tx_req    | Output    | 1                | TX DMA request                  |
| dma_rx_req    | Output    | 1                | RX DMA request                  |
| dma_tx_ack    | Input     | 1                | TX DMA acknowledge              |
| dma_rx_ack    | Input     | 1                | RX DMA acknowledge              |

## Parameters

| Parameter         | Default Value | Description                           |
|-------------------|---------------|---------------------------------------|
| APB_ADDR_WIDTH    | 12            | Width of APB address bus              |
| APB_DATA_WIDTH    | 32            | Width of APB data bus                 |
| SPI_DATA_MAX_WIDTH| 32            | Maximum SPI data width                |
| FIFO_DEPTH        | 16            | Depth of TX/RX FIFOs                  |
| CS_WIDTH          | 4             | Number of chip select lines           |

## Register Map

### Control Register (CTRL_REG, Offset: 0x000)

| Bits    | Name          | Access | Reset Value | Description                     |
|---------|---------------|--------|-------------|---------------------------------|
| 0       | enable        | R/W    | 0           | SPI enable bit                  |
| 1       | master        | R/W    | 1           | Master mode (should be 1)       |
| 3:2     | spi_mode      | R/W    | 0           | SPI mode (0-3)                  |
| 4       | tx_fifo_rst   | W      | 0           | TX FIFO reset (write 1 to reset)|
| 5       | rx_fifo_rst   | W      | 0           | RX FIFO reset (write 1 to reset)|
| 6       | lsb_first     | R/W    | 0           | LSB first when 1, MSB when 0    |
| 9:7     | reserved      | R      | 0           | Reserved                        |
| 17:10   | tx_watermark  | R/W    | 0           | TX FIFO watermark level         |
| 25:18   | rx_watermark  | R/W    | 0           | RX FIFO watermark level         |
| 31:26   | reserved2     | R      | 0           | Reserved                        |

### Status Register (STATUS_REG, Offset: 0x004)

| Bits    | Name              | Access | Reset Value | Description                     |
|---------|-------------------|--------|-------------|---------------------------------|
| 0       | busy              | R      | 0           | SPI busy flag                   |
| 1       | tx_full           | R      | 0           | TX FIFO full                    |
| 2       | tx_empty          | R      | 1           | TX FIFO empty                   |
| 3       | rx_full           | R      | 0           | RX FIFO full                    |
| 4       | rx_empty          | R      | 1           | RX FIFO empty                   |
| 5       | tx_watermark_hit  | R      | 0           | TX FIFO watermark hit           |
| 6       | rx_watermark_hit  | R      | 0           | RX FIFO watermark hit           |
| 31:7    | reserved          | R      | 0           | Reserved                        |

### Clock Divider Register (CLK_DIV_REG, Offset: 0x008)

| Bits    | Name          | Access | Reset Value | Description                     |
|---------|---------------|--------|-------------|---------------------------------|
| 31:0    | clk_div       | R/W    | 10          | Clock divider value             |

### Chip Select Register (CS_REG, Offset: 0x00C)

| Bits            | Name          | Access | Reset Value | Description                     |
|-----------------|---------------|--------|-------------|---------------------------------|
| CS_WIDTH-1:0    | cs_reg        | R/W    | All 1s      | Chip select control (1=selected)|

### Data Format Register (DATA_FMT_REG, Offset: 0x010)

| Bits    | Name          | Access | Reset Value | Description                     |
|---------|---------------|--------|-------------|---------------------------------|
| 4:0     | data_len      | R/W    | 8           | Data length (4-32 bits)         |
| 5       | reserved      | R      | 0           | Reserved                        |
| 6       | cs_hold       | R/W    | 0           | Hold CS between transfers       |
| 31:7    | reserved2     | R      | 0           | Reserved                        |

### TX Data Register (TX_DATA_REG, Offset: 0x014)

| Bits                    | Name          | Access | Description                     |
|-------------------------|---------------|--------|---------------------------------|
| SPI_DATA_MAX_WIDTH-1:0  | tx_data       | W      | Data to transmit                |

### RX Data Register (RX_DATA_REG, Offset: 0x018)

| Bits                    | Name          | Access | Description                     |
|-------------------------|---------------|--------|---------------------------------|
| SPI_DATA_MAX_WIDTH-1:0  | rx_data       | R      | Received data                   |

### Interrupt Enable Register (INTR_EN_REG, Offset: 0x01C)

| Bits    | Name              | Access | Reset Value | Description                     |
|---------|-------------------|--------|-------------|---------------------------------|
| 0       | tx_empty_en       | R/W    | 0           | TX FIFO empty interrupt enable  |
| 1       | tx_watermark_en   | R/W    | 0           | TX watermark interrupt enable   |
| 2       | rx_full_en        | R/W    | 0           | RX FIFO full interrupt enable   |
| 3       | rx_watermark_en   | R/W    | 0           | RX watermark interrupt enable   |
| 4       | spi_idle_en       | R/W    | 0           | SPI idle interrupt enable       |
| 31:5    | reserved          | R      | 0           | Reserved                        |

### Interrupt Status Register (INTR_STAT_REG, Offset: 0x020)

| Bits    | Name              | Access | Reset Value | Description                     |
|---------|-------------------|--------|-------------|---------------------------------|
| 0       | tx_empty_st       | R/W1C  | 0           | TX FIFO empty interrupt status  |
| 1       | tx_watermark_st   | R/W1C  | 0           | TX watermark interrupt status   |
| 2       | rx_full_st        | R/W1C  | 0           | RX FIFO full interrupt status   |
| 3       | rx_watermark_st   | R/W1C  | 0           | RX watermark interrupt status   |
| 4       | spi_idle_st       | R/W1C  | 0           | SPI idle interrupt status       |
| 31:5    | reserved          | R      | 0           | Reserved                        |

### DMA Control Register (DMA_CTRL_REG, Offset: 0x024)

| Bits    | Name          | Access | Reset Value | Description                     |
|---------|---------------|--------|-------------|---------------------------------|
| 0       | tx_dma_en     | R/W    | 0           | TX DMA enable                   |
| 1       | rx_dma_en     | R/W    | 0           | RX DMA enable                   |
| 31:2    | reserved      | R      | 0           | Reserved                        |

### TX FIFO Level Register (TX_FIFO_LVL, Offset: 0x028)

| Bits    | Name          | Access | Description                     |
|---------|---------------|---------|---------------------------------|
| Log2(FIFO_DEPTH)+1:0 | tx_fifo_count | R    | Number of entries in TX FIFO    |

### RX FIFO Level Register (RX_FIFO_LVL, Offset: 0x02C)

| Bits    | Name          | Access | Description                     |
|---------|---------------|---------|---------------------------------|
| Log2(FIFO_DEPTH)+1:0 | rx_fifo_count | R    | Number of entries in RX FIFO    |

## Functional Description

### SPI Modes

The SPI controller supports all four standard SPI modes:

| Mode | CPOL | CPHA | Clock Idle State | Data Sampling Edge |
|------|------|------|-----------------|--------------------|
| 0    | 0    | 0    | Low             | Rising             |
| 1    | 0    | 1    | Low             | Falling            |
| 2    | 1    | 0    | High            | Falling            |
| 3    | 1    | 1    | High            | Rising             |

### Clock Generation

The SPI clock frequency is derived from the system clock using the programmable divider:
```
spi_clk_freq = system_clk_freq / (2 * clk_div_reg)
```

### Data Transfer

1. Software writes data to the TX FIFO via TX_DATA_REG
2. When the controller is enabled and TX FIFO has data, transmission begins
3. Data is transferred according to the configured SPI mode
4. Received data is stored in RX FIFO
5. Software reads data from RX FIFO via RX_DATA_REG

### Chip Select Control

- Each bit in the CS register controls one chip select line
- CS lines are active low
- CS can be held between transfers by setting cs_hold bit

### Interrupt Generation

Interrupts can be generated for the following events:
- TX FIFO empty
- TX FIFO watermark hit
- RX FIFO full
- RX FIFO watermark hit
- SPI idle

### DMA Operation

- TX DMA requests are generated when TX FIFO has space and TX DMA is enabled
- RX DMA requests are generated when RX FIFO has data and RX DMA is enabled

## Timing Diagrams

### SPI Mode 0 (CPOL=0, CPHA=0)
```
         ┌─┐   ┌─┐   ┌─┐   ┌─┐   ┌─┐   ┌─┐   ┌─┐   ┌─┐
CLK      │ │   │ │   │ │   │ │   │ │   │ │   │ │   │ │
       ──┘ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘ └───┘ └──
            ┌───────┐       ┌───────┐       ┌───────┐   
CS_n    ────┘       └───────┘       └───────┘       └───
            ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───
MOSI     ───┤D7 ├───┤D6 ├───┤D5 ├───┤D4 ├───┤D3 ├───┤D2 
            └───┘   └───┘   └───┘   └───┘   └───┘   └───
              ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌─
MISO     ─────┤D7 ├───┤D6 ├───┤D5 ├───┤D4 ├───┤D3 ├───┤D
              └───┘   └───┘   └───┘   └───┘   └───┘   └─
```

## Error Handling

- APB errors (apb_pslverr) are generated for invalid register accesses
- Writes to TX FIFO when full are ignored
- Reads from RX FIFO when empty return 0

## Power Management

- SPI clock is only generated during active transfers
- Controller can be disabled completely by clearing the enable bit

## Integration Guidelines

- Connect system clock to clk input
- Connect reset to rst_n input
- Connect APB bus signals to APB interface
- Connect SPI lines to appropriate devices
- Handle interrupt and DMA signals as required by the system