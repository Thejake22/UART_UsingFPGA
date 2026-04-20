module uart_baud_gen (
    input  wire clk_50m,
    input  wire rst_n,
    input  wire baud_sel,         // Connect to DIP Switch (1 = 115200, 0 = 9600)
    
    output reg  rx_baud_tick_16x, // The fast 16x tick for the Receiver
    output reg  tx_baud_tick      // The slow 1x tick for the Transmitter
);

    // --- 0. Select Baud Rate Limit ---
    // If baud_sel is 1: limit is 26  (for 115200 baud)
    // If baud_sel is 0: limit is 324 (for 9600 baud)
    wire [8:0] counter_limit;
    assign counter_limit = baud_sel ? 9'd26 : 9'd324;

    // --- 1. Generate the fast 16x tick ---
    reg [8:0] counter_16x; // Increased to 9 bits to store up to 324
    
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n) begin
            counter_16x      <= 9'd0;
            rx_baud_tick_16x <= 1'b0;
        end else begin
            // We use >= instead of == just in case the switch is flipped 
            // from 9600 to 115200 while the counter is already past 26.
            if (counter_16x >= counter_limit) begin
                counter_16x      <= 9'd0;
                rx_baud_tick_16x <= 1'b1;
            end else begin
                counter_16x      <= counter_16x + 1'b1;
                rx_baud_tick_16x <= 1'b0;
            end
        end
    end

    // --- 2. Generate the slow 1x tick (Divide 16x tick by 16) ---
    reg [3:0] counter_1x; // 4-bit counter counts from 0 to 15
    
    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n) begin
            counter_1x   <= 4'd0;
            tx_baud_tick <= 1'b0;
        end else begin
            // Default to 0 unless we explicitly set it to 1 below
            tx_baud_tick <= 1'b0; 
            
            // We only act when the 16x tick fires
            if (rx_baud_tick_16x) begin
                if (counter_1x == 4'd15) begin
                    counter_1x   <= 4'd0;
                    tx_baud_tick <= 1'b1; // Pulse the 1x tick
                end else begin
                    counter_1x   <= counter_1x + 1'b1;
                end
            end
        end
    end

endmodule