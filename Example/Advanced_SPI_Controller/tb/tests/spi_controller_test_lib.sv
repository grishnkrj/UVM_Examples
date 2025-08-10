/**
 * SPI Controller Test Library
 *
 * This file contains the base test class and extended test classes for
 * SPI controller verification.
 */

// Base test class for all SPI controller tests
class spi_controller_base_test extends uvm_test;
    // Environment instance
    spi_controller_env m_env;
    
    // Environment configuration
    spi_controller_env_config m_env_cfg;
    
    // Factory registration
    `uvm_component_utils(spi_controller_base_test)
    
    // Constructor
    function new(string name = "spi_controller_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create and configure environment configuration
        m_env_cfg = spi_controller_env_config::type_id::create("m_env_cfg");
        
        // Set default parameters
        configure_env();
        
        // Validate configuration
        if (!m_env_cfg.is_valid()) begin
            `uvm_fatal("CONFIG_ERROR", "Environment configuration is invalid")
        end
        
        // Set environment configuration in config_db
        uvm_config_db#(spi_controller_env_config)::set(this, "m_env", "cfg", m_env_cfg);
        
        // Create environment
        m_env = spi_controller_env::type_id::create("m_env", this);
        
        // Make environment accessible to virtual sequences
        uvm_config_db#(spi_controller_env)::set(this, "*", "env", m_env);
    endfunction
    
    // Configuration method (to be overridden by derived classes)
    virtual function void configure_env();
        // Configure APB agent
        m_env_cfg.apb_cfg.is_active = UVM_ACTIVE;
        m_env_cfg.apb_cfg.has_checks = 1;
        m_env_cfg.apb_cfg.has_coverage = 1;
        
        // Configure SPI agent
        m_env_cfg.spi_cfg.is_active = UVM_PASSIVE;
        m_env_cfg.spi_cfg.has_checks = 1;
        m_env_cfg.spi_cfg.has_coverage = 1;
        
        // Enable checking and coverage by default
        m_env_cfg.has_spi_checker = 1;
        m_env_cfg.has_coverage = 1;
    endfunction
    
    // Connect phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction
    
    // Run phase
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        // Set default timeout
        phase.phase_done.set_drain_time(this, 5000);
        
        // Print test information
        `uvm_info(get_type_name(), "Starting test execution", UVM_LOW)
    endtask
    
    // Report phase - check for test pass/fail
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        if (get_report_stats().get_severity_count(UVM_FATAL) +
            get_report_stats().get_severity_count(UVM_ERROR) > 0) begin
            `uvm_info(get_type_name(), "=======================================", UVM_NONE)
            `uvm_info(get_type_name(), "=====    TEST FAILED            =====", UVM_NONE)
            `uvm_info(get_type_name(), "=======================================", UVM_NONE)
        end
        else begin
            `uvm_info(get_type_name(), "=======================================", UVM_NONE)
            `uvm_info(get_type_name(), "=====    TEST PASSED            =====", UVM_NONE)
            `uvm_info(get_type_name(), "=======================================", UVM_NONE)
        end
    endfunction
endclass

// Basic SPI test
class spi_basic_test extends spi_controller_base_test;
    // Factory registration
    `uvm_component_utils(spi_basic_test)
    
    // Constructor
    function new(string name = "spi_basic_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Run phase - execute test
    virtual task run_phase(uvm_phase phase);
        spi_basic_test_vseq vseq;
        
        super.run_phase(phase);
        
        // Create virtual sequence
        vseq = spi_basic_test_vseq::type_id::create("vseq");
        
        // Raise objection to keep test alive
        phase.raise_objection(this);
        
        // Start virtual sequence
        vseq.start(null);
        
        // Drop objection when done
        phase.drop_objection(this);
    endtask
endclass

// SPI mode test - tests all four SPI modes
class spi_mode_test extends spi_controller_base_test;
    // Factory registration
    `uvm_component_utils(spi_mode_test)
    
    // Constructor
    function new(string name = "spi_mode_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Run phase - execute test
    virtual task run_phase(uvm_phase phase);
        spi_mode_test_vseq vseq;
        
        super.run_phase(phase);
        
        // Create virtual sequence
        vseq = spi_mode_test_vseq::type_id::create("vseq");
        
        // Raise objection to keep test alive
        phase.raise_objection(this);
        
        // Start virtual sequence
        vseq.start(null);
        
        // Drop objection when done
        phase.drop_objection(this);
    endtask
endclass

// SPI width test - tests different data widths
class spi_width_test extends spi_controller_base_test;
    // Factory registration
    `uvm_component_utils(spi_width_test)
    
    // Constructor
    function new(string name = "spi_width_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Run phase - execute test
    virtual task run_phase(uvm_phase phase);
        spi_width_test_vseq vseq;
        
        super.run_phase(phase);
        
        // Create virtual sequence
        vseq = spi_width_test_vseq::type_id::create("vseq");
        
        // Raise objection to keep test alive
        phase.raise_objection(this);
        
        // Start virtual sequence
        vseq.start(null);
        
        // Drop objection when done
        phase.drop_objection(this);
    endtask
endclass

// SPI burst test - tests burst transfers
class spi_burst_test extends spi_controller_base_test;
    // Factory registration
    `uvm_component_utils(spi_burst_test)
    
    // Constructor
    function new(string name = "spi_burst_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Run phase - execute test
    virtual task run_phase(uvm_phase phase);
        spi_burst_test_vseq vseq;
        
        super.run_phase(phase);
        
        // Create virtual sequence
        vseq = spi_burst_test_vseq::type_id::create("vseq");
        
        // Raise objection to keep test alive
        phase.raise_objection(this);
        
        // Start virtual sequence
        vseq.start(null);
        
        // Drop objection when done
        phase.drop_objection(this);
    endtask
endclass

// SPI interrupt test - tests interrupt functionality
class spi_interrupt_test extends spi_controller_base_test;
    // Factory registration
    `uvm_component_utils(spi_interrupt_test)
    
    // Constructor
    function new(string name = "spi_interrupt_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Run phase - execute test
    virtual task run_phase(uvm_phase phase);
        spi_interrupt_test_vseq vseq;
        
        super.run_phase(phase);
        
        // Create virtual sequence
        vseq = spi_interrupt_test_vseq::type_id::create("vseq");
        
        // Raise objection to keep test alive
        phase.raise_objection(this);
        
        // Start virtual sequence
        vseq.start(null);
        
        // Drop objection when done
        phase.drop_objection(this);
    endtask
endclass