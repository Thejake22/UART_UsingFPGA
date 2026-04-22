`timescale 1ns / 1ps

module tb_uart_top();

    // --- 1. Testbench Signals ---
    reg        clk_50;
    reg  [1:0] keys;       // keys[0] = Reset, keys[1] = Transmit
    reg  [7:0] switches;   // 8-bit data input
    reg        rx_en;      // RX Enable signal
    reg        baud_sel;   // Baud Rate Selector (0 = 9600, 1 = 115200)
    
    wire       tx_pin;     // Transmit output from FPGA
    wire       rx_pin;     // Receive input to FPGA
    
    // 7-segment display outputs
    wire [6:0] hex0, hex1, hex2, hex3;

    // --- 2. The Loopback Wire ---
    assign rx_pin = tx_pin; 

    // --- 3. Instantiate the Updated Top Module ---
    system_top DUT (
        .CLOCK_50 (clk_50),
        .KEY      (keys),
        .SW       (switches),
        .GPIO_RX  (rx_pin),
        .RX_EN    (rx_en),      // Connected to new port
        .baud_sel (baud_sel),   // Connected to new port
        .GPIO_TX  (tx_pin),
        .HEX0     (hex0),
        .HEX1     (hex1),
        .HEX2     (hex2),
        .HEX3     (hex3)
    );

    // --- 4. Clock Generation ---
    always #10 clk_50 = ~clk_50; // 50 MHz clock

    // --- 5. The Test Sequence ---
    initial begin
        // Initialize everything
        clk_50   = 0;
        rx_en    = 1;         // Enable Receiver
        baud_sel = 1;         // Start with High Speed (115200)
        keys     = 2'b11;     // Active-low, so 1 means NOT pressed
        switches = 8'h43;     // Hex '43' (ASCII 'C')

        // --- Reset Sequence ---
        #100;
        keys[0] = 0;          // Press Reset
        #100;
        keys[0] = 1;          // Release Reset
        #100;

        // --- TEST 1: 115200 Baud ---
        $display("Starting Test 1: 115200 Baud");
        keys[1] = 0;          // Trigger Transmit
        #100;
        keys[1] = 1;
        
        // Wait for ~100us (115200 takes ~86us per byte)
        #100000; 

        // --- TEST 2: 9600 Baud ---
        $display("Starting Test 2: 9600 Baud");
        baud_sel = 0;         // Switch to 9600 Baud
        switches = 8'h44;     // Change data to 'D'
        #1000;
        
        keys[1] = 0;          // Trigger Transmit
        #100;
        keys[1] = 1;

        // 9600 baud takes ~1.04ms (1,040,000 ns) to send 10 bits.
        // We wait 1.2ms to ensure the slow transmission finishes.
        #1200000; 

        $display("Simulation Finished");
        $stop; 
    end

endmodule
