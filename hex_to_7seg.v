module hex_to_7seg (
    input  wire [3:0] hex_in,
    output reg  [6:0] seg_out 
);
    // Note: This is configured for "Common Cathode" (Active-High). 
    // This means sending a '1' turns the LED segment ON, and '0' turns it OFF.
    // The segment order is assumed to be g-f-e-d-c-b-a (MSB to LSB).
    always @(*) begin
        case (hex_in)
            4'h0: seg_out = 7'b0111111; // 0
            4'h1: seg_out = 7'b0000110; // 1
            4'h2: seg_out = 7'b1011011; // 2
            4'h3: seg_out = 7'b1001111; // 3
            4'h4: seg_out = 7'b1100110; // 4
            4'h5: seg_out = 7'b1101101; // 5
            4'h6: seg_out = 7'b1111101; // 6
            4'h7: seg_out = 7'b0000111; // 7
            4'h8: seg_out = 7'b1111111; // 8
            4'h9: seg_out = 7'b1101111; // 9
            4'hA: seg_out = 7'b1110111; // A
            4'hB: seg_out = 7'b1111100; // b
            4'hC: seg_out = 7'b0111001; // C
            4'hD: seg_out = 7'b1011110; // d
            4'hE: seg_out = 7'b1111001; // E
            4'hF: seg_out = 7'b1110001; // F
            default: seg_out = 7'b0000000; // All OFF
        endcase
    end
endmodule