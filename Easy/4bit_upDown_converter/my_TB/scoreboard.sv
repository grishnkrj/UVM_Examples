class scb extends uvm_component;
    `uvm_component_utils(scb)
  uvm_analysis_imp #(seq_item, scb) scb_port;
  bit [3:0] expected_count=0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        scb_port = new("scb_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

    endfunction

function void write(seq_item item);
    if (item.count !== expected_count)
        `uvm_error("SCOREBOARD", $sformatf("Mismatch: expected %0h, got %0h", expected_count, item.count))
    else
        `uvm_info("SCOREBOARD", $sformatf("Match: %0h", item.count), UVM_LOW)

    // Now update expected_count for the next cycle
    if (!item.rst_n) begin
        expected_count = 0;
    end else if (item.up_down) begin
        if (expected_count != 4'hF)
            expected_count++;
    end else begin
        if (expected_count != 4'h0)
            expected_count--;
    end
endfunction
endclass