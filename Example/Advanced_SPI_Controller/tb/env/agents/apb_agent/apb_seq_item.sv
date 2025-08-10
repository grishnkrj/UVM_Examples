/**
 * APB Transaction Class (Sequence Item)
 * 
 * This class models APB bus transactions for the Advanced SPI Controller.
 * It encapsulates fields and methods needed for APB transfers (read/write).
 *
 * Features:
 * - Complete APB transaction modeling
 * - Field automation with UVM macros
 * - Randomization constraints for valid transactions
 * - Custom printing for better debug
 */
class apb_seq_item extends uvm_sequence_item;
    // Transaction fields
    rand bit                     is_write;   // 1: Write, 0: Read
    rand bit [11:0]              addr;       // APB address
    rand bit [31:0]              data;       // Data for write or read response
    rand int                     delay;      // Delay before starting transaction
    bit                          error;      // Error flag for response
    
    // Response fields - these will be populated during response phase
    bit [31:0]                   rdata;      // Read data for read transactions
    bit                          resp_error; // Error flag from slave
    
    // Register addresses - match the DUT register map
    // Using these symbolic constants improves readability
    typedef enum bit[11:0] {
        CTRL_REG      = 12'h000,  // Control register
        STATUS_REG    = 12'h004,  // Status register
        CLK_DIV_REG   = 12'h008,  // Clock divider register
        CS_REG        = 12'h00C,  // Chip select register
        DATA_FMT_REG  = 12'h010,  // Data format register
        TX_DATA_REG   = 12'h014,  // TX data register
        RX_DATA_REG   = 12'h018,  // RX data register
        INTR_EN_REG   = 12'h01C,  // Interrupt enable register
        INTR_STAT_REG = 12'h020,  // Interrupt status register
        DMA_CTRL_REG  = 12'h024,  // DMA control register
        TX_FIFO_LVL   = 12'h028,  // TX FIFO level register
        RX_FIFO_LVL   = 12'h02C   // RX FIFO level register
    } reg_addr_t;
    
    // Constraints
    constraint c_addr_alignment {
        // Addresses must be 4-byte aligned for this design
        addr[1:0] == 2'b00;
    }
    
    constraint c_valid_addr {
        // Address must be a valid register
        addr inside {CTRL_REG, STATUS_REG, CLK_DIV_REG, CS_REG, 
                    DATA_FMT_REG, TX_DATA_REG, RX_DATA_REG, 
                    INTR_EN_REG, INTR_STAT_REG, DMA_CTRL_REG, 
                    TX_FIFO_LVL, RX_FIFO_LVL};
    }
    
    constraint c_delay {
        // Reasonable delay range for transaction pacing
        delay inside {[0:10]};
    }
    
    // Special constraints for read-only and write-only registers
    constraint c_rw_access {
        // STATUS_REG, RX_DATA_REG, TX_FIFO_LVL, RX_FIFO_LVL are read-only
        addr inside {STATUS_REG, RX_DATA_REG, TX_FIFO_LVL, RX_FIFO_LVL} -> is_write == 0;
        
        // TX_DATA_REG is write-only
        addr == TX_DATA_REG -> is_write == 1;
    }
    
    // UVM factory registration
    `uvm_object_utils_begin(apb_seq_item)
        `uvm_field_int(is_write, UVM_DEFAULT)
        `uvm_field_int(addr, UVM_DEFAULT | UVM_HEX)
        `uvm_field_int(data, UVM_DEFAULT | UVM_HEX)
        `uvm_field_int(delay, UVM_DEFAULT)
        `uvm_field_int(error, UVM_DEFAULT)
        `uvm_field_int(rdata, UVM_DEFAULT | UVM_HEX)
        `uvm_field_int(resp_error, UVM_DEFAULT)
    `uvm_object_utils_end
    
    // Constructor
    function new(string name = "apb_seq_item");
        super.new(name);
    endfunction
    
    // Helper function to convert address to readable register name
    function string get_reg_name();
        case (addr)
            CTRL_REG:      return "CTRL_REG";
            STATUS_REG:    return "STATUS_REG";
            CLK_DIV_REG:   return "CLK_DIV_REG";
            CS_REG:        return "CS_REG";
            DATA_FMT_REG:  return "DATA_FMT_REG";
            TX_DATA_REG:   return "TX_DATA_REG";
            RX_DATA_REG:   return "RX_DATA_REG";
            INTR_EN_REG:   return "INTR_EN_REG";
            INTR_STAT_REG: return "INTR_STAT_REG";
            DMA_CTRL_REG:  return "DMA_CTRL_REG";
            TX_FIFO_LVL:   return "TX_FIFO_LVL";
            RX_FIFO_LVL:   return "RX_FIFO_LVL";
            default:       return $sformatf("UNKNOWN (0x%0h)", addr);
        endcase
    endfunction
    
    // Custom print method for improved debug output
    function string convert2string();
        string s;
        s = $sformatf("%s APB Transaction: Register=%s (0x%0h)", 
                      is_write ? "WRITE" : "READ", 
                      get_reg_name(), addr);
        
        if (is_write)
            s = {s, $sformatf(", Data=0x%0h", data)};
        else if (rdata !== 32'bx)  // Show read data if available
            s = {s, $sformatf(", Read Data=0x%0h", rdata)};
            
        if (error || resp_error)
            s = {s, " [ERROR]"};
            
        return s;
    endfunction
    
    // Customize do_copy to ensure all fields are copied properly
    virtual function void do_copy(uvm_object rhs);
        apb_seq_item rhs_cast;
        if(!$cast(rhs_cast, rhs)) begin
            `uvm_error("do_copy", "Cast failed")
            return;
        end
        
        super.do_copy(rhs);
        
        this.is_write   = rhs_cast.is_write;
        this.addr       = rhs_cast.addr;
        this.data       = rhs_cast.data;
        this.delay      = rhs_cast.delay;
        this.error      = rhs_cast.error;
        this.rdata      = rhs_cast.rdata;
        this.resp_error = rhs_cast.resp_error;
    endfunction
    
    // Customize do_compare to add specific comparison criteria
    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        apb_seq_item rhs_cast;
        if(!$cast(rhs_cast, rhs)) begin
            `uvm_error("do_compare", "Cast failed")
            return 0;
        end
        
        return (super.do_compare(rhs, comparer) &&
                this.is_write   == rhs_cast.is_write &&
                this.addr       == rhs_cast.addr &&
                this.data       == rhs_cast.data &&
                // Only compare response fields for read transactions
                (this.is_write || this.rdata == rhs_cast.rdata) &&
                this.resp_error == rhs_cast.resp_error);
    endfunction
    
endclass : apb_seq_item