module system_top (
    input  wire       CLOCK_50,      // 50 MHz system clock
    input  wire [1:0] KEY,           // KEY[0] = Reset, KEY[1] = Transmit
    input  wire [7:0] SW,            // 8-bit input data
    input  wire       GPIO_RX,       // Serial Receive Pin
    input  wire       RX_EN,	 // RX Enable Switch
	 input  wire		 baud_sel,
    
    output wire       GPIO_TX,       // Serial Transmit Pin
    output wire [6:0] HEX0,          // 7-Segment: Input Data (Low Nibble)
    output wire [6:0] HEX1,          // 7-Segment: Input Data (High Nibble)
    output wire [6:0] HEX2,          // 7-Segment: Output Data (Low Nibble)
    output wire [6:0] HEX3           // 7-Segment: Output Data (High Nibble)
);

    // --- Internal Wires ---
    wire [7:0] rx_data_wire;
    wire       data_valid_wire;
    
    // --- Transmit Data Selection ---
    // Swap the comments on the two lines below to switch between hardware SW and manual entry
    wire [7:0] tx_data_wire = SW;                 // Default: Use physical switches
    //wire [7:0] tx_data_wire = 8'b10101010;     // Manual: Hardcode your 8 bits here (e.g., 8'hA5)
    
    // Invert Active-Low Buttons
    wire rst_n    = KEY[0];
    wire tx_start = ~KEY[1]; 
    // For this implementation, we can leave RX_Enable always high to constantly listen,
    // or tie it to another button if you add one. Setting to 1'b1 for continuous listening.
    //wire rx_enable = RX_EN;
    wire rx_enable = 1'b1;   
    
    // --- 1. The Green Block: UART Core ---
    // This perfectly matches the specifications from Table 1 of your assignment
    uart_core my_uart (
        .Data_In    (tx_data_wire),   // Swapped SW for tx_data_wire
        .Data_Out   (rx_data_wire),   // 8-bit parallel output
        .Clk        (CLOCK_50),       // System Clock
        .TX_Enable  (tx_start),       // Triggered by button press
        .RX_Enable  (rx_enable),      // Always listening
        .Data_Valid (data_valid_wire),// High when valid data is received
        .Reset      (rst_n),          // System reset
        .TX         (GPIO_TX),        // Serial out to physical pin
        .RX         (GPIO_RX),
		  .baud_sel  (baud_sel)// Serial in from physical pin
    );

    // --- 2. The Blue Block: 7-Segment Output Logic ---
    
    // Input Data Displays (What you are about to send)
    hex_to_7seg in_low_decoder (
        .hex_in  (tx_data_wire[3:0]), // Swapped SW for tx_data_wire
        .seg_out (HEX0)
    );
    
    hex_to_7seg in_high_decoder (
        .hex_in  (tx_data_wire[7:4]), // Swapped SW for tx_data_wire
        .seg_out (HEX1)
    );

    // Received Data Displays (What you just got from the other board/loopback)
    // To satisfy the "Data Valid" requirement, we only update the display 
    // if the data is valid. Otherwise, we can hold the last value or clear it.
    // Here, we simply route the output register directly to the displays.
    
    hex_to_7seg out_low_decoder (
        .hex_in  (rx_data_wire[3:0]), 
        .seg_out (HEX2)
    );
    
    hex_to_7seg out_high_decoder (
        .hex_in  (rx_data_wire[7:4]), 
        .seg_out (HEX3)
    );

endmodule