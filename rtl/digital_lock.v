// ============================================================================
// digital_lock.v  -  4-digit hex combination lock with lockout + code change
// Target: RealDigital Urbana Board (AMD Spartan-7 XC7S50-CSGA324-1)
// Contains: debounce, digital_lock
// Standard: Verilog-2001
//
// Features:
//   - 4-digit hex combination (default 16'h1234)
//   - Digit-by-digit entry: set sw[3:0], press ENTER 4 times
//   - OPEN state: press ENTER to relock, or press CHANGE to enter programming mode
//   - CHANGE mode: flip sw[15:0] to desired 16-bit hex combination with live display,
//     then press CHANGE again to save! (ENTER is ignored during CHANGE mode)
//   - Anti-brute force: 3 consecutive wrong attempts triggers 5-second lockout
//   - Lockout countdown: outputs lockout_secs (5..1) for 7-segment display
//   - Reset (btn[0]): restores factory default 16'h1234 and clears fail count
// ============================================================================
`timescale 1ns/1ps

module debounce #(
    parameter CYCLES = 1_000_000   // 10 ms at 100 MHz
)(
    input      clk,
    input      rst,
    input      in,
    output reg stable
);
    reg [1:0]  sync = 2'b00;
    reg [31:0] cnt  = 32'd0;

    always @(posedge clk) begin
        if (rst) begin
            sync   <= 2'b00;
            cnt    <= 32'd0;
            stable <= 1'b0;
        end else begin
            sync <= {sync[0], in};
            if (sync[1] == stable) begin
                cnt <= 32'd0;
            end else if (cnt >= CYCLES - 1) begin
                stable <= sync[1];
                cnt    <= 32'd0;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule

module digital_lock #(
    parameter [15:0] CODE            = 16'h1234,
    parameter        LOCK_CYCLES     = 500_000_000,  // 5 s at 100 MHz
    parameter        DEBOUNCE_CYCLES = 1_000_000     // 10 ms at 100 MHz
)(
    input             clk,
    input             rst,        // active-high, synchronized internally
    input      [15:0] sw,         // 16 slide switches (sw[3:0] for digit entry, sw[15:0] for code change)
    input             enter,      // ENTER button (btn[1])
    input             change,     // CHANGE button (btn[2])
    output            unlocked,   // lock is open
    output            lockout,    // lockout active
    output            changing,   // change mode active
    output reg [3:0]  progress,   // thermometer progress LEDs
    output     [1:0]  fail_count, // consecutive wrong attempts (0..3)
    output     [15:0] entry_digits, // current digit buffer (for display)
    output     [2:0]  state_out,  // FSM state (for display controller)
    output reg        wrong,      // 1-cycle pulse on wrong code entry
    output     [2:0]  lockout_secs // seconds remaining in lockout (5..1)
);
    // ---- 2-stage synchronizers for reset and slide switches ----
    reg [1:0]  rst_sr = 2'b11;          // starts in reset on FPGA configuration
    reg [15:0] sw_m   = 16'h0000;
    reg [15:0] sw_s   = 16'h0000;
    wire       rst_s  = rst_sr[1];

    always @(posedge clk) begin
        rst_sr <= {rst_sr[0], rst};
        sw_m   <= sw;
        sw_s   <= sw_m;
    end

    // ---- Debouncers for push buttons ----
    wire enter_s, change_s;
    debounce #(DEBOUNCE_CYCLES) db_e (
        .clk(clk), .rst(rst_s), .in(enter),  .stable(enter_s)
    );
    debounce #(DEBOUNCE_CYCLES) db_c (
        .clk(clk), .rst(rst_s), .in(change), .stable(change_s)
    );

    // ---- Edge detection ----
    reg  enter_d  = 1'b0;
    reg  change_d = 1'b0;
    wire press     = enter_s  & ~enter_d;   // ENTER rising edge
    wire chg_press = change_s & ~change_d;  // CHANGE rising edge

    // ---- FSM States ----
    localparam [2:0] S_D0      = 3'd0,
                     S_D1      = 3'd1,
                     S_D2      = 3'd2,
                     S_D3      = 3'd3,
                     S_CHECK   = 3'd4,
                     S_OPEN    = 3'd5,
                     S_CHANGE  = 3'd6,
                     S_LOCKOUT = 3'd7;

    reg [2:0]  state    = S_D0;
    reg [15:0] code_reg = CODE;
    reg [15:0] entry    = 16'h0000;
    reg [1:0]  fails    = 2'b00;
    reg [31:0] timer    = 32'd0;

    // ---- Lockout countdown (seconds remaining: 5, 4, 3, 2, 1) ----
    localparam ONE_SEC = LOCK_CYCLES / 5;
    assign lockout_secs = (timer < ONE_SEC * 1) ? 3'd5 :
                          (timer < ONE_SEC * 2) ? 3'd4 :
                          (timer < ONE_SEC * 3) ? 3'd3 :
                          (timer < ONE_SEC * 4) ? 3'd2 : 3'd1;

    // ---- Main FSM ----
    always @(posedge clk) begin
        if (rst_s) begin
            state    <= S_D0;
            entry    <= 16'h0000;
            fails    <= 2'b00;
            timer    <= 32'd0;
            code_reg <= CODE;
            enter_d  <= 1'b0;
            change_d <= 1'b0;
            wrong    <= 1'b0;
        end else begin
            enter_d  <= enter_s;
            change_d <= change_s;
            wrong    <= 1'b0;           // default: clear pulse

            case (state)
                S_D0: begin
                    if (press) begin
                        entry[15:12] <= sw_s[3:0];
                        state        <= S_D1;
                    end
                end

                S_D1: begin
                    if (press) begin
                        entry[11:8] <= sw_s[3:0];
                        state       <= S_D2;
                    end
                end

                S_D2: begin
                    if (press) begin
                        entry[7:4] <= sw_s[3:0];
                        state      <= S_D3;
                    end
                end

                S_D3: begin
                    if (press) begin
                        entry[3:0] <= sw_s[3:0];
                        state      <= S_CHECK;
                    end
                end

                S_CHECK: begin
                    if (entry == code_reg) begin
                        fails <= 2'b00;
                        state <= S_OPEN;
                    end else if (fails == 2'd2) begin
                        wrong <= 1'b1;
                        fails <= 2'd3;
                        timer <= 32'd0;
                        state <= S_LOCKOUT;
                    end else begin
                        wrong <= 1'b1;
                        fails <= fails + 1'b1;
                        state <= S_D0;
                    end
                    entry <= 16'h0000;  // clear entered digits after check
                end

                S_OPEN: begin
                    if (chg_press) begin
                        state <= S_CHANGE;  // click CHANGE once to enter programming mode
                    end else if (press) begin
                        state <= S_D0;      // click ENTER to relock
                    end
                end

                S_CHANGE: begin
                    // In S_CHANGE, sw[15:0] is displayed live on D1.
                    // Click CHANGE again to confirm and save new code.
                    if (chg_press) begin
                        code_reg <= sw_s;
                        state    <= S_OPEN;
                    end
                    // ENTER is ignored in S_CHANGE to prevent accidental relocking
                end

                S_LOCKOUT: begin
                    if (timer >= LOCK_CYCLES - 1) begin
                        fails <= 2'b00;
                        state <= S_D0;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end

                default: state <= S_D0;
            endcase
        end
    end

    // ---- Progress LED decoder (shows count of digits entered) ----
    always @(*) begin
        case (state)
            S_D1:    progress = 4'b0001;  // 1 digit entered
            S_D2:    progress = 4'b0011;  // 2 digits entered
            S_D3:    progress = 4'b0111;  // 3 digits entered
            S_CHECK: progress = 4'b1111;  // 4 digits entered (evaluation cycle)
            default: progress = 4'b0000;  // Idle / Open / Change / Lockout
        endcase
    end

    // ---- Output assignments ----
    assign unlocked     = (state == S_OPEN) || (state == S_CHANGE);
    assign lockout      = (state == S_LOCKOUT);
    assign changing     = (state == S_CHANGE);
    assign fail_count   = fails;
    assign entry_digits = entry;
    assign state_out    = state;

endmodule
