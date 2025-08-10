#!/bin/bash
# SPI Controller Regression Test Script
# This script runs all SPI controller tests as part of a regression suite

# Set simulation tool (modify as needed for your environment)
SIMULATOR="xrun"  # Options: xrun (Cadence), vcs (Synopsys), vsim (Mentor)

# Set UVM_HOME (modify for your environment)
UVM_HOME="/tools/uvm-1.2"

# Output directory for logs and results
LOG_DIR="../logs"
COV_DIR="../cov_db"

# Create output directories if they don't exist
mkdir -p ${LOG_DIR}
mkdir -p ${COV_DIR}

# Test list - add new tests here as they are developed
TESTS=(
    "spi_basic_test"
    "spi_mode_test"
    "spi_width_test"
    "spi_burst_test"
    "spi_interrupt_test"
)

# Date stamp for reports
DATE=$(date +"%Y-%m-%d_%H-%M")
REGRESSION_LOG="${LOG_DIR}/regression_${DATE}.log"

# Print header
echo "================================================================" | tee ${REGRESSION_LOG}
echo "         SPI Controller Regression Suite (${DATE})" | tee -a ${REGRESSION_LOG}
echo "================================================================" | tee -a ${REGRESSION_LOG}
echo "" | tee -a ${REGRESSION_LOG}

# Run each test
PASSED=0
FAILED=0
TOTAL=${#TESTS[@]}

for test in "${TESTS[@]}"; do
    echo "Running test: ${test}" | tee -a ${REGRESSION_LOG}
    
    # Define log files for this test
    TEST_LOG="${LOG_DIR}/${test}_${DATE}.log"
    
    # Define coverage database for this test
    TEST_COV="${COV_DIR}/${test}_${DATE}"
    
    # Simulator command based on the selected tool
    case ${SIMULATOR} in
        "xrun")
            # Cadence Xcelium command
            CMD="xrun -uvm -uvmhome ${UVM_HOME} \
                 -incdir ../../tb \
                 -incdir ../../rtl \
                 -f filelist.f \
                 -covfile cov_config.ccf \
                 -coverage all -covoverwrite \
                 -covtest ${test} \
                 -covdut advanced_spi_controller \
                 +UVM_TESTNAME=${test} \
                 +UVM_VERBOSITY=UVM_MEDIUM \
                 -l ${TEST_LOG}"
            ;;
            
        "vcs")
            # Synopsys VCS command
            CMD="vcs -full64 -sverilog -timescale=1ns/1ps \
                 -ntb_opts uvm-1.2 \
                 -debug_access+all \
                 -cm line+tgl+cond+fsm+branch \
                 -cm_test ${test} \
                 -cm_dir ${TEST_COV} \
                 +define+UVM_TESTNAME=${test} \
                 +UVM_VERBOSITY=UVM_MEDIUM \
                 -f filelist.f \
                 -l ${TEST_LOG} \
                 && ./simv -cm line+tgl+cond+fsm+branch -cm_test ${test} -cm_dir ${TEST_COV}"
            ;;
            
        "vsim")
            # Mentor Questa command
            CMD="vlib work && \
                 vlog -sv -work work -f filelist.f \
                 +incdir+${UVM_HOME}/src \
                 ${UVM_HOME}/src/uvm.sv && \
                 vsim -c -work work \
                 +UVM_TESTNAME=${test} \
                 +UVM_VERBOSITY=UVM_MEDIUM \
                 -coverage \
                 -cvgperinstance \
                 -voptargs=+acc \
                 -do \"coverage save -onexit ${TEST_COV}; run -all; exit\" \
                 spi_controller_tb_top \
                 -l ${TEST_LOG}"
            ;;
            
        *)
            echo "Error: Unknown simulator ${SIMULATOR}" | tee -a ${REGRESSION_LOG}
            exit 1
            ;;
    esac
    
    # Run the test
    echo "  Command: ${CMD}" >> ${REGRESSION_LOG}
    eval ${CMD}
    
    # Check test status
    if grep -q "UVM_ERROR\|UVM_FATAL" ${TEST_LOG}; then
        echo "  [FAILED] ${test}" | tee -a ${REGRESSION_LOG}
        FAILED=$((FAILED+1))
    else
        echo "  [PASSED] ${test}" | tee -a ${REGRESSION_LOG}
        PASSED=$((PASSED+1))
    fi
    
    # Extract coverage information if available
    case ${SIMULATOR} in
        "xrun")
            # Extract coverage from Xcelium
            if command -v imc &> /dev/null; then
                imc -exec "load -test ${test} ${TEST_COV}; report -test ${test} -detail -metrics all -out ${LOG_DIR}/${test}_coverage.rpt; exit" >> ${TEST_LOG}
                COVERAGE=$(grep -m 1 "Total Coverage:" ${LOG_DIR}/${test}_coverage.rpt | awk '{print $3}')
                echo "  Coverage: ${COVERAGE}" | tee -a ${REGRESSION_LOG}
            fi
            ;;
            
        "vcs")
            # Extract coverage from VCS
            if command -v urg &> /dev/null; then
                urg -dir ${TEST_COV} -report ${LOG_DIR}/${test}_coverage
                COVERAGE=$(grep -m 1 "Total Coverage:" ${LOG_DIR}/${test}_coverage/dashboard.txt | awk '{print $3}')
                echo "  Coverage: ${COVERAGE}" | tee -a ${REGRESSION_LOG}
            fi
            ;;
            
        "vsim")
            # Extract coverage from Questa
            if command -v vcover &> /dev/null; then
                vcover report -output ${LOG_DIR}/${test}_coverage.rpt ${TEST_COV}
                COVERAGE=$(grep -m 1 "Total Coverage:" ${LOG_DIR}/${test}_coverage.rpt | awk '{print $3}')
                echo "  Coverage: ${COVERAGE}" | tee -a ${REGRESSION_LOG}
            fi
            ;;
    esac
    
    echo "" | tee -a ${REGRESSION_LOG}
