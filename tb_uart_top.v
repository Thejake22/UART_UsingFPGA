`timescale 1ns / 1ps

module tb_uart_top();

    // --- 1. Testbench Signals ---
    reg        clk_50;
    reg  [1:0] keys;       // keys[0] = Reset, keys[1] = Transmit
    reg  [7:0] switches;   // Now 8 bits to match the new design
    
    wire       tx_pin;     // Transmit output from FPGA
    wire       rx_pin;     // Receive input to FPGA
    
    // New wires to catch the 7-segment display outputs
    wire [6:0] hex0, hex1, hex2, hex3;

    // --- 2. The Loopback Wire ---
    // This physically connects the TX pin to the RX pin in the simulation
    assign rx_pin = tx_pin; 

    // --- 3. Instantiate the New Top Module ---
    system_top DUT (
        .CLOCK_50 (clk_50),
        .KEY      (keys),
        .SW       (switches),
        .GPIO_RX  (rx_pin),
        .GPIO_TX  (tx_pin),
        .HEX0     (hex0),
        .HEX1     (hex1),
        .HEX2     (hex2),
        .HEX3     (hex3)
    );

    // --- 4. Clock Generation ---
    always #10 clk_50 = ~clk_50; // 50 MHz clock (20ns period)

    // --- 5. The Test Sequence ---
    initial begin
        // Initialize everything
        clk_50   = 0;
        keys     = 2'b11; // Active-low, so 1 means NOT pressed
        switches = 8'b0100_0011; // Hex '43' (ASCII for 'C')

        // Apply Reset
        #100;
        keys[0] = 0; // Press Reset
        #100;
        keys[0] = 1; // Release Reset
        #100;

        // Trigger Transmission
        keys[1] = 0; // Press Transmit Button
        #100;
        keys[1] = 1; // Release Transmit Button

        // Wait for the transmission to finish.
        // 115200 baud takes ~8.6us per bit. 10 bits = ~86us.
        // We wait 100us just to be safe.
        #100000; 

        // Change the switch data and transmit again to test if it updates
        switches = 8'b0100_0100; // Hex '44' (ASCII for 'D')
        #1000;
        keys[1] = 0; // Press Transmit
        #100;
        keys[1] = 1; // Release Transmit
        
        #100000;

        $stop; // End simulation
    end

endmodule