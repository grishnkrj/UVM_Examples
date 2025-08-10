# Advanced SPI Controller UVM Verification Framework

This document provides a summary of the UVM verification framework implemented for the Advanced SPI Controller. The implementation follows corporate standard practices and provides a comprehensive verification environment.

## Verification Architecture

![UVM Architecture](https://www.edaplayground.com/img/UVM_ClassHierarchy.png)

The verification architecture follows the standard UVM methodology with the following key components:

### 1. Test Components

- **Base Test**: `spi_controller_base_test` - Foundation for all test scenarios
- **Extended Tests**:
  - `spi_basic_test` - Basic functionality testing
  - `spi_mode_test` - Tests all four SPI modes (0-3)
  - `spi_width_test` - Tests different data widths (8/16/24/32-bit)
  - `spi_burst_test` - Tests burst transfers with CS holding
  - `spi_interrupt_test` - Tests interrupt functionality

### 2. Environment Components

- **Environment**: `spi_controller_env` - Integrates all testbench components
- **Config**: `spi_controller_env_config` - Configuration parameters
- **Reference Model**: `spi_controller_ref_model` - Predicts expected behavior
- **Scoreboard**: `spi_controller_scoreboard` - Compares expected vs actual
- **Coverage**: 
  - `spi_cov` - SPI protocol coverage
  - `apb_cov` - APB register access coverage

### 3. Agent Components

- **APB Agent**: Master agent to drive and monitor APB interface
  - Driver, Monitor, Sequencer, Config, Interface
- **SPI Agent**: Passive agent to monitor SPI interface
  - Monitor, Config, Interface

### 4. Sequences & Scenarios

- **APB Sequences**:
  - `apb_base_seq` - Base sequence with utility tasks
  - `apb_spi_reset_seq` - Reset sequence
  - `apb_spi_config_seq` - Configuration sequence
  - `apb_spi_single_transfer_seq` - Single data transfer
  - `apb_spi_burst_transfer_seq` - Burst data transfer
- **Virtual Sequences**:
  - `spi_controller_vseq_base` - Base virtual sequence
  - `spi_basic_test_vseq` - Basic test scenario
  - `spi_mode_test_vseq` - SPI mode test scenario
  - `spi_width_test_vseq` - Data width test scenario
  - `spi_burst_test_vseq` - Burst transfer scenario
  - `spi_interrupt_test_vseq` - Interrupt test scenario

### 5. Integration & Utilities

- **Package**: `spi_controller_pkg.sv` - Combines all components
- **Top Level**: `spi_controller_tb_top.sv` - Instantiates DUT and interfaces
- **Simulation**: 
  - `filelist.f` - File list for simulators
  - `cov_config.ccf` - Coverage configuration
  - `run_regression.sh` - Regression script

## Advanced Features

### 1. Comprehensive Coverage

- **Transaction Coverage**:
  - SPI modes (0-3)
  - Data widths (4-32 bits)
  - CS patterns
  - Data patterns
  - Bit ordering (MSB/LSB first)
  
- **Protocol Coverage**:
  - CPOL/CPHA transitions
  - Data width transitions
  - Register access patterns
  - Cross coverage of parameters

### 2. Reference Model

- Register-accurate behavioral model
- FIFO modeling
- Interrupt prediction
- Transaction prediction

### 3. Testbench Infrastructure

- Layered architecture for reusability
- Factory pattern for customization
- Configurable agents
- Advanced scoreboarding

## Verification Flow

1. **Setup Phase**:
   - Configure environment
   - Set up agents
   - Connect components

2. **Execution Phase**:
   - Run test scenarios
   - Generate stimulus
   - Collect coverage
   - Compare actual vs expected

3. **Reporting Phase**:
   - Generate coverage reports
   - Report test results
   - Analyze any mismatches

## Using the Testbench

### Running a Single Test

```bash
cd tb/sim/scripts
# Modify run_regression.sh to select your simulator
./run_regression.sh
```

### Adding a New Test

1. Extend the base test in `spi_controller_test_lib.sv`
2. Create a new virtual sequence in `spi_controller_virtual_sequences.sv`
3. Add the new test to the TESTS array in `run_regression.sh`

### Reviewing Results

- Test logs in `tb/sim/logs/`
- Coverage reports
- Test summaries

## Corporate Standard Compliance

The verification environment follows corporate standard practices:

- Standard directory structure
- Comprehensive documentation
- Quality metrics in reports
- Regression testing framework
- Coverage goals for signoff

## Conclusion

This UVM implementation provides a robust, reusable, and comprehensive verification environment for the Advanced SPI Controller that follows industry best practices and will help ensure the design is fully verified.