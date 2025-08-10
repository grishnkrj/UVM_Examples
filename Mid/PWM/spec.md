# Configurable Pulse Width Modulator (PWM) Specification

## Overview
This document specifies the requirements and behavior of a parameterized Pulse Width Modulator (PWM) module. The module is intended for UVM practice and is suitable as a mid-level DUT.

## Features
- Parameterizable counter width (default: 8 bits)
- Programmable period and duty cycle via input ports
- Synchronous reset (active low)
- Single output: `pwm_out`

## Ports
| Name        | Direction | Width      | Description                       |
|-------------|-----------|------------|-----------------------------------|
| clk         | input     | 1          | System clock                      |
| rst_n       | input     | 1          | Active-low synchronous reset      |
| period      | input     | WIDTH      | PWM period (number of clock cycles)|
| duty_cycle  | input     | WIDTH      | PWM high time (number of clock cycles)|
| pwm_out     | output    | 1          | PWM output signal                 |

## Functional Description
- The module generates a periodic PWM signal on `pwm_out`.
- The period of the PWM is set by the `period` input (in clock cycles).
- The high time of the PWM is set by the `duty_cycle` input (in clock cycles).
- The output `pwm_out` is high for `duty_cycle` cycles and low for the remaining `period - duty_cycle` cycles.
- If `duty_cycle` >= `period`, the output remains high for the entire period.
- If `duty_cycle` is 0, the output remains low for the entire period.
- The counter and output are reset to 0 when `rst_n` is deasserted.

## Timing Diagram
```
clk        ───┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐
pwm_out    ──┐    ┌───────┐       ┌───────┐       ┌───────┐
            │    │       │       │       │       │       │
           ─┘    └───────┘       └───────┘       └───────┘

(period = 8, duty_cycle = 4)
```

## Parameterization
- `WIDTH`: Sets the width of the counter and input ports. Default is 8.

## Reset Behavior
- When `rst_n` is low, the counter and output are reset to 0.

## Example Configuration
- `WIDTH = 8`, `period = 100`, `duty_cycle = 25` produces a PWM with 25% duty cycle and 100 clock cycle period.

## Notes
- Inputs `period` and `duty_cycle` can be changed at runtime.
- No metastability protection is provided for asynchronous changes to `period` or `duty_cycle`.
- The module is synthesizable and suitable for FPGA/ASIC implementation.

## UVM Verification Planning

### Transaction Level Modeling
- **PWM Configuration Transaction**: Define a transaction class with the following fields:
  - `period`: PWM period value (WIDTH bits)
  - `duty_cycle`: PWM duty cycle value (WIDTH bits)
  - `expected_output_pattern`: Expected output pattern based on the configuration

### Verification Components
- **Driver**: Generate PWM configuration changes at specified intervals
- **Monitor**: 
  - Input monitor: Capture configuration changes to period and duty_cycle
  - Output monitor: Sample pwm_out at high frequency to verify duty cycle accuracy
- **Sequencer**: Control transaction generation for directed and random scenarios
- **Scoreboard**: 
  - Calculate expected output based on period and duty_cycle
  - Measure actual output duty cycle and period
  - Compare expected vs. actual behavior

### Test Scenarios
1. **Basic Functionality Tests**:
   - Fixed period, varying duty cycle
   - Fixed duty cycle, varying period
   - 0% duty cycle (always low)
   - 100% duty cycle (always high)
   - 50% duty cycle (equal high/low time)
   
2. **Boundary Condition Tests**:
   - Minimum period value
   - Maximum period value
   - Duty cycle just below period (high most of the time)
   - Duty cycle just above zero (low most of the time)
   
3. **Dynamic Configuration Tests**:
   - Change period during operation
   - Change duty cycle during operation
   - Simultaneous changes to both period and duty cycle
   
4. **Reset Behavior Tests**:
   - Assert reset during different PWM output phases
   - Change configuration immediately after reset

5. **Parameterization Tests**:
   - Test with different WIDTH values (minimum, typical, maximum)

### Functional Coverage Points
1. **Configuration Coverage**:
   - Period values: 0, 1, maximum (2^WIDTH-1), and ranges in between
   - Duty cycle values: 0, 1, maximum, and ranges in between
   - Duty cycle > period condition
   - Duty cycle = period condition
   - Duty cycle = 0 condition
   
2. **Output Pattern Coverage**:
   - Low output (duty_cycle = 0)
   - High output (duty_cycle >= period)
   - Normal PWM operation with different duty cycle percentages
     - Near 0% (low most of the time)
     - Near 25% 
     - Near 50% (equal high/low time)
     - Near 75%
     - Near 100% (high most of the time)

3. **Counter Coverage**:
   - All values of internal counter from 0 to max period used
   - Counter reset at period boundary

4. **Cross Coverage**:
   - Period × Duty Cycle interactions
   - Reset × Counter Value (reset asserted at different counter values)

### Assertion Plan
1. **Protocol Assertions**:
   - Output should be low when duty_cycle=0
   - Output should be high when duty_cycle >= period
   - Output frequency should match the period setting
   - Output should be low immediately after reset

2. **Temporal Assertions**:
   - For duty_cycle D and period P, output should be high for D clock cycles and low for (P-D) clock cycles
   - After period value change, the new period should take effect after the current cycle completes
   - After duty_cycle change, the new duty cycle should take effect in the next period

### Recommended UVM Test Structure
- Base test with common PWM configurations
- Derived tests for specific scenarios (edge cases, dynamic reconfiguration)
- Factory overrides for WIDTH parameter variations
- Sequences for different PWM signal generation patterns
