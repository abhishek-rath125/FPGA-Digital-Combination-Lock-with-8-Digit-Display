// ============================================================================
// sev_seg_display.v - 8-Digit 7-Segment Display Controller
// Target: RealDigital Urbana Board (AMD Spartan-7 XC7S50-CSGA324-1)
// Standard: Verilog-2001
//
// Drives dual 4-digit display modules:
//   D0 (Left 4 digits: DISP0, digits 7..4)
//   D1 (Right 4 digits: DISP1, digits 3..0)
//
// Electrical characteristics (Urbana V2I1):
//   - Anodes: Active-Low (D0_AN, D1_AN): 0 = digit ON, 1 = digit OFF
//     [0] = rightmost digit of block, [3] = leftmost digit of block
//   - Cathodes: Active-Low (D0_SEG, D1_SEG): 0 = segment ON, 1 = segment OFF
//     Bit mapping: {CDP, CG, CF, CE, CD, CC, CB, CA}
//                  [7]=DP, [6]=G, [5]=F, [4]=E, [3]=D, [2]=C, [1]=B, [0]=A
//
// Refresh rate:
//   100 MHz / 25000 = 4 kHz per digit -> 1 kHz full display refresh (flicker-free)
// ============================================================================
`timescale 1ns/1ps

module sev_seg_display (
    input             clk,
    input             rst,
    // Lock state inputs
    input      [2:0]  state,        // FSM state from digital_lock
    input             changing,     // change mode flag
    input      [15:0] entry,        // entered digits buffer
    input      [1:0]  fail_count,   // consecutive wrong attempts
    input      [2:0]  lockout_secs, // lockout countdown seconds (5..1)
    input             wrong,        // 1-cycle pulse on wrong code
    input      [15:0] sw,           // slide switch inputs (for live previews)
    // Display outputs (active-low)
    output reg [3:0]  d0_an,        // Left display anodes  [3]=leftmost, [0]=rightmost
    output reg [7:0]  d0_seg,       // Left display cathodes {DP,G,F,E,D,C,B,A}
    output reg [3:0]  d1_an,        // Right display anodes [3]=leftmost, [0]=rightmost
    output reg [7:0]  d1_seg        // Right display cathodes {DP,G,F,E,D,C,B,A}
);

    // ---- FSM state encoding (must match digital_lock) ----
    localparam [2:0] S_D0      = 3'd0,
                     S_D1      = 3'd1,
                     S_D2      = 3'd2,
                     S_D3      = 3'd3,
                     S_CHECK   = 3'd4,
                     S_OPEN    = 3'd5,
                     S_CHANGE  = 3'd6,
                     S_LOCKOUT = 3'd7;

    // ---- 7-segment character encodings (active-low: 0=ON, 1=OFF) ----
    // Bit order: SEG[7:0] = {DP, G, F, E, D, C, B, A}
    //
    //      ---A---
    //     |       |
    //     F       B
    //     |       |
    //      ---G---
    //     |       |
    //     E       C
    //     |       |
    //      ---D---   .DP
    //
    localparam [7:0] CH_0 = 8'hC0, CH_1 = 8'hF9, CH_2 = 8'hA4, CH_3 = 8'hB0,
                     CH_4 = 8'h99, CH_5 = 8'h92, CH_6 = 8'h82, CH_7 = 8'hF8,
                     CH_8 = 8'h80, CH_9 = 8'h90, CH_A = 8'h88, CH_b = 8'h83,
                     CH_C = 8'hC6, CH_d = 8'hA1, CH_E = 8'h86, CH_F = 8'h8E;

    localparam [7:0] CH_H     = 8'h89,  // H  (B,C,E,F,G)
                     CH_n     = 8'hAB,  // n  (C,E,G)
                     CH_O     = 8'hC0,  // O  (same as 0)
                     CH_P     = 8'h8C,  // P  (A,B,E,F,G)
                     CH_L     = 8'hC7,  // L  (D,E,F)
                     CH_G     = 8'h82,  // G  (same as 6)
                     CH_I     = 8'hF9,  // I  (same as 1)
                     CH_DASH  = 8'hBF,  // -  (G segment only)
                     CH_BLANK = 8'hFF;  // all segments off

    // ---- Hex-to-7-segment decoder function ----
    function [7:0] hex_to_seg;
        input [3:0] h;
        begin
            case (h)
                4'h0: hex_to_seg = CH_0;  4'h1: hex_to_seg = CH_1;
                4'h2: hex_to_seg = CH_2;  4'h3: hex_to_seg = CH_3;
                4'h4: hex_to_seg = CH_4;  4'h5: hex_to_seg = CH_5;
                4'h6: hex_to_seg = CH_6;  4'h7: hex_to_seg = CH_7;
                4'h8: hex_to_seg = CH_8;  4'h9: hex_to_seg = CH_9;
                4'hA: hex_to_seg = CH_A;  4'hB: hex_to_seg = CH_b;
                4'hC: hex_to_seg = CH_C;  4'hD: hex_to_seg = CH_d;
                4'hE: hex_to_seg = CH_E;  4'hF: hex_to_seg = CH_F;
                default: hex_to_seg = CH_BLANK;
            endcase
        end
    endfunction

    // ---- 2-flop synchronizer for switch inputs (for flicker-free live preview) ----
    reg [15:0] sw_m = 16'h0000, sw_s = 16'h0000;
    always @(posedge clk) begin
        if (rst) begin
            sw_m <= 16'h0000;
            sw_s <= 16'h0000;
        end else begin
            sw_m <= sw;
            sw_s <= sw_m;
        end
    end

    // ---- Refresh counter and digit selector ----
    // 100 MHz / 25000 = 4 kHz (1 kHz complete refresh across 4 digits)
    reg [14:0] refresh_cnt = 15'd0;
    reg [1:0]  digit_sel   = 2'd0;

    always @(posedge clk) begin
        if (rst) begin
            refresh_cnt <= 15'd0;
            digit_sel   <= 2'd0;
        end else if (refresh_cnt >= 15'd24999) begin
            refresh_cnt <= 15'd0;
            digit_sel   <= digit_sel + 1'b1;
        end else begin
            refresh_cnt <= refresh_cnt + 1'b1;
        end
    end

    // ---- Fail flash timer (~0.75 seconds on error) ----
    reg [26:0] fail_timer = 27'd0;
    wire fail_flashing = (fail_timer != 27'd0);

    always @(posedge clk) begin
        if (rst) begin
            fail_timer <= 27'd0;
        end else if (wrong) begin
            fail_timer <= 27'd75_000_000;  // 0.75 s @ 100 MHz
        end else if (fail_timer != 27'd0) begin
            fail_timer <= fail_timer - 1'b1;
        end
    end

    // ---- Content selection for each display position ----
    // D0: d0_char[3] = leftmost (AN[3]), d0_char[0] = rightmost (AN[0])
    // D1: d1_char[3] = leftmost (AN[3]), d1_char[0] = rightmost (AN[0])
    reg [7:0] d0_char3, d0_char2, d0_char1, d0_char0;
    reg [7:0] d1_char3, d1_char2, d1_char1, d1_char0;

    always @(*) begin
        // Defaults: blank
        d0_char3 = CH_BLANK; d0_char2 = CH_BLANK;
        d0_char1 = CH_BLANK; d0_char0 = CH_BLANK;
        d1_char3 = CH_BLANK; d1_char2 = CH_BLANK;
        d1_char1 = CH_BLANK; d1_char0 = CH_BLANK;

        if (state == S_LOCKOUT) begin
            // ---- LOCKOUT: Left="LOCH", Right="   N" (countdown 5..1) ----
            d0_char3 = CH_L;  d0_char2 = CH_O;
            d0_char1 = CH_C;  d0_char0 = CH_H;
            d1_char3 = CH_BLANK; d1_char2 = CH_BLANK;
            d1_char1 = CH_BLANK;
            case (lockout_secs)
                3'd5:    d1_char0 = CH_5;
                3'd4:    d1_char0 = CH_4;
                3'd3:    d1_char0 = CH_3;
                3'd2:    d1_char0 = CH_2;
                3'd1:    d1_char0 = CH_1;
                default: d1_char0 = CH_DASH;
            endcase

        end else if (state == S_CHANGE) begin
            // ---- CHANGE MODE: Left="CHnG", Right=sw[15:0] live preview ----
            d0_char3 = CH_C;  d0_char2 = CH_H;
            d0_char1 = CH_n;  d0_char0 = CH_G;
            d1_char3 = hex_to_seg(sw_s[15:12]);
            d1_char2 = hex_to_seg(sw_s[11:8]);
            d1_char1 = hex_to_seg(sw_s[7:4]);
            d1_char0 = hex_to_seg(sw_s[3:0]);

        end else if (state == S_OPEN) begin
            // ---- UNLOCKED: Left=blank, Right="OPEn" ----
            d1_char3 = CH_O;  d1_char2 = CH_P;
            d1_char1 = CH_E;  d1_char0 = CH_n;

        end else if (fail_flashing && state == S_D0) begin
            // ---- WRONG CODE FLASH: Left="----", Right="FAIL" ----
            d0_char3 = CH_DASH; d0_char2 = CH_DASH;
            d0_char1 = CH_DASH; d0_char0 = CH_DASH;
            d1_char3 = CH_F;  d1_char2 = CH_A;
            d1_char1 = CH_I;  d1_char0 = CH_L;

        end else begin
            // ---- NORMAL ENTRY (S_D0..S_D3, S_CHECK): Left="COdE" ----
            d0_char3 = CH_C;  d0_char2 = CH_O;
            d0_char1 = CH_d;  d0_char0 = CH_E;

            // Right: entered digits with real-time live preview from sw[3:0]
            case (state)
                S_D0: begin
                    d1_char3 = hex_to_seg(sw_s[3:0]);  // live preview cursor
                    d1_char2 = CH_DASH;
                    d1_char1 = CH_DASH;
                    d1_char0 = CH_DASH;
                end
                S_D1: begin
                    d1_char3 = hex_to_seg(entry[15:12]);  // digit 1 locked
                    d1_char2 = hex_to_seg(sw_s[3:0]);     // live preview cursor
                    d1_char1 = CH_DASH;
                    d1_char0 = CH_DASH;
                end
                S_D2: begin
                    d1_char3 = hex_to_seg(entry[15:12]);  // digit 1 locked
                    d1_char2 = hex_to_seg(entry[11:8]);   // digit 2 locked
                    d1_char1 = hex_to_seg(sw_s[3:0]);     // live preview cursor
                    d1_char0 = CH_DASH;
                end
                S_D3: begin
                    d1_char3 = hex_to_seg(entry[15:12]);  // digit 1 locked
                    d1_char2 = hex_to_seg(entry[11:8]);   // digit 2 locked
                    d1_char1 = hex_to_seg(entry[7:4]);    // digit 3 locked
                    d1_char0 = hex_to_seg(sw_s[3:0]);     // live preview cursor
                end
                S_CHECK: begin
                    d1_char3 = hex_to_seg(entry[15:12]);
                    d1_char2 = hex_to_seg(entry[11:8]);
                    d1_char1 = hex_to_seg(entry[7:4]);
                    d1_char0 = hex_to_seg(entry[3:0]);
                end
                default: begin
                    d1_char3 = CH_DASH; d1_char2 = CH_DASH;
                    d1_char1 = CH_DASH; d1_char0 = CH_DASH;
                end
            endcase
        end
    end

    // ---- Multiplexing output registers ----
    // On the RealDigital Urbana Board:
    //   AN[0] = Leftmost digit of block
    //   AN[1] = 2nd digit from left
    //   AN[2] = 3rd digit from left
    //   AN[3] = Rightmost digit of block
    //
    // D0 decimal point (B5) is active-high, so bit 7 is set to 0 to keep DP OFF.
    // D1 decimal point (J4) is active-low, so bit 7 remains 1 to keep DP OFF.
    always @(*) begin
        case (digit_sel)
            2'd0: begin
                d0_an = 4'b1110;  // AN[0] = Leftmost physical digit
                d0_seg = {1'b0, d0_char3[6:0]}; // char3 (leftmost character)
                d1_an = 4'b1110;
                d1_seg = d1_char3;
            end
            2'd1: begin
                d0_an = 4'b1101;  // AN[1] = 2nd digit from left
                d0_seg = {1'b0, d0_char2[6:0]}; // char2
                d1_an = 4'b1101;
                d1_seg = d1_char2;
            end
            2'd2: begin
                d0_an = 4'b1011;  // AN[2] = 3rd digit from left
                d0_seg = {1'b0, d0_char1[6:0]}; // char1
                d1_an = 4'b1011;
                d1_seg = d1_char1;
            end
            2'd3: begin
                d0_an = 4'b0111;  // AN[3] = Rightmost physical digit
                d0_seg = {1'b0, d0_char0[6:0]}; // char0 (rightmost character)
                d1_an = 4'b0111;
                d1_seg = d1_char0;
            end
            default: begin
                d0_an = 4'b1111;  d0_seg = 8'h7F;
                d1_an = 4'b1111;  d1_seg = CH_BLANK;
            end
        endcase
    end

endmodule
