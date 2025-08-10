# Simple 4-bit ALU Specification

## Overview

A 4-bit Arithmetic Logic Unit (ALU) that performs basic arithmetic and logical operations.

## Specifications

### Functionality

The ALU performs four operations: addition, subtraction, AND, and OR.

### Inputs

- **a** (4-bit): First operand
- **b** (4-bit): Second operand
- **op** (2-bit): Operation code

### Operation Codes

| op | Operation |
|----|-----------|
| 00 | ADD       |
| 01 | SUB       |
| 10 | AND       |
| 11 | OR        |

### Output

- **result** (4-bit): Operation result

## Parameters

- **WIDTH** (default = 4): Width of operands and result

## UVM Verification Planning

### Transaction Level Modeling
- **ALU Transaction**: Define a transaction class with the following fields:
  - `a`: First operand
  - `b`: Second operand
  - `op`: Operation code
  - `expected_result`: Expected result of operation

### Verification Components
- **Driver**: Apply operands and operation codes to the ALU
- **Monitor**: Track input values and result output
- **Sequencer**: Generate test patterns for different operations and operands
- **Scoreboard**: 
  - Calculate expected results based on operation and inputs
  - Compare actual results with expected values

### Test Scenarios
1. **Basic Operation Tests**:
   - Addition: Various operand combinations
   - Subtraction: Various operand combinations
   - AND: Various bit patterns
   - OR: Various bit patterns

2. **Boundary Condition Tests**:
   - Maximum values (all 1s)
   - Minimum values (all 0s)
   - Addition with overflow
   - Subtraction with underflow

3. **Special Pattern Tests**:
   - Alternating bit patterns (0101, 1010)
   - Walking ones/zeros
   - Powers of 2
   - Operation on identical operands (a == b)

4. **Operation Transitions**:
   - Change operation code with same operands
   - Rapid changes between operations

5. **Parameterization Tests**:
   - Different WIDTH values (e.g., 2, 4, 8 bits)

### Functional Coverage Points
1. **Input Coverage**:
   - All bit patterns in operands a and b
   - All operation codes
   - Special values: zeros, ones, alternating patterns
   - Single bit set in different positions

2. **Output Coverage**:
   - All result bit positions toggled
   - Result values including zero and maximum

3. **Operation Coverage**:
   - All operations executed
   - Transitions between operations

4. **Cross Coverage**:
   - Operation × operand patterns
   - Special cases for each operation (e.g., subtraction with a < b)

### Assertion Plan
1. **Functional Assertions**:
   - Addition: result should equal a + b (truncated to WIDTH bits)
   - Subtraction: result should equal a - b (truncated to WIDTH bits)
   - AND: result should equal a & b
   - OR: result should equal a | b

2. **Parameterization Assertions**:
   - Input width should match WIDTH parameter
   - Output width should match WIDTH parameter

### Recommended UVM Test Structure
- Base test with common ALU operations
- Operation-specific tests (focused on each operation)
- Corner-case tests for each operation
- Random tests with constrained operation and operand patterns
- Parameter variation tests
