// ============================================================================
// tb_digital_lock.v - Self-checking testbench (reduced parameters)
// Tests: glitch rejection, progress, unlock, 3-fail lockout, lockout recovery,
//        two-click toggle code change with sw[15:0], ENTER ignored in change mode,
//        reset restores default code.
// Prints "ALL TESTS PASSED" or the failing checks.
// ============================================================================
`timescale 1ns/1ps

module tb_digital_lock;
    reg clk = 0, rst = 1, enter = 0, change = 0;
    reg [15:0] sw = 16'h0000;
    wire unlocked, lockout, changing;
    wire [3:0] progress;
    wire [1:0] fail_count;
    wire [15:0] entry_digits;
    wire [2:0] state_out;
    wire wrong;
    wire [2:0] lockout_secs;

    digital_lock #(.CODE(16'h1234), .LOCK_CYCLES(100), .DEBOUNCE_CYCLES(4)) dut (
        .clk(clk), .rst(rst), .sw(sw), .enter(enter), .change(change),
        .unlocked(unlocked), .lockout(lockout), .changing(changing),
        .progress(progress), .fail_count(fail_count),
        .entry_digits(entry_digits), .state_out(state_out),
        .wrong(wrong), .lockout_secs(lockout_secs));

    always #5 clk = ~clk;                       // 100 MHz

    integer errors = 0, checks = 0, t;

    task check(input cond, input [8*48-1:0] msg);
    begin
        checks = checks + 1;
        if (!cond) begin errors = errors + 1; $display("FAIL @%0t ns: %0s", $time, msg); end
    end
    endtask

    task clks(input integer n);
    begin repeat (n) @(posedge clk); #1; end
    endtask

    task press_enter;  begin enter = 1; clks(16); enter = 0; clks(16); end endtask
    task press_change; begin change = 1; clks(16); change = 0; clks(16); end endtask
    task enter_digit(input [3:0] d); begin sw[3:0] = d; press_enter; end endtask
    task enter_code(input [15:0] c);
    begin enter_digit(c[15:12]); enter_digit(c[11:8]); enter_digit(c[7:4]); enter_digit(c[3:0]); end
    endtask
    task do_reset; begin rst = 1; clks(5); rst = 0; clks(10); end endtask

    initial begin #5_000_000; $display("TIMEOUT"); $finish; end   // watchdog

    initial begin
        clks(5);  do_reset;
        // T1 idle state
        check(!unlocked && !lockout && !changing, "T1 idle outputs low");
        check(progress == 0 && fail_count == 0,   "T1 progress/fails zero");

        // T2 short glitch (< debounce) must be ignored
        enter = 1; clks(2); enter = 0; clks(20);
        check(progress == 0, "T2 glitch ignored");

        // T3 correct code with progress LEDs
        sw[3:0] = 4'h1; press_enter; check(progress == 4'b0001, "T3 progress 1");
        enter_digit(4'h2);          check(progress == 4'b0011, "T3 progress 2");
        enter_digit(4'h3);          check(progress == 4'b0111, "T3 progress 3");
        enter_digit(4'h4);
        check(unlocked && progress == 0 && fail_count == 0, "T3 unlocked with 1234");
        press_enter; check(!unlocked, "T3 ENTER relocks");

        // T4 three wrong codes -> lockout
        enter_code(16'h1111); check(fail_count == 1 && !lockout, "T4 fail 1");
        enter_code(16'h2222); check(fail_count == 2 && !lockout, "T4 fail 2");
        enter_code(16'h3333);
        check(lockout && fail_count == 3 && !unlocked, "T4 lockout + fail_count 3");

        // T5 inputs ignored during lockout, then recovery
        sw[3:0] = 4'h1; press_enter;
        check(lockout && progress == 0, "T5 input ignored in lockout");
        check(lockout_secs >= 3'd1, "T5 lockout countdown active");
        t = 0; while (lockout && t < 500) begin clks(1); t = t + 1; end
        check(t < 500, "T5 lockout ends");
        check(!lockout && fail_count == 0 && progress == 0, "T5 clean state after lockout");

        // T6 correct code works after lockout
        enter_code(16'h1234); check(unlocked, "T6 unlock after lockout");

        // T7 Two-click toggle change mode: click CHANGE -> set sw[15:0] -> click CHANGE again
        press_change;
        check(changing && unlocked, "T7 change mode active");
        sw = 16'hABCD; clks(20);
        press_change;
        check(!changing && unlocked, "T7 change complete, new code saved");
        press_enter; check(!unlocked, "T7 relock after change");

        // T8 old code rejected, new code accepted
        enter_code(16'h1234); check(!unlocked && fail_count == 1, "T8 old code rejected");
        enter_code(16'hABCD); check(unlocked && fail_count == 0,  "T8 new code accepted");

        // T9 ENTER during change mode is ignored (doesn't relock)
        press_change;
        check(changing && unlocked, "T9 entered change mode");
        press_enter;
        check(changing && unlocked, "T9 ENTER ignored in change mode");
        press_change;
        check(!changing && unlocked, "T9 exited change mode");
        press_enter;
        check(!unlocked, "T9 relocked");

        // T10 reset restores default code
        do_reset;
        enter_code(16'hABCD); check(!unlocked && fail_count == 1, "T10 changed code gone");
        enter_code(16'h1234); check(unlocked, "T10 default code restored");

        $display("---- %0d checks, %0d errors ----", checks, errors);
        if (errors == 0) $display("ALL TESTS PASSED"); else $display("TESTS FAILED");
        $finish;
    end
endmodule
