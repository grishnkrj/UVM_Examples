# SPI Controller Testbench File List
# This file contains all files needed for simulation

# RTL files
../../rtl/advanced_spi_controller.sv

# Testbench interfaces
../../tb/env/agents/apb_agent/apb_if.sv
../../tb/env/agents/spi_agent/spi_if.sv

# Testbench package and top
../../tb/spi_controller_pkg.sv
../../tb/top/spi_controller_tb_top.sv

# Compilation options
+incdir+../../rtl
+incdir+../../tb
+incdir+../../tb/env
+incdir+../../tb/env/agents
+incdir+../../tb/env/agents/apb_agent
+incdir+../../tb/env/agents/spi_agent
+incdir+../../tb/env/scoreboard
+incdir+../../tb/env/coverage
+incdir+../../tb/env/virtual_sequences
+incdir+../../tb/sequences
+incdir+../../tb/tests

# UVM options
+UVM_NO_DEPRECATED
+UVM_VERBOSITY=UVM_MEDIUM

# Assertion options
-assert enable
-assert verbose