/**
 * SPI Controller UVM Package
 * 
 * This package contains all UVM components for the SPI controller testbench.
 */
package spi_controller_pkg;
    // Import UVM package
    import uvm_pkg::*;
    
    // Include UVM macros
    `include "uvm_macros.svh"
    
    // Include all components
    
    // Agent components
    `include "env/agents/apb_agent/apb_seq_item.sv"
    `include "env/agents/apb_agent/apb_sequencer.sv"
    `include "env/agents/apb_agent/apb_driver.sv"
    `include "env/agents/apb_agent/apb_monitor.sv"
    `include "env/agents/apb_agent/apb_config.sv"
    `include "env/agents/apb_agent/apb_agent.sv"
    
    `include "env/agents/spi_agent/spi_seq_item.sv"
    `include "env/agents/spi_agent/spi_sequencer.sv"
    `include "env/agents/spi_agent/spi_driver.sv"
    `include "env/agents/spi_agent/spi_monitor.sv"
    `include "env/agents/spi_agent/spi_config.sv"
    `include "env/agents/spi_agent/spi_agent.sv"
    
    // Coverage components
    `include "env/coverage/apb_cov.sv"
    `include "env/coverage/spi_cov.sv"
    
    // Reference model
    `include "env/spi_controller_ref_model.sv"
    
    // Scoreboard
    `include "env/scoreboard/spi_controller_scoreboard.sv"
    
    // Environment config and class
    `include "env/spi_controller_env_config.sv"
    `include "env/spi_controller_env.sv"
    
    // Sequences
    `include "sequences/apb_sequences.sv"
    
    // Virtual sequences
    `include "env/virtual_sequences/spi_controller_virtual_sequences.sv"
    
    // Test classes
    `include "tests/spi_controller_test_lib.sv"
    
endpackage : spi_controller_pkg