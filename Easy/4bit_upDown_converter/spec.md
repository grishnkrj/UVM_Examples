# 4-bit Up/Down Counter Specification

## Overview

A synchronous 4-bit counter that can count either upward or downward based on a control input.

## Specifications

### Functionality

- Counts up or down based on control input
- Synchronous operation with clock
- Active-low reset

### Inputs

| Signal | Width | Description |
|--------|-------|-------------|
| `clk` | 1-bit | Clock signal |
| `rst_n` | 1-bit | Active-low synchronous reset |
| `up_down` | 1-bit | Count direction control (1 = count up, 0 = count down) |

### Outputs

| Signal | Width | Description |
|--------|-------|-------------|
| `count` | 4-bit | Current counter value |

## RTL Implementation

The design will be implemented in SystemVerilog with synchronous reset and parameterized bit width (defaulting to 4 bits).

## UVM Verification Planning

### Transaction Level Modeling
- **Counter Transaction**: Define a transaction class with the following fields:
  - `up_down`: Direction control (1=up, 0=down)
  - `expected_count`: Expected counter value after operation
  - `operation_cycles`: Number of clock cycles for this operation

### Verification Components
- **Driver**: Generate clock and control signals for the counter
- **Monitor**: Track the counter output and control signals
- **Sequencer**: Coordinate transaction generation for various test scenarios
- **Scoreboard**: 
  - Track expected counter value based on operations
  - Compare expected value with actual counter output

### Test Scenarios
1. **Basic Functionality Tests**:
   - Reset behavior verification
   - Count up sequence from 0 to max (15)
   - Count down sequence from max to 0
   - Alternating up/down operations

2. **Boundary Condition Tests**:
   - Overflow protection (attempting to count up from 15)
   - Underflow protection (attempting to count down from 0)
   - Mid-count direction change

3. **Reset Tests**:
   - Reset during count-up operation
   - Reset during count-down operation
   - Reset timing verification

4. **Parameterization Tests**:
   - Test with different WIDTH values (e.g., 2, 4, 8 bits)

### Functional Coverage Points
1. **Control Coverage**:
   - Both up_down states (0 and 1)
   - Direction change during operation

2. **Counter Value Coverage**:
   - All counter values from 0 to 2^WIDTH-1
   - Special values: minimum (0), maximum (2^WIDTH-1)
   - Overflow and underflow conditions
   
3. **State Transitions**:
   - Transitions between consecutive values in both directions
   - Direction change at boundary values
   - Reset from various count values

### Assertion Plan
1. **Reset Behavior**:
   - After reset, count should be 0
   - Reset should take effect on next clock edge

2. **Counting Behavior**:
   - When up_down=1, counter should increment on each clock (if not at max)
   - When up_down=0, counter should decrement on each clock (if not at min)
   - No change when at max value and up_down=1
   - No change when at min value and up_down=0

3. **Parameterization**:
   - Maximum value should be (2^WIDTH)-1
   - Counter width should match parameter setting

### Recommended UVM Test Structure
- Base test with common counter configurations
- Directed tests for edge cases (max/min values, direction changes)
- Random tests with constraints for normal operation
- Parameter variations testing
