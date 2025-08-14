class param_scoreboard #(parameter int WIDTH=4) extends uvm_scoreboard;
    `uvm_component_param_utils(param_scoreboard #(WIDTH))
    
    uvm_analysis_imp #(param_seq_item #(WIDTH), param_scoreboard #(WIDTH)) item_collected_export;
    
    // Local variable to store expected counter value
    logic [WIDTH-1:0] expected_count;
    
    // Counters for tracking verification progress
    int num_transactions;
    int num_matches;
    int num_mismatches;
    
    function new(string name = "param_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
        num_transactions = 0;
        num_matches = 0;
        num_mismatches = 0;
    endfunction
    
    function void write(param_seq_item #(WIDTH) seq_item);
        // Process the transaction
        num_transactions++;
        
        // Check reset condition
        if(seq_item.rst_n == 1'b0) begin
            expected_count = '0; // Reset expected count to all zeros
            `uvm_info(get_type_name(), $sformatf("Reset detected: expected_count = %0h", expected_count), UVM_LOW)
        end
        else begin
            // Calculate next expected value based on up_down control
            if(seq_item.up_down == 1'b1) begin
                // Count up with overflow protection
                if(expected_count < {WIDTH{1'b1}})
                    expected_count = expected_count + 1'b1;
            end
            else begin
                // Count down with underflow protection
                if(expected_count > '0)
                    expected_count = expected_count - 1'b1;
            end
        end
        
        // Compare expected with actual
        if(seq_item.count === expected_count) begin
            `uvm_info(get_type_name(), 
                $sformatf("MATCH! up_down=%0d, rst_n=%0d, count=%0h, expected=%0h", 
                seq_item.up_down, seq_item.rst_n, seq_item.count, expected_count), UVM_LOW)
            num_matches++;
        end
        else begin
            `uvm_error(get_type_name(), 
                $sformatf("MISMATCH! up_down=%0d, rst_n=%0d, count=%0h, expected=%0h", 
                seq_item.up_down, seq_item.rst_n, seq_item.count, expected_count))
            num_mismatches++;
        end
    endfunction
    
    // Report phase to print summary
    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("Scoreboard Report:"), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Total transactions: %0d", num_transactions), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Matches: %0d", num_matches), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Mismatches: %0d", num_mismatches), UVM_LOW)
        
        if(num_mismatches == 0)
            `uvm_info(get_type_name(), "TEST PASSED", UVM_LOW)
        else
            `uvm_info(get_type_name(), "TEST FAILED", UVM_LOW)
    endfunction
endclass