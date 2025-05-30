`timescale 1ns / 1ps

module combined_fsm_tb;

    // --- Common clock ---
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;  // 10 ns period

    // --- fsm_code_lock (phase 1) signals ---
    reg rst_phase1;
    reg code_in;
    wire phase1_done, phase1_fail;

    fsm_code_lock phase1 (
        .clk(clk),
        .rst(rst_phase1),
        .code_in(code_in),
        .phase1_done(phase1_done),
        .phase1_fail(phase1_fail)
    );

    // --- fsm_switch_room (phase 2) signals ---
    reg rst_phase2;
    reg [3:0] switch_in;
    wire phase2_done, phase2_fail;

    fsm_switch_room phase2 (
        .clk(clk),
        .rst(rst_phase2),
        .switch_in(switch_in),
        .phase2_done(phase2_done),
        .phase2_fail(phase2_fail)
    );

    // --- phase3 signals ---
    reg reset_phase3;
    reg enable_phase3;
    reg [2:0] dir_in;
    wire status_done;
    wire alarm;

    phase3 phase3_inst (
        .clk(clk),
        .reset(reset_phase3),
        .enable(enable_phase3),
        .dir_in(dir_in),
        .status_done(status_done),
        .alarm(alarm)
    );

    // --- phase4 signals ---
    reg reset_phase4;
    reg [7:0] plate_in;
    wire phase4_done, phase4_fail;

    phase4 phase4_inst (
        .clk(clk),
        .reset(reset_phase4),
        .plate_in(plate_in),
        .phase4_done(phase4_done),
        .phase4_fail(phase4_fail)
    );

    // --- phase5 signals ---
    reg reset_phase5;
    wire [1:0] time_lock_out;
    wire phase5_done, phase5_fail;

    phase5 phase5_inst (
        .clk(clk),
        .reset(reset_phase5),
        .time_lock_out(time_lock_out),
        .phase5_done(phase5_done),
        .phase5_fail(phase5_fail)
    );

    // -----------------------
    // Tasks for phase1 (fsm_code_lock)
    task send_bit_phase1(input bit val);
        begin
            code_in = val;
            #10;
        end
    endtask

    // -----------------------
    initial begin
        // Dump all waves in one file or separate files
        $dumpfile("combined_fsm.vcd");
        $dumpvars(0, combined_fsm_tb);

        // ----------- Phase 1 test -----------
        // Reset phase1, keep others reset too
        rst_phase1 = 1; code_in = 0;
        rst_phase2 = 1; switch_in = 0;
        reset_phase3 = 1; enable_phase3 = 0; dir_in = 0;
        reset_phase4 = 1; plate_in = 0;
        reset_phase5 = 1;

        #20;
        rst_phase1 = 0;

        // Correct sequence for phase1: 1 0 1 1
        send_bit_phase1(1);
        send_bit_phase1(0);
        send_bit_phase1(1);
        send_bit_phase1(1);

        #20;

        // Reset phase1 and test wrong sequence
        rst_phase1 = 1; #20; rst_phase1 = 0;
        send_bit_phase1(1);
        send_bit_phase1(1);
        send_bit_phase1(1);
        send_bit_phase1(1);

        #40;

        // ----------- Phase 2 test -----------
        // Reset phase2
        rst_phase2 = 1; #20; rst_phase2 = 0;

        // Correct input: 1101
        switch_in = 4'b1101; #10;

        // Reset and test wrong input
        rst_phase2 = 1; #20; rst_phase2 = 0;
        switch_in = 4'b1111; #10;

        #40;

        // ----------- Phase 3 test -----------
        reset_phase3 = 1; enable_phase3 = 0; dir_in = 3'b000;
        #20;
        reset_phase3 = 0; enable_phase3 = 1;

        // Correct sequence: UP(000), RIGHT(011), DOWN(001), LEFT(010), UP(000)
        dir_in = 3'b000; #10;
        dir_in = 3'b011; #10;
        dir_in = 3'b001; #10;
        dir_in = 3'b010; #10;
        dir_in = 3'b000; #10;

        #20;

        // Reset and test wrong input
        reset_phase3 = 1; #20; reset_phase3 = 0;
        dir_in = 3'b000; #10;
        dir_in = 3'b111; // invalid input
        #20;

        // ----------- Phase 4 test -----------
        reset_phase4 = 1; plate_in = 8'b0;
        #20; reset_phase4 = 0;

        // Correct sequence
        plate_in = 8'b10101010; #10;
        plate_in = 8'b11001100; #10;
        plate_in = 8'b11110000; #10;

        #20;

        // Reset and wrong sequence
        reset_phase4 = 1; #20; reset_phase4 = 0;
        plate_in = 8'b10101010; #10;
        plate_in = 8'b11111111; #10; // wrong
        plate_in = 8'b11110000; #10;

        #20;

        // ----------- Phase 5 test -----------
        reset_phase5 = 1;
        #20;
        reset_phase5 = 0;

        // Wait for phase5 to finish
        #50;

        $finish;
    end

endmodule
