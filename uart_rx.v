module uart_rx (
    input  wire       clk_50m,
    input  wire       rst_n,
    input  wire       rx_in,
    input  wire       rx_baud_tick_16x, // NEW: Sourced from the master baud gen
    
    output reg  [7:0] rx_data,
    output reg        rx_done_tick,
    output reg        frame_error
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [3:0] tick_counter; 
    reg [2:0] bit_idx;      
    reg [7:0] data_reg;      

    always @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            tick_counter <= 4'd0;
            bit_idx      <= 3'd0;
            data_reg     <= 8'd0;
            rx_data      <= 8'd0;
            rx_done_tick <= 1'b0;
            frame_error  <= 1'b0;
        end else begin
            rx_done_tick <= 1'b0; 

            case (state)
                IDLE: begin
                    if (rx_in == 1'b0) begin 
                        state        <= START;
                        tick_counter <= 4'd0;
                    end
                end

                START: begin
                    if (rx_baud_tick_16x) begin
                        if (tick_counter == 4'd7) begin 
                            if (rx_in == 1'b0) begin    
                                tick_counter <= 4'd0;
                                bit_idx      <= 3'd0;
                                state        <= DATA;
                            end else begin              
                                state <= IDLE;
                            end
                        end else begin
                            tick_counter <= tick_counter + 1'b1;
                        end
                    end
                end

                DATA: begin
                    if (rx_baud_tick_16x) begin
                        if (tick_counter == 4'd15) begin 
                            tick_counter <= 4'd0;
                            data_reg[bit_idx] <= rx_in;  

                            if (bit_idx == 3'd7) begin   
                                state <= STOP;
                            end else begin
                                bit_idx <= bit_idx + 1'b1;
                            end
                        end else begin
                            tick_counter <= tick_counter + 1'b1;
                        end
                    end
                end

                STOP: begin
                    if (rx_baud_tick_16x) begin
                        if (tick_counter == 4'd15) begin 
                            state <= IDLE;
                            if (rx_in == 1'b1) begin     
                                rx_data      <= data_reg; 
                                rx_done_tick <= 1'b1;     
                                frame_error  <= 1'b0;
                            end else begin
                                frame_error  <= 1'b1;
                            end
                        end else begin
                            tick_counter <= tick_counter + 1'b1;
                        end
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule