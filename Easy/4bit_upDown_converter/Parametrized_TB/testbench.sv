`include "uvm_macros.svh"
import uvm_pkg::*;

// Include all UVM components
`include "interface.sv"
`include "sequence_item.sv"
`include "sequence.sv"
`include "sequencer.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "agent.sv"
`include "env.sv"
`include "test.sv"

module testbench_top;
    // Width parameter for the counter
    parameter int WIDTH = 8;  // Set to match the test we want to run (changed from 6 to 8)
    
    // Instantiate the interface
    param_counter_if #(WIDTH) intf();
    
    // Instantiate the DUT and connect to interface
    param_counter #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(intf.clk),
        .rst_n(intf.rst_n),
        .up_down(intf.up_down),
        .count(intf.count)
    );
    
    // UVM initialization
    initial begin
        // Set the interface in the config DB
        // Important: Use the same WIDTH as the test will use
        uvm_config_db#(virtual param_counter_if #(WIDTH))::set(null, "*", "vif", intf);
        
        // Pass WIDTH parameter to config DB
        uvm_config_db#(int)::set(null, "*", "WIDTH", WIDTH);
        
        // Run the test
        run_test("param_counter_test_8bit");
    end
    
    // Optional: Add waveform dumping
    initial begin
        $dumpfile("param_counter.vcd");
        $dumpvars(0, testbench_top);
    end
    
    // Add simulation timeout
    initial begin
        #100000 $finish;
    end
endmodule
