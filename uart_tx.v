module uart_tx (
    input  wire       clk_50m,      // 50 MHz system clock
    input  wire       rst_n,        // Active-low reset
    input  wire       tx_baud_tick, // The 115200 Hz pulse from baud_rate_gen
    input  wire       tx_start,     // A pulse to trigger transmission
    input  wire [7:0] tx_data,      // The 8-bit byte to send
    
    output reg        tx_out,       // The physical serial wire leaving the FPGA
    output reg        tx_busy       // Status flag (1 when sending, 0 when idle)
);

    // FSM State Definitions
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;         // Tracks which of the 4 states we are in
    reg [2:0] bit_idx;       // Counts from 0 to 7 to track data bits
    reg [7:0] data_reg;      // Internal memory to hold the byte being sent

    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n) begin
            // Reset to safe defaults
            state    <= IDLE;
            tx_out   <= 1'b1;       // UART line is HIGH when idle
            tx_busy  <= 1'b0;
            bit_idx  <= 3'd0;
            data_reg <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    tx_out  <= 1'b1; 
                    tx_busy <= 1'b0;
                    
                    // If someone pushes the 'send' button
                    if (tx_start) begin
                        data_reg <= tx_data; // Lock in the data so it doesn't change mid-send
                        tx_busy  <= 1'b1;    // Tell the system we are busy
                        state    <= START;   // Move to START state
                    end
                end

                START: begin
                    // Wait for the exact moment the baud tick fires
                    if (tx_baud_tick) begin
                        tx_out  <= 1'b0; // Pull the line LOW to create the Start Bit
                        bit_idx <= 3'd0; // Reset our bit counter
                        state   <= DATA; // Move to DATA state
                    end
                end

                DATA: begin
                    if (tx_baud_tick) begin
                        // Output the current bit. We start with bit_idx 0 (Least Significant Bit)
                        tx_out <= data_reg[bit_idx]; 
                        
                        // Check if we just sent the last bit
                        if (bit_idx == 3'd7) begin
                            state <= STOP; // Move to STOP state
                        end else begin
                            // Otherwise, increment the counter to send the next bit
                            bit_idx <= bit_idx + 1'b1; 
                        end
                    end
                end

                STOP: begin
                    if (tx_baud_tick) begin
                        tx_out <= 1'b1; // Pull the line HIGH to create the Stop Bit
                        state  <= IDLE; // We are done! Go back to IDLE
                    end
                end
                
                // Safety catch-all
                default: state <= IDLE;
            endcase
        end
    end

endmodule