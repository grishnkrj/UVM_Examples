# UVM Implementation Guide

This document provides detailed, step-by-step guidelines for implementing UVM testbenches for the DUTs in this repository.

## Table of Contents

1. [UVM Basics](#uvm-basics)
2. [General Implementation Process](#general-implementation-process)
3. [Detailed Example: Simple ALU](#detailed-example-simple-alu)
4. [Detailed Example: FIFO](#detailed-example-fifo)
5. [Common UVM Patterns](#common-uvm-patterns)
6. [Advanced Techniques](#advanced-techniques)

## UVM Basics

### UVM Class Hierarchy

UVM provides a class library with pre-defined components for verification:

```
uvm_object
  ├── uvm_transaction
  │     └── Your transaction classes
  └── uvm_component
        ├── uvm_driver
        ├── uvm_monitor
        ├── uvm_sequencer
        ├── uvm_scoreboard
        ├── uvm_agent
        ├── uvm_env
        └── uvm_test
```

### Essential UVM Phases

UVM test execution follows these phases:

1. **Build Phase**: Create and configure components
2. **Connect Phase**: Establish connections between components
3. **Run Phase**: Execute the actual test
4. **Report Phase**: Report results and coverage

## General Implementation Process

### 1. Create Directory Structure

For each DUT, create this directory structure:

```
dut_name_tb/
├── dut_name_pkg.sv         # Package file
├── dut_name_if.sv          # Interface file
├── dut_name_types.sv       # Types and parameters
├── dut_name_seq_item.sv    # Transaction definition
├── dut_name_sequences.sv   # Sequences
├── dut_name_sequencer.sv   # Sequencer
├── dut_name_driver.sv      # Driver
├── dut_name_monitor.sv     # Monitor
├── dut_name_agent.sv       # Agent
├── dut_name_scoreboard.sv  # Scoreboard
├── dut_name_env.sv         # Environment
├── dut_name_test.sv        # Test cases
└── dut_name_tb_top.sv      # Top-level testbench
```

### 2. Define Interface

```systemverilog
interface dut_name_if #(parameter WIDTH = 8) (input logic clk);
  // DUT signals go here
  logic [WIDTH-1:0] signal_a;
  logic reset_n;
  
  // Clocking blocks for driver and monitor
  clocking cb_drv @(posedge clk);
    output signal_a, reset_n;
  endclocking
  
  clocking cb_mon @(posedge clk);
    input signal_a, reset_n;
  endclocking
  
  // Optional modports
  modport DRV (clocking cb_drv);
  modport MON (clocking cb_mon);
endinterface
```

### 3. Define Transaction (Sequence Item)

```systemverilog
class dut_name_seq_item extends uvm_sequence_item;
  // Define transaction fields
  rand bit [7:0] data_a;
  rand bit [7:0] data_b;
  
  // UVM macros
  `uvm_object_utils_begin(dut_name_seq_item)
    `uvm_field_int(data_a, UVM_ALL_ON)
    `uvm_field_int(data_b, UVM_ALL_ON)
  `uvm_object_utils_end
  
  // Constructor
  function new(string name = "dut_name_seq_item");
    super.new(name);
  endfunction
  
  // Optional constraints
  constraint c_data { data_a inside {[0:100]}; }
endclass
```

### 4. Create Sequences

```systemverilog
class dut_name_base_seq extends uvm_sequence #(dut_name_seq_item);
  `uvm_object_utils(dut_name_base_seq)
  
  function new(string name = "dut_name_base_seq");
    super.new(name);
  endfunction
  
  task body();
    dut_name_seq_item req;
    
    repeat(10) begin
      req = dut_name_seq_item::type_id::create("req");
      start_item(req);
      if(!req.randomize())
        `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
    end
  endtask
endclass
```

### 5. Implement Driver

```systemverilog
class dut_name_driver extends uvm_driver #(dut_name_seq_item);
  `uvm_component_utils(dut_name_driver)
  
  virtual dut_name_if vif;
  
  function new(string name = "dut_name_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual dut_name_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "Could not get vif")
  endfunction
  
  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask
  
  task drive_item(dut_name_seq_item item);
    // Implement driving logic
    @(vif.cb_drv);
    vif.cb_drv.signal_a <= item.data_a;
    // Other signals...
  endtask
endclass
```

### 6. Implement Monitor

```systemverilog
class dut_name_monitor extends uvm_monitor;
  `uvm_component_utils(dut_name_monitor)
  
  virtual dut_name_if vif;
  uvm_analysis_port #(dut_name_seq_item) analysis_port;
  
  function new(string name = "dut_name_monitor", uvm_component parent = null);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual dut_name_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Could not get vif")
  endfunction
  
  task run_phase(uvm_phase phase);
    dut_name_seq_item item;
    
    forever begin
      item = dut_name_seq_item::type_id::create("item");
      collect_data(item);
      analysis_port.write(item);
    end
  endtask
  
  task collect_data(dut_name_seq_item item);
    // Monitor logic to collect signals
    @(vif.cb_mon);
    item.data_a = vif.cb_mon.signal_a;
    // Other signals...
  endtask
endclass
```

### 7. Implement Agent

```systemverilog
class dut_name_agent extends uvm_agent;
  `uvm_component_utils(dut_name_agent)
  
  dut_name_driver    driver;
  dut_name_sequencer sequencer;
  dut_name_monitor   monitor;
  
  // Configuration object (optional)
  dut_name_agent_config cfg;
  
  function new(string name = "dut_name_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration if available
    if(!uvm_config_db#(dut_name_agent_config)::get(this, "", "cfg", cfg))
      cfg = dut_name_agent_config::type_id::create("cfg");
    
    monitor = dut_name_monitor::type_id::create("monitor", this);
    
    // Create driver and sequencer only for active agents
    if(cfg.is_active == UVM_ACTIVE) begin
      driver = dut_name_driver::type_id::create("driver", this);
      sequencer = dut_name_sequencer::type_id::create("sequencer", this);
    end
  endfunction
  
  function void connect_phase(uvm_phase phase);
    if(cfg.is_active == UVM_ACTIVE)
      driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass
```

### 8. Implement Scoreboard

```systemverilog
class dut_name_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(dut_name_scoreboard)
  
  uvm_analysis_imp #(dut_name_seq_item, dut_name_scoreboard) analysis_export;
  
  // Queues to store expected and actual results
  dut_name_seq_item exp_queue[$];
  
  function new(string name = "dut_name_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    analysis_export = new("analysis_export", this);
  endfunction
  
  function void write(dut_name_seq_item item);
    // Process received transactions
    // Compare with expected results
    // Use `uvm_info, `uvm_error, etc. for reporting
  endfunction
  
  // Implement predictor logic
  function void predict_result(dut_name_seq_item item);
    // Calculate expected results based on inputs
    // Add to exp_queue
  endfunction
endclass
```

### 9. Implement Environment

```systemverilog
class dut_name_env extends uvm_env;
  `uvm_component_utils(dut_name_env)
  
  dut_name_agent     agent;
  dut_name_scoreboard scoreboard;
  
  function new(string name = "dut_name_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = dut_name_agent::type_id::create("agent", this);
    scoreboard = dut_name_scoreboard::type_id::create("scoreboard", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    agent.monitor.analysis_port.connect(scoreboard.analysis_export);
  endfunction
endclass
```

### 10. Implement Test

```systemverilog
class dut_name_base_test extends uvm_test;
  `uvm_component_utils(dut_name_base_test)
  
  dut_name_env env;
  
  function new(string name = "dut_name_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = dut_name_env::type_id::create("env", this);
    
    // Set verbosity level
    uvm_top.set_report_verbosity_level(UVM_MEDIUM);
  endfunction
  
  task run_phase(uvm_phase phase);
    dut_name_base_seq seq;
    
    phase.raise_objection(this);
    seq = dut_name_base_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);
    phase.drop_objection(this);
  endtask
endclass
```

### 11. Create Testbench Top

```systemverilog
module dut_name_tb_top;
  // Import packages
  import uvm_pkg::*;
  import dut_name_pkg::*;
  
  // Generate clock
  logic clk;
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  // Interface instance
  dut_name_if intf(clk);
  
  // DUT instantiation
  dut_module #(
    .PARAM1(VALUE1)
  ) dut_inst (
    .clk(clk),
    .signal_a(intf.signal_a),
    .reset_n(intf.reset_n)
    // other connections
  );
  
  // Start UVM test
  initial begin
    // Set interface in config DB
    uvm_config_db#(virtual dut_name_if)::set(null, "*", "vif", intf);
    
    // Run test
    run_test("dut_name_base_test");
  end
endmodule
```

## Detailed Example: Simple ALU

Let's implement a complete UVM testbench for the Simple ALU design.

### 1. ALU Interface

```systemverilog
interface alu_if (input logic clk);
  logic [3:0] a;          // First operand
  logic [3:0] b;          // Second operand
  logic [1:0] op;         // Operation code
  logic [3:0] result;     // Operation result
  
  // Driver clocking block
  clocking cb_drv @(posedge clk);
    output a, b, op;
    input result;
  endclocking
  
  // Monitor clocking block
  clocking cb_mon @(posedge clk);
    input a, b, op, result;
  endclocking
  
  // Modports
  modport DRV (clocking cb_drv);
  modport MON (clocking cb_mon);
endinterface
```

### 2. ALU Transaction

```systemverilog
class alu_seq_item extends uvm_sequence_item;
  // Transaction fields
  rand bit [3:0] a;
  rand bit [3:0] b;
  rand bit [1:0] op;
  bit [3:0] result;
  
  // UVM utilities and automation
  `uvm_object_utils_begin(alu_seq_item)
    `uvm_field_int(a, UVM_ALL_ON)
    `uvm_field_int(b, UVM_ALL_ON)
    `uvm_field_int(op, UVM_ALL_ON)
    `uvm_field_int(result, UVM_ALL_ON)
  `uvm_object_utils_end
  
  // Constructor
  function new(string name = "alu_seq_item");
    super.new(name);
  endfunction
  
  // Calculate expected result based on inputs
  function bit [3:0] calc_expected_result();
    bit [3:0] exp_result;
    
    case(op)
      2'b00: exp_result = a + b;      // ADD
      2'b01: exp_result = a - b;      // SUB
      2'b10: exp_result = a & b;      // AND
      2'b11: exp_result = a | b;      // OR
    endcase
    
    return exp_result;
  endfunction
endclass
```

### 3. ALU Driver

```systemverilog
class alu_driver extends uvm_driver #(alu_seq_item);
  `uvm_component_utils(alu_driver)
  
  virtual alu_if vif;
  
  function new(string name = "alu_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "Could not get vif")
  endfunction
  
  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask
  
  task drive_item(alu_seq_item item);
    // Drive signals to interface
    @(vif.cb_drv);
    vif.cb_drv.a <= item.a;
    vif.cb_drv.b <= item.b;
    vif.cb_drv.op <= item.op;
    
    // Wait one cycle for result
    @(vif.cb_drv);
    
    // Optional delay
    repeat(2) @(vif.cb_drv);
  endtask
endclass
```

### 4. ALU Monitor

```systemverilog
class alu_monitor extends uvm_monitor;
  `uvm_component_utils(alu_monitor)
  
  virtual alu_if vif;
  uvm_analysis_port #(alu_seq_item) analysis_port;
  
  function new(string name = "alu_monitor", uvm_component parent = null);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Could not get vif")
  endfunction
  
  task run_phase(uvm_phase phase);
    alu_seq_item item;
    
    forever begin
      item = alu_seq_item::type_id::create("item");
      
      // Wait for input to change
      @(vif.cb_mon);
      
      // Sample the inputs
      item.a = vif.cb_mon.a;
      item.b = vif.cb_mon.b;
      item.op = vif.cb_mon.op;
      
      // Wait one cycle for result
      @(vif.cb_mon);
      
      // Sample the result
      item.result = vif.cb_mon.result;
      
      // Send item to scoreboard
      analysis_port.write(item);
    end
  endtask
endclass
```

### 5. ALU Scoreboard

```systemverilog
class alu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(alu_scoreboard)
  
  uvm_analysis_imp #(alu_seq_item, alu_scoreboard) analysis_export;
  int correct_count, error_count;
  
  function new(string name = "alu_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    analysis_export = new("analysis_export", this);
    correct_count = 0;
    error_count = 0;
  endfunction
  
  function void write(alu_seq_item item);
    bit [3:0] expected_result;
    expected_result = item.calc_expected_result();
    
    if(item.result === expected_result) begin
      `uvm_info("SCB", $sformatf("PASS: a=%0h, b=%0h, op=%0h, result=%0h, expected=%0h",
                item.a, item.b, item.op, item.result, expected_result), UVM_MEDIUM)
      correct_count++;
    end
    else begin
      `uvm_error("SCB", $sformatf("FAIL: a=%0h, b=%0h, op=%0h, result=%0h, expected=%0h",
                 item.a, item.b, item.op, item.result, expected_result))
      error_count++;
    end
  endfunction
  
  function void report_phase(uvm_phase phase);
    `uvm_info("SCB", $sformatf("Results: %0d correct, %0d errors", 
              correct_count, error_count), UVM_LOW)
  endfunction
endclass
```

## Detailed Example: FIFO

Let's look at some key components for a more complex design like the FIFO.

### 1. FIFO Transaction

```systemverilog
class fifo_seq_item extends uvm_sequence_item;
  typedef enum {WRITE, READ, IDLE} operation_t;
  
  rand operation_t operation;
  rand bit [7:0] data;
  bit full, empty, almost_full, almost_empty;
  bit [$clog2(16):0] count;
  bit [7:0] data_out;
  
  // UVM utilities
  `uvm_object_utils_begin(fifo_seq_item)
    `uvm_field_enum(operation_t, operation, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(full, UVM_ALL_ON)
    `uvm_field_int(empty, UVM_ALL_ON)
    `uvm_field_int(almost_full, UVM_ALL_ON)
    `uvm_field_int(almost_empty, UVM_ALL_ON)
    `uvm_field_int(count, UVM_ALL_ON)
    `uvm_field_int(data_out, UVM_ALL_ON)
  `uvm_object_utils_end
  
  // Constructor
  function new(string name = "fifo_seq_item");
    super.new(name);
  endfunction
  
  // Constrain operations to avoid writes when full and reads when empty
  constraint valid_ops {
    full == 1 -> operation != WRITE;
    empty == 1 -> operation != READ;
  }
endclass
```

### 2. FIFO Sequencer and Sequences

```systemverilog
class fifo_fill_sequence extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_fill_sequence)
  
  function new(string name = "fifo_fill_sequence");
    super.new(name);
  endfunction
  
  task body();
    fifo_seq_item req;
    
    repeat(20) begin
      req = fifo_seq_item::type_id::create("req");
      start_item(req);
      if(!req.randomize() with { operation == fifo_seq_item::WRITE; })
        `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class fifo_drain_sequence extends uvm_sequence #(fifo_seq_item);
  `uvm_object_utils(fifo_drain_sequence)
  
  function new(string name = "fifo_drain_sequence");
    super.new(name);
  endfunction
  
  task body();
    fifo_seq_item req;
    
    repeat(20) begin
      req = fifo_seq_item::type_id::create("req");
      start_item(req);
      if(!req.randomize() with { operation == fifo_seq_item::READ; })
        `uvm_error("SEQ", "Randomization failed")
      finish_item(req);
    end
  endtask
endclass
```

### 3. FIFO Reference Model

```systemverilog
class fifo_reference_model extends uvm_component;
  `uvm_component_utils(fifo_reference_model)
  
  parameter int DEPTH = 16;
  parameter int DATA_WIDTH = 8;
  
  // Internal FIFO model
  bit [DATA_WIDTH-1:0] mem[DEPTH];
  int wr_ptr;
  int rd_ptr;
  int count;
  
  // TLM ports
  uvm_analysis_imp #(fifo_seq_item, fifo_reference_model) analysis_export;
  uvm_analysis_port #(fifo_seq_item) expected_port;
  
  function new(string name = "fifo_reference_model", uvm_component parent = null);
    super.new(name, parent);
    analysis_export = new("analysis_export", this);
    expected_port = new("expected_port", this);
    wr_ptr = 0;
    rd_ptr = 0;
    count = 0;
  endfunction
  
  function void write(fifo_seq_item item);
    fifo_seq_item exp_item;
    exp_item = fifo_seq_item::type_id::create("exp_item");
    
    // Copy original transaction
    $cast(exp_item, item.clone());
    
    // Update reference model and expected outputs
    case(item.operation)
      fifo_seq_item::WRITE: begin
        if(count < DEPTH) begin
          mem[wr_ptr] = item.data;
          wr_ptr = (wr_ptr + 1) % DEPTH;
          count++;
        end
      end
      
      fifo_seq_item::READ: begin
        if(count > 0) begin
          exp_item.data_out = mem[rd_ptr];
          rd_ptr = (rd_ptr + 1) % DEPTH;
          count--;
        end
      end
    endcase
    
    // Update status flags
    exp_item.full = (count == DEPTH);
    exp_item.empty = (count == 0);
    exp_item.almost_full = (count == DEPTH-1);
    exp_item.almost_empty = (count == 1);
    exp_item.count = count;
    
    // Send expected item to scoreboard
    expected_port.write(exp_item);
  endfunction
endclass
```

## Common UVM Patterns

### Factory Override Pattern

Use the factory to substitute classes at runtime:

```systemverilog
// In your test:
function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // Override with derived class
  my_driver::type_id::set_type_override(my_special_driver::get_type());
  
  // Conditionally override
  if(get_config_int("special_mode", 0))
    my_driver::type_id::set_type_override(my_special_driver::get_type());
  
  // Instance-specific override  
  my_driver::type_id::set_inst_override(my_special_driver::get_type(), 
                                     "env.agent.driver");
endfunction
```

### Configuration Pattern

Use the configuration database to share objects between components:

```systemverilog
// Set configuration
uvm_config_db#(int)::set(this, "env.agent*", "max_count", 100);
uvm_config_db#(virtual dut_if)::set(this, "*", "vif", vif);

// Get configuration
if(!uvm_config_db#(int)::get(this, "", "max_count", max_count))
  max_count = 10; // Default value

if(!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
  `uvm_fatal("CFG", "Interface not set")
```

### TLM Connections

Connect components using TLM ports:

```systemverilog
// In consumer:
uvm_analysis_imp #(my_transaction, my_consumer) analysis_export;

// In producer:
uvm_analysis_port #(my_transaction) analysis_port;

// Connect in parent:
producer.analysis_port.connect(consumer.analysis_export);
```

## Advanced Techniques

### Coverage Collection

```systemverilog
class my_subscriber extends uvm_subscriber #(my_transaction);
  `uvm_component_utils(my_subscriber)
  
  // Coverage groups
  covergroup my_cg;
    cp_field1: coverpoint item.field1 {
      bins low = {[0:31]};
      bins mid = {[32:223]};
      bins high = {[224:255]};
    }
    
    cp_field2: coverpoint item.field2;
    
    cross_f1_f2: cross cp_field1, cp_field2;
  endgroup
  
  function new(string name = "my_subscriber", uvm_component parent = null);
    super.new(name, parent);
    my_cg = new();
  endfunction
  
  function void write(my_transaction t);
    // Sample coverage
    my_cg.sample();
  endfunction
endclass
```

### SystemVerilog Assertions

```systemverilog
// In interface or testbench:
property p_valid_transaction;
  @(posedge clk) 
    req ##[1:3] ack;
endproperty

assert_valid_transaction: assert property(p_valid_transaction)
  else `uvm_error("ASSERT", "Transaction not acknowledged in time")
```

### Reusable Agent

Create flexible, reusable agents:

```systemverilog
class my_agent_config extends uvm_object;
  `uvm_object_utils(my_agent_config)
  
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  bit has_coverage = 0;
  // Other configuration parameters
  
  function new(string name = "my_agent_config");
    super.new(name);
  endfunction
endclass
```

### Virtual Sequences

Coordinate multiple sequencers:

```systemverilog
class my_virtual_sequence extends uvm_sequence;
  `uvm_object_utils(my_virtual_sequence)
  
  // Handles to sequencers
  uvm_sequencer #(alu_seq_item) alu_seqr;
  uvm_sequencer #(fifo_seq_item) fifo_seqr;
  
  // Sub-sequences
  alu_sequence alu_seq;
  fifo_sequence fifo_seq;
  
  function new(string name = "my_virtual_sequence");
    super.new(name);
  endfunction
  
  task body();
    alu_seq = alu_sequence::type_id::create("alu_seq");
    fifo_seq = fifo_sequence::type_id::create("fifo_seq");
    
    // Run sequences in parallel
    fork
      alu_seq.start(alu_seqr);
      fifo_seq.start(fifo_seqr);
    join
  endtask
endclass
```

### Generating Tests

Create a script to generate multiple test variations:

```bash
#!/bin/bash
# generate_tests.sh

# Base test template
TEMPLATE="my_test_template.sv"

# Generate tests with different parameters
for SIZE in 8 16 32 64; do
  for MODE in 0 1 2 3; do
    # Create test variation
    TEST_FILE="test_size${SIZE}_mode${MODE}.sv"
    cp $TEMPLATE $TEST_FILE
    
    # Modify parameters
    sed -i "s/PARAM_SIZE = .*/PARAM_SIZE = ${SIZE};/" $TEST_FILE
    sed -i "s/PARAM_MODE = .*/PARAM_MODE = ${MODE};/" $TEST_FILE
  done
done
```