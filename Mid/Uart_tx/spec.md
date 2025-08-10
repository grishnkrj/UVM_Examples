# UART Transmitter (uart_tx) Specification Sheet

## 1. Functional Overview

The **UART Transmitter** converts parallel data bytes into a serial bitstream according to the UART protocol format:  
`Start bit (0) → Data bits (LSB first) → Optional parity bit → Stop bit(s) (1)`.

---

## 2. Features

- Baud rate generation from system clock.
- Configurable data length: 7 or 8 bits.
- Configurable parity: None, Even, Odd.
- Configurable stop bits: 1 or 2.
- Single-byte transmit buffer (load new data only when ready).
- Status signals for `busy` and `tx_done`.

---

## 3. Interface Specification

| Signal Name  | Dir  | Width | Description |
|--------------|------|-------|-------------|
| `clk`        | In   | 1     | System clock |
| `rst_n`      | In   | 1     | Active-low synchronous reset |
| `data_in`    | In   | 8     | Parallel input data |
| `data_len`   | In   | 1     | 0 = 7-bit data, 1 = 8-bit data |
| `parity_en`  | In   | 1     | 1 = Enable parity, 0 = No parity |
| `parity_type`| In   | 1     | 0 = Even parity, 1 = Odd parity |
| `stop_bits`  | In   | 1     | 0 = 1 stop bit, 1 = 2 stop bits |
| `baud_div`   | In   | 16    | Clock divider value for baud rate generation |
| `tx_start`   | In   | 1     | Pulse high to start transmission when idle |
| `tx_line`    | Out  | 1     | Serial TX output line |
| `tx_busy`    | Out  | 1     | 1 when transmitting |
| `tx_done`    | Out  | 1     | 1 for 1 cycle after transmission completes |

---

## 4. UART Frame Format

- **Start bit:** Always `0`.
- **Data bits:** Sent LSB first, length = `7` or `8` bits.
- **Parity bit:** Sent if `parity_en = 1`.
  - Even parity: Total number of 1s in data + parity = even.
  - Odd parity: Total number of 1s in data + parity = odd.
- **Stop bit(s):** Always `1`, length = 1 or 2 bits depending on `stop_bits`.

---

## 5. Operation

1. **Idle State:** `tx_line = 1`, `tx_busy = 0`.
2. When `tx_start = 1` and `tx_busy = 0`:
   - Load `data_in` and config parameters.
   - Send start bit first.
   - Shift out data bits LSB first.
   - If parity enabled, compute and send parity bit.
   - Send stop bits.
3. Assert `tx_done` for 1 cycle at the end.
4. Return to idle.

---

## 6. Timing Diagram Example

**Example:** 8-bit data, even parity, 1 stop bit, `baud_div = 4`

```
clk:   _|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_
tx:    1 | 0 |D0 |D1 |D2 |D3 |D4 |D5 |D6 |D7 | P | 1 | 1
             ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^   ^
            Idle|Strt|<---- Data Bits (LSB first) --->|Par|Stp|Idle
```

---

## 7. Verification Notes

- **Randomizable Inputs:** `data_in`, `data_len`, `parity_en`, `parity_type`, `stop_bits`, `baud_div`.
- **Functional Coverage Points:**
  - Data length = {7, 8}
  - Parity type = {None, Even, Odd}
  - Stop bits = {1, 2}
  - Baud divider variations
- **Corner Cases:**
  - Change configuration mid-simulation
  - Back-to-back `tx_start` pulses
  - Minimum and maximum baud rates
  - Invalid parity scenarios

---

## 8. UVM Verification Planning

### Transaction Level Modeling
- **UART TX Transaction**: Define a transaction class with the following fields:
  - `data_in`: Data to transmit (8 bits)
  - `data_len`: Data length configuration (7/8 bits)
  - `parity_en`: Parity enable flag
  - `parity_type`: Parity type (even/odd)
  - `stop_bits`: Stop bits configuration (1/2 bits)
  - `baud_div`: Baud rate divider value
  - `expected_serial_pattern`: Expected bit sequence on tx_line

### Verification Components
- **Driver**: Generate control signals to the UART TX DUT
- **Monitor**:
  - Control Monitor: Track input signals and configuration changes
  - Serial Monitor: Observe and sample tx_line at intervals determined by baud rate
- **Sequencer**: Control transaction generation for various transmission scenarios
- **Scoreboard**: 
  - Calculate expected serial bit patterns based on configurations
  - Compare actual tx_line pattern against expected bit sequence
  - Verify timing of tx_busy and tx_done signals

### Test Scenarios
1. **Basic Functionality Tests**:
   - Transmission with various data values
   - Test both 7-bit and 8-bit data lengths
   - Test with and without parity
   - Test both parity types (even/odd)
   - Test both stop bit configurations (1/2)

2. **Configuration Transition Tests**:
   - Change configuration parameters between transmissions
   - Verify proper handling of configuration updates
   - Test extreme baud rate divider values

3. **Protocol Timing Tests**:
   - Verify timing between start, data, parity, and stop bits
   - Confirm tx_busy assertion throughout transmission
   - Verify tx_done pulse at completion

4. **Back-to-Back Tests**:
   - Multiple consecutive transmissions
   - tx_start assertion while tx_busy is high
   - Minimum delay between transmissions

5. **Error and Corner Cases**:
   - Reset during transmission
   - Invalid configuration combinations
   - Maximum and minimum values for all configuration parameters

### Functional Coverage Points
1. **Configuration Coverage**:
   - `data_len`: Both 7-bit and 8-bit modes
   - `parity_en`: Both enabled and disabled states
   - `parity_type`: Both even and odd parity
   - `stop_bits`: Both 1 and 2 stop bit modes
   - `baud_div`: Various values covering operational range

2. **Data Value Coverage**:
   - All bit patterns in `data_in`
   - Special patterns (all 0s, all 1s, alternating, etc.)
   - 7-bit mode with MSB variations

3. **State Machine Coverage**:
   - All states reached
   - All valid state transitions
   - Time spent in each state

4. **Protocol Coverage**:
   - Start bit transitions
   - Stop bit transitions
   - Parity bit generation for both types
   - Idle-to-Start transitions
   - All combinations of configuration parameters

5. **Cross Coverage**:
   - `data_in` patterns × `parity_type`
   - `data_len` × `parity_en` × `stop_bits`
   - `baud_div` × transmission mode combinations

### Assertion Plan
1. **Protocol Assertions**:
   - Idle state should have tx_line high
   - Start bit should always be low
   - Stop bit(s) should always be high
   - Parity bit should match calculated parity when enabled
   - tx_busy should remain high from tx_start until the last bit is transmitted
   - tx_done should pulse for exactly one clock cycle

2. **Timing Assertions**:
   - Bit period should match configured baud_div
   - tx_busy should assert within one clock of tx_start
   - tx_done should assert after the last stop bit

3. **Functional Assertions**:
   - After reset, module should return to IDLE state with tx_line high
   - Correct number of data bits should be transmitted based on data_len
   - Correct number of stop bits should be transmitted based on stop_bits

### Recommended UVM Test Structure
- Base test with common UART TX configurations
- Extended tests for specific protocol features
- Directed tests for corner cases and error conditions
- Random tests with constraints for valid configurations
- Virtual sequences for complex transmission scenarios
- Coverage-driven tests focusing on configuration combinations
