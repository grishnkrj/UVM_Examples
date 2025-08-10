# UART Receiver (UART_RX) Specification

## Overview
This document specifies a mid-level complexity UART Receiver (UART_RX) module for UVM verification practice. The design supports configurable data width, parity, stop bits, baud rate, and error detection features.

## Features
- Configurable data width (`DATA_WIDTH`)
- Configurable parity: none, even, or odd (`PARITY`)
- Configurable stop bits: 1 or 2 (`STOP_BITS`)
- Configurable baud rate via clock divider (`BAUD_DIV`)
- Parity error detection
- Framing error detection
- Overrun error detection
- Synchronous operation

## Ports
| Name         | Direction | Width                | Description                                 |
|--------------|----------|----------------------|---------------------------------------------|
| clk          | input    | 1                    | System clock                                |
| rst_n        | input    | 1                    | Active-low synchronous reset                |
| rx           | input    | 1                    | Serial data input                           |
| data_out     | output   | DATA_WIDTH           | Received parallel data                      |
| data_valid   | output   | 1                    | Data valid strobe (1 clk pulse)             |
| parity_error | output   | 1                    | Parity error detected                       |
| framing_error| output   | 1                    | Framing error detected                      |
| overrun_error| output   | 1                    | Overrun error detected                      |

## Functional Description
- **Reception:**
  - Detects start bit (falling edge on `rx`).
  - Samples data bits at the center of each bit period (baud rate defined by `BAUD_DIV`).
  - Supports 7/8/9-bit data (parameterizable).
  - Optional parity bit (none, even, odd).
  - 1 or 2 stop bits.
- **Error Detection:**
  - Parity error: Set if received parity does not match calculated parity.
  - Framing error: Set if stop bit(s) not high.
  - Overrun error: Set if new data arrives before previous data is read.
- **Data Output:**
  - `data_out` holds received data when `data_valid` is high.
  - `data_valid` is asserted for one clock when new data is available.

## Verification Requirements
- Parameterize tests for different `DATA_WIDTH`, `PARITY`, `STOP_BITS`, and `BAUD_DIV` values.
- Verify correct data reception for all configurations.
- Verify detection of parity, framing, and overrun errors.
- Test operation at minimum and maximum baud rates.
- Test back-to-back frame reception and overrun conditions.
- Test reset behavior during reception.
- Test data_valid strobe and data output timing.

## UVM Verification Planning

### Transaction Level Modeling
- **Serial Bit Transaction**: Define a transaction class representing a UART frame with:
  - `data_bits`: Received data bits
  - `parity_bit`: Received parity bit (if enabled)
  - `stop_bits`: Received stop bits (1 or 2)
  - `expected_data`: Expected data to be received
  - `expected_errors`: Expected error flags (parity, framing, overrun)

### Verification Components
- **Driver**: Generate serial bit stream on rx line with programmable baud rate
- **Monitor**:
  - Input monitor: Track rx line state changes
  - Output monitor: Capture received data and error flags
- **Sequencer**: Control serial data pattern generation
- **Scoreboard**:
  - Check received data against expected data
  - Verify error flag assertions
  - Track reception timing

### Test Scenarios
1. **Basic Functionality Tests**:
   - Normal reception with various data values
   - Verify reception with different data widths (7-9 bits)
   - Test all parity modes (none, even, odd)
   - Test stop bit configurations (1 and 2 bits)

2. **Baud Rate Tests**:
   - Test various baud rate divider values
   - Test minimum and maximum supported baud rates
   - Test non-standard baud rates

3. **Error Detection Tests**:
   - Parity error scenarios (inject wrong parity)
   - Framing error scenarios (incorrect stop bits)
   - Overrun error scenarios (back-to-back frames without reading)

4. **Timing Tests**:
   - Start bit detection at various offsets within baud period
   - Sample timing across bit periods
   - Clock frequency drift effects

5. **Special Cases**:
   - False start bit (glitch on rx line)
   - Noise injection on rx line
   - Metastability handling

### Functional Coverage Points
1. **Configuration Coverage**:
   - DATA_WIDTH parameter values (7-9)
   - PARITY parameter values (0, 1, 2)
   - STOP_BITS parameter values (1, 2)
   - BAUD_DIV parameter coverage

2. **Data Value Coverage**:
   - All bit patterns in received data
   - Special patterns (all 0s, all 1s, alternating, etc.)
   - Maximum and minimum data values

3. **State Machine Coverage**:
   - All state transitions reached
   - All states reached
   - Time spent in each state

4. **Error Condition Coverage**:
   - Parity error detection
   - Framing error detection
   - Overrun error detection
   - Multiple error conditions

5. **Cross Coverage**:
   - Data patterns × Parity settings
   - Error conditions × Baud rate
   - Error conditions × DATA_WIDTH

### Assertion Plan
1. **Protocol Assertions**:
   - After start bit, data bits should follow at correct baud intervals
   - Parity bit (if enabled) should follow data bits
   - Stop bit(s) should follow parity bit or data bits
   - data_valid should be asserted for exactly one clock cycle

2. **Error Flag Assertions**:
   - parity_error should be asserted only when a parity mismatch occurs
   - framing_error should be asserted only when stop bits are not high
   - overrun_error should be asserted when data_valid is already high and new data arrives

3. **Temporal Assertions**:
   - After reset, module should return to IDLE state
   - From IDLE, falling edge on rx should trigger START state
   - False start bit should return to IDLE without asserting data_valid

### Recommended UVM Test Structure
- Base test with common UART_rx configurations
- Derived tests for each error scenario and specific data patterns
- Factory overrides for parameter variations
- Sequences for different frame patterns and error injection
- Virtual sequences for complex multi-frame scenarios
- Coverage-driven tests with specific corner cases

## Notes
- All operations are synchronous to `clk`.
- No flow control or break detection is implemented.
- Parity calculation: even = XOR of all data bits is 0, odd = XOR is 1.
