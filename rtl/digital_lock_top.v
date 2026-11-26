// ============================================================================
// digital_lock_top.v - Board Top Wrapper for RealDigital Urbana
// Target: AMD Spartan-7 XC7S50-CSGA324-1 (Urbana Board)
//
// Push Button Controls (Active-High, Bank 35):
//   btn[0] = RESET  : Restores factory default code (16'h1234) and clears lock state
//   btn[1] = ENTER  : Samples current hex digit sw[3:0]; relocks when unlocked
//   btn[2] = CHANGE : Click once to enter change mode; flip sw[15:0]; click again to save
//   btn[3] = Unused
//
// Slide Switch Controls (Bank 35):
//   sw[3:0]  = Hex digit being entered (0..F) with live cursor preview
//   sw[15:0] = Full 16-bit new combination with live 4-digit hex preview in CHANGE mode
//
// Discrete User LEDs (Bank 14/15):
//   led[3:0]   = Progress (binary thermometer: 0001 -> 0011 -> 0111 -> 1111)
//   led[5:4]   = Consecutive wrong attempts (0, 1, 2, or 3 during lockout)
//   led[6]     = 0 (off)
//   led[7]     = Changing indicator (active during change mode)
//   led[8]     = UNLOCKED indicator (solid ON when unlocked)
//   led[9]     = LOCKOUT indicator (solid ON for 5 seconds after 3 fails)
//   led[14:10] = 0 (off)
//   led[15]    = Heartbeat blink (~0.74 Hz: indicates 100MHz clock is running)
//
// On-board Dual RGB LEDs (Bank 16, Active-High):
//   rgb0, rgb1 = [0]=Red, [1]=Green, [2]=Blue
//   - Unlocked: Green (3'b010)
//   - Change Mode: Blue (3'b100)
//   - Lockout / Wrong: Red (3'b001)
//   - Normal / Idle: Off (3'b000) - avoids unconfigured pullup glare
//
// Dual 4-Digit 7-Segment Displays (Bank 35, Active-Low):
//   D0_AN[3:0], D0_SEG[7:0] = Left display module  ("COdE", "CHnG", "LOCH", "----")
//   D1_AN[3:0], D1_SEG[7:0] = Right display module (digits + preview, "OPEn", "FAIL", countdown)
// ============================================================================
`timescale 1ns/1ps

module digital_lock_top (
    input         CLK_100MHZ,
    input  [15:0] SW,
    input  [3:0]  BTN,
    output [15:0] LED,
    output [2:0]  RGB0,
    output [2:0]  RGB1,
    output [3:0]  D0_AN,
    output [7:0]  D0_SEG,
    output [3:0]  D1_AN,
    output [7:0]  D1_SEG
);
    wire        unlocked;
    wire        lockout;
    wire        changing;
    wire [3:0]  progress;
    wire [1:0]  fail_count;
    wire [15:0] entry_digits;
    wire [2:0]  state_out;
    wire        wrong;
    wire [2:0]  lockout_secs;

    // Tie off unused button to avoid lint / synthesis warnings
    wire _unused_btn = BTN[3];

    // Core digital lock module instance
    digital_lock #(
        .CODE(16'h1234),
        .LOCK_CYCLES(500_000_000),   // 5.0 seconds at 100 MHz
        .DEBOUNCE_CYCLES(1_000_000)   // 10.0 ms at 100 MHz
    ) u_lock (
        .clk(CLK_100MHZ),
        .rst(BTN[0]),
        .sw(SW),
        .enter(BTN[1]),
        .change(BTN[2]),
        .unlocked(unlocked),
        .lockout(lockout),
        .changing(changing),
        .progress(progress),
        .fail_count(fail_count),
        .entry_digits(entry_digits),
        .state_out(state_out),
        .wrong(wrong),
        .lockout_secs(lockout_secs)
    );

    // 8-Digit 7-Segment Display Driver instance
    sev_seg_display u_display (
        .clk(CLK_100MHZ),
        .rst(BTN[0]),
        .state(state_out),
        .changing(changing),
        .entry(entry_digits),
        .fail_count(fail_count),
        .lockout_secs(lockout_secs),
        .wrong(wrong),
        .sw(SW),
        .d0_an(D0_AN),
        .d0_seg(D0_SEG),
        .d1_an(D1_AN),
        .d1_seg(D1_SEG)
    );

    // Heartbeat counter: 2^26 clock cycles @ 100 MHz ~ 0.671 s half-period (~0.74 Hz blink)
    reg [26:0] hb = 27'd0;
    always @(posedge CLK_100MHZ) begin
        hb <= hb + 1'b1;
    end

    // Discrete status LEDs
    assign LED = {
        hb[26],       // [15]    Heartbeat
        5'b00000,     // [14:10] Unused
        lockout,      // [9]     Lockout (3 wrong attempts)
        unlocked,     // [8]     Unlocked
        changing,     // [7]     Changing code
        1'b0,         // [6]     Unused
        fail_count,   // [5:4]   Consecutive fails (0..3)
        progress      // [3:0]   Entered digits progress
    };

    // On-board RGB Status Lighting: {Blue, Green, Red}
    //   Bit 0 = Red, Bit 1 = Green, Bit 2 = Blue (Active High)
    reg [2:0] rgb_color;
    always @(*) begin
        if (lockout || wrong) begin
            rgb_color = 3'b001;  // Red (Lockout / Access Denied)
        end else if (changing) begin
            rgb_color = 3'b100;  // Blue (Programming / Change Mode)
        end else if (unlocked) begin
            rgb_color = 3'b010;  // Green (Unlocked / Access Granted)
        end else begin
            rgb_color = 3'b000;  // Off during normal standby (no glare!)
        end
    end

    assign RGB0 = rgb_color;
    assign RGB1 = rgb_color;

endmodule
