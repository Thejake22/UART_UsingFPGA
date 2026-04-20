module uart_core (
    input  wire [7:0] Data_In,
    output wire [7:0] Data_Out,
    input  wire       Clk,
    input  wire       TX_Enable,
    input  wire       RX_Enable,
    output wire       Data_Valid,
    input  wire       Reset,
    output wire       TX,
    input  wire       RX,
	 input  wire		 baud_sel
);

    wire tick_16x_wire;
    wire tick_1x_wire;
    wire rx_done_internal;
    wire frame_error_internal; // <-- NEW: Wire to catch the error
	 

    // Master Baud Clock
    uart_baud_gen baud_clock (
        .clk_50m(Clk), 
        .rst_n(Reset),
		  .baud_sel(baud_sel),
        .rx_baud_tick_16x(tick_16x_wire), 
        .tx_baud_tick(tick_1x_wire)
    );

    // Transmitter
    uart_tx transmitter (
        .clk_50m(Clk), 
        .rst_n(Reset),
        .tx_baud_tick(tick_1x_wire), 
        .tx_start(TX_Enable), 
        .tx_data(Data_In), 
        .tx_out(TX), 
        .tx_busy() 
    );

    // Receiver
    uart_rx receiver (
        .clk_50m(Clk), 
        .rst_n(Reset),
        .rx_in(RX), 
        .rx_baud_tick_16x(tick_16x_wire), 
        .rx_data(Data_Out), 
        .rx_done_tick(rx_done_internal), 
        .frame_error(frame_error_internal) // <-- Catch the error flag
    );

    // EXPLICIT LOGIC: Data is only valid if we received a done tick, 
    // the receiver is enabled, AND there is NO framing error.
    assign Data_Valid = rx_done_internal & RX_Enable & ~frame_error_internal;

endmodule