# Mod-N Counter (Parameterized)

## Description

A parameterized counter that counts from 0 to N-1 and then wraps back to 0.

## Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| N         | Maximum count value (counts from 0 to N-1) | 10 |

## Inputs

| Signal | Description |
|--------|-------------|
| clk    | Clock signal |
| rst_n  | Active-low synchronous reset |

## Outputs

| Signal | Description |
|--------|-------------|
| count  | Current counter value (0 to N-1) |

## Functional Behavior

- Counter increments by 1 on each positive edge of the clock
- When counter reaches N-1, it wraps back to 0 on the next clock cycle
- When rst_n is asserted (low), counter resets to 0 synchronously

## UVM Verification Planning

### Transaction Level Modeling
- **Counter Transaction**: Define a transaction class with the following fields:
  - `reset`: Reset control flag
  - `expected_count`: Expected counter value
  - `operation_cycles`: Number of clock cycles for this operation

### Verification Components
- **Driver**: Generate clock and reset signals for the counter
- **Monitor**: Track the counter output value
- **Sequencer**: Generate transaction sequences for various test scenarios
- **Scoreboard**: 
  - Maintain expected counter value based on operations
  - Compare expected value with actual counter output

### Test Scenarios
1. **Basic Functionality Tests**:
   - Reset behavior verification
   - Count sequence from 0 to N-1 and wrap around
   - Multiple wrap-around cycles

2. **Boundary Condition Tests**:
   - Verify wrap-around from N-1 to 0
   - Reset at N-1 value
   - Reset at mid-count value

3. **Parameterization Tests**:
   - Test with different N values:
     - N = 2 (minimum useful value)
     - N = 10 (default)
     - N = powers of 2 (e.g., 8, 16)
     - N = non-powers of 2 (e.g., 3, 7, 15)

### Functional Coverage Points
1. **Counter Value Coverage**:
   - All counter values from 0 to N-1
   - Special values: 0, N-1 (maximum)
   - Wrap-around transition

2. **Reset Behavior Coverage**:
   - Reset at different counter values
   - Reset timing relative to clock edge

3. **Bit Width Coverage**:
   - Width of counter matches $clog2(N)

### Assertion Plan
1. **Reset Behavior**:
   - After reset, count should be 0
   - Reset should take effect on the next clock edge

2. **Counting Behavior**:
   - Counter should increment by 1 on each clock cycle when not reset
   - When count equals N-1, it should wrap to 0 on the next clock
   - Counter should never exceed N-1
   - Counter should never hold invalid values (beyond the $clog2(N) bit width)

3. **Parameterization**:
   - Counter width should match $clog2(N)
   - Counter maximum value should be N-1

### Recommended UVM Test Structure
- Base test for common counter operations
- Directed tests for boundary conditions
- Parameterized tests for different N values
- Random reset injection tests