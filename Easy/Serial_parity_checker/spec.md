# Serial Parity Checker

## Specifications

**Function:** Takes an 8-bit data word and a parity bit, checks whether the parity matches the selected parity type (even/odd).

### Inputs:
- **data_in** (8-bit) — Data byte to check
- **parity_bit** (1-bit) — Received parity bit
- **parity_type** (1-bit) — 0 for even parity, 1 for odd parity

### Output:
- **parity_error** (1-bit) — 1 if parity is incorrect, else 0

### Operation:
- **For even parity:** The total number of 1s in {data_in, parity_bit} should be even
- **For odd parity:** The total number of 1s in {data_in, parity_bit} should be odd

### Implementation:
- Clock/Reset: Not needed — purely combinational design

### Parameters:
- **DATA_WIDTH** (int) — Width of data input (default: 8 bits)

## UVM Verification Planning

### Transaction Level Modeling
- **Parity Check Transaction**: Define a transaction class with the following fields:
  - `data_in`: Data byte to check
  - `parity_bit`: Received parity bit
  - `parity_type`: Parity type selection (even/odd)
  - `expected_error`: Expected parity error flag

### Verification Components
- **Driver**: Apply test patterns to the parity checker
- **Monitor**: Track input values and error output signal
- **Sequencer**: Generate various data and parity combinations
- **Scoreboard**: 
  - Calculate expected parity error based on inputs
  - Compare actual error output with expected error

### Test Scenarios
1. **Basic Functionality Tests**:
   - Even parity with correct parity bit (no error)
   - Even parity with incorrect parity bit (error)
   - Odd parity with correct parity bit (no error)
   - Odd parity with incorrect parity bit (error)

2. **Data Pattern Tests**:
   - All zeros with both parity types
   - All ones with both parity types
   - Alternating patterns (10101010, 01010101)
   - Single bit set in different positions
   - Walking ones pattern (00000001, 00000010, 00000100, etc.)

3. **Corner Cases**:
   - Boundary transitions between error and no error
   - Toggling parity_type with same data and parity bit

4. **Parameterization Tests**:
   - Different DATA_WIDTH values (e.g., 4, 8, 16 bits)

### Functional Coverage Points
1. **Input Coverage**:
   - Data patterns: all zeros, all ones, alternating bits
   - Each bit in data_in toggled
   - Parity bit values (0, 1)
   - Parity type values (even, odd)

2. **Output Coverage**:
   - Parity error asserted and deasserted
   - Transitions between error and no error

3. **Cross Coverage**:
   - Parity type × parity bit × parity error
   - Data patterns × parity bit × parity type
   - Number of 1's in data_in × parity bit × parity type

### Assertion Plan
1. **Functional Assertions**:
   - For even parity: error should be 0 when total 1's count is even
   - For even parity: error should be 1 when total 1's count is odd
   - For odd parity: error should be 0 when total 1's count is odd
   - For odd parity: error should be 1 when total 1's count is even

2. **Parameterization Assertions**:
   - DATA_WIDTH parameter should correctly determine the width of data_in

### Recommended UVM Test Structure
- Base test with common parity check operations
- Directed tests for specific data patterns
- Random tests with constrained inputs
- Parameter variation tests