done

# Merge coverage if needed
if [ ${SIMULATOR} = "xrun" ] && command -v imc &> /dev/null; then
    echo "Merging coverage databases..." | tee -a ${REGRESSION_LOG}
    imc -exec "merge -out ${COV_DIR}/merged_${DATE} ${COV_DIR}/*_${DATE}; report -metrics all -detail -out ${LOG_DIR}/merged_coverage_${DATE}.rpt; exit" >> ${REGRESSION_LOG}
    TOTAL_COV=$(grep -m 1 "Total Coverage:" ${LOG_DIR}/merged_coverage_${DATE}.rpt | awk '{print $3}')
    echo "Total merged coverage: ${TOTAL_COV}" | tee -a ${REGRESSION_LOG}
fi

# Print summary
echo "================================================================" | tee -a ${REGRESSION_LOG}
echo "                 Regression Summary" | tee -a ${REGRESSION_LOG}
echo "================================================================" | tee -a ${REGRESSION_LOG}
echo "Total Tests: ${TOTAL}" | tee -a ${REGRESSION_LOG}
echo "Passed:      ${PASSED}" | tee -a ${REGRESSION_LOG}
echo "Failed:      ${FAILED}" | tee -a ${REGRESSION_LOG}
if [ -n "${TOTAL_COV}" ]; then
    echo "Coverage:    ${TOTAL_COV}" | tee -a ${REGRESSION_LOG}
fi
echo "================================================================" | tee -a ${REGRESSION_LOG}

# Set exit code based on test results
if [ ${FAILED} -eq 0 ]; then
    echo "Regression PASSED!" | tee -a ${REGRESSION_LOG}
    exit 0
else
    echo "Regression FAILED!" | tee -a ${REGRESSION_LOG}
    exit 1
fi