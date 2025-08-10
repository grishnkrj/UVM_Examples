# Configurable FIFO Buffer Specification

## Overview

This document specifies the requirements for a Configurable FIFO (First-In-First-Out) Buffer module. The FIFO is intended for use as a mid-level complexity DUT for UVM verification practice.

## Features

- Parameterizable data width (`DATA_WIDTH`) and depth (`DEPTH`)
- Synchronous read and write operations
- Full and empty status flags
- Almost-full and almost-empty status flags
- Output of current FIFO occupancy (`count`)

## Ports

| Name         | Direction | Width                | Description                          |
|--------------|----------|----------------------|--------------------------------------|
| clk          | input    | 1                    | Clock                                |
| rst_n        | input    | 1                    | Active-low synchronous reset         |
| wr_en        | input    | 1                    | Write enable                         |
| rd_en        | input    | 1                    | Read enable                          |
| din          | input    | DATA_WIDTH           | Data input                           |
| dout         | output   | DATA_WIDTH           | Data output                          |
| full         | output   | 1                    | FIFO is full                         |
| empty        | output   | 1                    | FIFO is empty                        |
| almost_full  | output   | 1                    | FIFO is almost full (DEPTH-1)        |
| almost_empty | output   | 1                    | FIFO is almost empty (1 element left) |
| count        | output   | $clog2(DEPTH)+1      | Number of elements in FIFO           |

## Functional Description

- **Write Operation:**
  - On rising edge of `clk`, if `wr_en` is high and FIFO is not full, `din` is written to FIFO and occupancy increases by 1.
- **Read Operation:**
  - On rising edge of `clk`, if `rd_en` is high and FIFO is not empty, the oldest data is presented on `dout` and occupancy decreases by 1.
- **Full/Empty Flags:**
  - `full` is asserted when FIFO is at maximum capacity.
  - `empty` is asserted when FIFO has no data.
- **Almost-full/Almost-empty Flags:**
  - `almost_full` is asserted when only one space is left.
  - `almost_empty` is asserted when only one element is left.
- **Reset:**
  - On `rst_n` deassertion, FIFO pointers and occupancy are reset.

## Verification Requirements

- Parameterize tests for different `DATA_WIDTH` and `DEPTH` values.
- Verify correct operation of all flags (`full`, `empty`, `almost_full`, `almost_empty`).
- Verify correct data ordering (FIFO behavior).
- Test simultaneous read and write.
- Test reset behavior during operation.
- Test boundary conditions (empty/full transitions).
- Test occupancy counter (`count`).

## UVM Verification Planning

### Transaction Level Modeling
- **FIFO Transaction**: Define a transaction class with the following fields:
  - `data`: Data to be written or read (DATA_WIDTH bits)
  - `operation`: Write or read operation
  - `delay`: Optional delay before operation
  - `has_error`: Expected error condition (full/empty violation)

### Verification Components
- **Driver**: Generate FIFO interface signals for write and read operations
- **Monitor**: Observe FIFO interface signals and collect transactions
- **Sequencer**: Control transaction generation for directed and random scenarios
- **Scoreboard**: Maintain reference model and compare expected vs. actual data/flags

### Test Scenarios
1. **Basic Functionality Tests**:
   - Write then read single items
   - Fill to full capacity then read all
   - Alternating read/write operations
   
2. **Boundary Condition Tests**:
   - Empty → Not Empty → Empty transitions
   - Not Full → Full → Not Full transitions
   - Almost Full/Empty transitions
   
3. **Error Condition Tests**:
   - Write when full (should be ignored)
   - Read when empty (should return last value, empty flag stays asserted)
   
4. **Performance Tests**:
   - Back-to-back writes followed by back-to-back reads
   - Concurrent reads and writes
   
5. **Parameterization Tests**:
   - Test with different DATA_WIDTH values (minimum, typical, maximum)
   - Test with different DEPTH values (minimum, typical, maximum)

### Functional Coverage Points
1. **State Coverage**:
   - Empty state reached
   - Full state reached
   - Almost empty state reached
   - Almost full state reached
   - Simultaneous read and write at all states
   
2. **Counter Coverage**:
   - All values of count from 0 to DEPTH
   - Transitions between consecutive count values
   
3. **Data Coverage**:
   - Corner cases: all 0s, all 1s, alternating patterns
   - Data bit toggling

4. **Cross Coverage**:
   - Operation × State (all combinations of read/write with full/empty/normal states)
   - Parameterized cross-coverage for different DEPTH and WIDTH configurations

### Assertion Plan
1. **Protocol Assertions**:
   - When full, write operations should not change count or pointers
   - When empty, read operations should not change count or pointers
   - Count should never exceed DEPTH
   - Reset should clear all counters and flags

2. **Temporal Assertions**:
   - After reset, FIFO should be empty
   - After N consecutive writes (no reads), count should equal N (if N <= DEPTH)
   - After write when count=DEPTH-1, full flag should assert
   - After read when count=1, empty flag should assert

### Recommended UVM Test Structure
- Base test with common configurations
- Derived tests for specific scenarios (full/empty conditions, parameterized tests)
- Factory overrides for configuration variants
- Virtual sequences for complex scenarios
