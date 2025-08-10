# 8-bit Comparator Specification

## Function

Compares two 8-bit numbers and indicates their relationship.

## Inputs

- **a** (8-bit): First number to compare
- **b** (8-bit): Second number to compare

## Outputs

- **lt**: Logic 1 if a < b, otherwise 0
- **eq**: Logic 1 if a == b, otherwise 0
- **gt**: Logic 1 if a > b, otherwise 0

## Design Parameters

- **WIDTH** (default = 8): Bit width of the inputs to compare

## UVM Verification Planning

### Transaction Level Modeling
- **Comparator Transaction**: Define a transaction class with the following fields:
  - `a`: First input value
  - `b`: Second input value
  - `expected_lt`: Expected less-than output
  - `expected_eq`: Expected equal output
  - `expected_gt`: Expected greater-than output

### Verification Components
- **Driver**: Apply input values to the comparator
- **Monitor**: Capture input values and resulting output flags
- **Sequencer**: Generate test patterns for input combinations
- **Scoreboard**: 
  - Calculate expected output flags based on input values
  - Compare actual output flags with expected values

### Test Scenarios
1. **Basic Functionality Tests**:
   - a < b: Verify lt=1, eq=0, gt=0
   - a == b: Verify lt=0, eq=1, gt=0
   - a > b: Verify lt=0, eq=0, gt=1

2. **Boundary Condition Tests**:
   - Minimum values (all 0s)
   - Maximum values (all 1s)
   - Adjacent values (a = b+1, a = b-1)

3. **Edge Cases**:
   - Single bit differences
   - Alternating bit patterns
   - Powers of 2 and their neighbors

4. **Parameterization Tests**:
   - Test with different WIDTH values (e.g., 1, 4, 8, 16 bits)

### Functional Coverage Points
1. **Input Value Coverage**:
   - Cover the range of input values for both a and b
   - Special values: 0, 2^WIDTH-1 (all 1s), 2^(WIDTH-1) (MSB set)
   - Input patterns: alternating bits, walking 1s, walking 0s

2. **Output Combination Coverage**:
   - All output combinations (lt, eq, gt)
   - Transitions between output states

3. **Cross Coverage**:
   - Input ranges × output combinations
   - Special cases for values close to equality (a = b±1)

### Assertion Plan
1. **Protocol Assertions**:
   - Only one output flag should be asserted at any time
   - lt, eq, and gt should never all be 0 at the same time
   - lt, eq, and gt should never have more than one 1 at the same time

2. **Logical Assertions**:
   - When a < b, lt should be 1 and others 0
   - When a == b, eq should be 1 and others 0
   - When a > b, gt should be 1 and others 0

### Recommended UVM Test Structure
- Base test with common input patterns
- Directed tests for specific value comparisons
- Random tests with constrained input ranges
- Parameter variation tests
