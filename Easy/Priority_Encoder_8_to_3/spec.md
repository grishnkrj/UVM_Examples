# 8-to-3 Priority Encoder Specification

### Inputs

- **in [7:0]** - 8-bit input vector where priority is given to the highest bit position

### Outputs

- **out [2:0]** - 3-bit binary representation of the highest priority active bit position
- **valid** - Asserted (1) when at least one input bit is set to 1, otherwise deasserted (0)

## Priority Table

| Input Priority | Binary Value | Output |
|----------------|--------------|--------|
| Bit 7 (Highest)| 8'b1xxx_xxxx | 3'b111 |
| Bit 6          | 8'b01xx_xxxx | 3'b110 |
| Bit 5          | 8'b001x_xxxx | 3'b101 |
| Bit 4          | 8'b0001_xxxx | 3'b100 |
| Bit 3          | 8'b0000_1xxx | 3'b011 |
| Bit 2          | 8'b0000_01xx | 3'b010 |
| Bit 1          | 8'b0000_001x | 3'b001 |
| Bit 0 (Lowest) | 8'b0000_0001 | 3'b000 |
| No bits set    | 8'b0000_0000 | valid = 0 |

Note: 'x' represents a "don't care" value.

## Parameters

- **INPUT_WIDTH** - Width of the input vector (default: 8)
- **OUTPUT_WIDTH** - Width of the output vector (default: 3)

## UVM Verification Planning

### Transaction Level Modeling
- **Priority Encoder Transaction**: Define a transaction class with the following fields:
  - `input_vector`: Input bit vector to the encoder
  - `expected_output`: Expected encoded output
  - `expected_valid`: Expected valid flag state

### Verification Components
- **Driver**: Apply input patterns to the priority encoder
- **Monitor**: Track input and output signals
- **Sequencer**: Generate test patterns for different priority scenarios
- **Scoreboard**: 
  - Calculate expected outputs based on priority rules
  - Compare actual outputs with expected values
  - Verify valid flag operation

### Test Scenarios
1. **Basic Functionality Tests**:
   - Single bit asserted at each position
   - Multiple bits asserted with known priority
   - All bits asserted (should encode to highest priority)
   - No bits asserted (should have valid=0)

2. **Priority Verification Tests**:
   - All 256 possible input combinations
   - Focus on adjacent priority levels

3. **Specialized Input Patterns**:
   - Walking ones (single high bit moves from LSB to MSB)
   - Walking zeros (single low bit in a field of high bits)
   - Alternating patterns (10101010, etc.)

4. **Parameterization Tests**:
   - Different INPUT_WIDTH and OUTPUT_WIDTH combinations (if applicable)

### Functional Coverage Points
1. **Input Coverage**:
   - All input bits toggled
   - Each bit set as the highest priority bit
   - Multiple active bits in different positions
   - Zero, one, multiple, and all bits set

2. **Output Coverage**:
   - All output values generated
   - Valid flag toggled between 0 and 1

3. **Cross Coverage**:
   - Input patterns × output values
   - Adjacent priority levels (e.g., when bits 7 and 6 are both set, ensure output is for bit 7)

### Assertion Plan
1. **Functional Assertions**:
   - When any input bit is set, valid should be asserted (1)
   - When no input bits are set, valid should be deasserted (0)
   - Output should always match the position of the highest priority bit set
   - If multiple bits are set, the highest numbered bit should determine the output

2. **Parameterization Assertions**:
   - Output bit width should match OUTPUT_WIDTH parameter
   - Input handling should match INPUT_WIDTH parameter

### Recommended UVM Test Structure
- Base test for common priority encoding operations
- Directed tests for each priority level
- Random tests with constrained inputs
- Exhaustive test for all 256 possible input combinations
