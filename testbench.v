module tb_phase1;

    reg clk = 0;
    reg reset;
    reg start;
    reg code_in;
    wire phase1_done;
    wire phase1_fail;
    wire phase1_alarm;

    phase1 uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .code_in(code_in),
        .phase1_done(phase1_done),
        .phase1_fail(phase1_fail),
        .phase1_alarm(phase1_alarm)
    );

    // clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("phase1_tb.vcd");
        $dumpvars(0, tb_phase1);

        reset = 1;
        start = 0;
        code_in = 0;
        #20;

        reset = 0;
        start = 1;

        // TEST CASE 1: Correct sequence 1 0 1 1
        $display("Sending correct sequence 1 0 1 1");
        code_in = 1; #10;
        code_in = 0; #10;
        code_in = 1; #10;
        code_in = 1; #10;

        if (phase1_done)
            $display("✅ Phase 1 unlocked successfully.");
        else if (phase1_fail)
            $display("❌ Phase 1 failed (unexpected).");
        
        if (phase1_alarm)
            $display("❌ Alarm triggered (should NOT happen).");
        else
            $display("✅ No alarm, as expected.");

        // Reset for next test
        reset = 1; #10; reset = 0; start = 1;

        // TEST CASE 2: Wrong sequence 1 1 0 0
        $display("Sending wrong sequence 1 1 0 0");
        code_in = 1; #10;
        code_in = 1; #10;
        code_in = 0; #10;
        code_in = 0; #10;

        if (phase1_done)
            $display("❌ Phase 1 unlocked (should have failed).");
        else if (phase1_fail)
            $display("✅ Phase 1 correctly failed on wrong input.");

        if (phase1_alarm)
            $display("✅ Alarm triggered correctly on failure.");
        else
            $display("❌ Alarm NOT triggered (should have been).");

        
    end

endmodule

module tb_phase2;

    reg clk = 0;
    reg reset;
    reg start;
    reg [3:0] switch_in;
    wire phase2_done;
    wire phase2_fail;
    wire phase2_alarm;

    phase2 uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .switch_in(switch_in),
        .phase2_done(phase2_done),
        .phase2_fail(phase2_fail),
        .phase2_alarm(phase2_alarm)
    );
    always #5 clk = ~clk;
    initial begin
        $dumpfile("phase2_tb.vcd");
        $dumpvars(0, tb_phase2);
        reset = 1;
        start = 0;
        switch_in = 4'b0000;
        #20;
        reset = 0;
        start = 1;
        $display("Testing correct switch combination: 1101");
        switch_in = 4'b1101; #10;

        if (phase2_done)
            $display("Phase 2 passed (correct combination).");
        else if (phase2_fail)
            $display("Phase 2 failed (unexpected).");

        if (phase2_alarm)
            $display("Alarm triggered (should NOT happen).");
        else
            $display("No alarm, as expected.");

        // Reset for next test
        reset = 1; #10; reset = 0; start = 1;

        // TEST CASE 2: Wrong combination 1010
        $display("Testing wrong switch combination: 1010");
        switch_in = 4'b1010; #10;

        if (phase2_done)
            $display("Phase 2 passed (should have failed).");
        else if (phase2_fail)
            $display("Phase 2 correctly failed on wrong input.");

        if (phase2_alarm)
            $display("Alarm triggered correctly on failure.");
        else
            $display("Alarm NOT triggered (should have been).");
    
    end

endmodule
module tb_phase3;

    reg clk = 0;
    reg reset;
    reg start;
    reg [2:0] dir_in;
    wire phase3_done;
    wire phase3_fail;
    wire start_phase2;
    wire phase3_alarm;

    phase3 uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .dir_in(dir_in),
        .phase3_done(phase3_done),
        .phase3_fail(phase3_fail),
        .start_phase2(start_phase2),
        .phase3_alarm(phase3_alarm)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("phase3_tb.vcd");
        $dumpvars(0, tb_phase3);

        reset = 1;
        start = 0;
        dir_in = 3'b000;
        #20;

        reset = 0;
        start = 1;

        // TEST CASE 1: Correct sequence
        $display("Testing correct maze sequence: UP, RIGHT, DOWN, LEFT, UP");
        dir_in = 3'b000; #10; // UP
        dir_in = 3'b011; #10; // RIGHT
        dir_in = 3'b001; #10; // DOWN
        dir_in = 3'b010; #10; // LEFT
        dir_in = 3'b000; #10; // UP

        if (phase3_done)
            $display("✅ Phase 3 passed (correct sequence).");
        else if (phase3_fail)
            $display("❌ Phase 3 failed (unexpected).");

        if (phase3_alarm)
            $display("❌ Alarm triggered unexpectedly.");
        else
            $display("✅ No alarm as expected.");

        if (start_phase2)
            $display("❌ Unexpected start_phase2 signal.");
        else
            $display("✅ start_phase2 signal is low as expected.");

        // Reset for next test
        reset = 1; #10; reset = 0; start = 1;

        // TEST CASE 2: Wrong sequence (wrong second input)
        $display("Testing wrong maze sequence: UP, LEFT (wrong), ...");
        dir_in = 3'b000; #10; // UP
        dir_in = 3'b010; #10; // WRONG (should be RIGHT)

        if (phase3_done)
            $display("❌ Phase 3 passed (should have failed).");
        else if (phase3_fail)
            $display("✅ Phase 3 correctly failed on wrong input.");

        if (phase3_alarm)
            $display("✅ Alarm triggered correctly on failure.");
        else
            $display("❌ Alarm NOT triggered (should have been).");

        if (start_phase2)
            $display("✅ start_phase2 signal correctly triggered on failure.");
        else
            $display("❌ start_phase2 NOT triggered (should have been).");

           end

endmodule
module tb_phase4;

    reg clk = 0;
    reg reset;
    reg start;
    reg [7:0] plate_in;
    wire phase4_done;
    wire phase4_fail;
    wire start_phase2;
    wire phase4_alarm;

    phase4 uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .plate_in(plate_in),
        .phase4_done(phase4_done),
        .phase4_fail(phase4_fail),
        .start_phase2(start_phase2),
        .phase4_alarm(phase4_alarm)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("phase4_tb.vcd");
        $dumpvars(0, tb_phase4);

        reset = 1;
        start = 0;
        plate_in = 8'b00000000;
        #20;

        reset = 0;
        start = 1;

        // TEST CASE 1: Correct pattern sequence
        $display("Testing correct pressure plate sequence");
        plate_in = 8'b10101010; #10;
        plate_in = 8'b11001100; #10;
        plate_in = 8'b11110000; #10;

        if (phase4_done)
            $display("✅ Phase 4 passed (correct sequence).");
        else if (phase4_fail)
            $display("❌ Phase 4 failed (unexpected).");

        if (phase4_alarm)
            $display("❌ Alarm triggered unexpectedly.");
        else
            $display("✅ No alarm as expected.");

        if (start_phase2)
            $display("❌ Unexpected start_phase2 signal.");
        else
            $display("✅ start_phase2 signal is low as expected.");

        // Reset for next test
        reset = 1; #10; reset = 0; start = 1;

        // TEST CASE 2: Wrong second input
        $display("Testing wrong pressure plate sequence");
        plate_in = 8'b10101010; #10;
        plate_in = 8'b11111111; #10; // WRONG
        plate_in = 8'b11110000; #10;

        if (phase4_done)
            $display("❌ Phase 4 passed (should have failed).");
        else if (phase4_fail)
            $display("✅ Phase 4 correctly failed on wrong input.");

        if (phase4_alarm)
            $display("✅ Alarm triggered correctly on failure.");
        else
            $display("❌ Alarm NOT triggered (should have been).");

        if (start_phase2)
            $display("✅ start_phase2 signal correctly triggered on failure.");
        else
            $display("❌ start_phase2 NOT triggered (should have been).");
    end

endmodule
module tb_phase5;

    reg clk = 0;
    reg reset;
    reg start;
    wire [1:0] time_lock_out;
    wire phase5_done;
    wire phase5_fail;
    wire start_phase2;
    wire phase5_alarm;

    phase5 uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .time_lock_out(time_lock_out),
        .phase5_done(phase5_done),
        .phase5_fail(phase5_fail),
        .start_phase2(start_phase2),
        .phase5_alarm(phase5_alarm)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("phase5_tb.vcd");
        $dumpvars(0, tb_phase5);

        reset = 1;
        start = 0;
        #20;

        reset = 0;
        start = 1;

        $display("Testing time-lock sequence generation");

        // Monitor outputs for 20 clock cycles
        repeat (20) begin
            #10;
            $display("Time: %0t | Output: %b | Done: %b | Fail: %b | Start_Phase2: %b | Alarm: %b", 
                      $time, time_lock_out, phase5_done, phase5_fail, start_phase2, phase5_alarm);
        end

        if (phase5_done)
            $display("✅ Phase 5 passed (correct timed sequence).");
        else if (phase5_fail)
            $display("❌ Phase 5 failed.");
        else
            $display(" Phase 5 incomplete after test duration.");

       
    end

endmodule


module tb_top_module;

    reg clk;
    reg reset;
    reg code_in;
    reg [3:0] switch_in;
    reg [2:0] dir_in;
    reg [7:0] plate_in;
    wire [1:0] time_lock_out;
    wire all_done;
    wire vault_escape;

    top_module uut (
        .clk(clk),
        .reset(reset),
        .code_in(code_in),
        .switch_in(switch_in),
        .dir_in(dir_in),
        .plate_in(plate_in),
        .time_lock_out(time_lock_out),
        .all_done(all_done),
        .vault_escape(vault_escape)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;  
    end

    initial begin
        $dumpfile("top_module.vcd");  
        $dumpvars(0, tb_top_module);  
    end

    initial begin
        $monitor("Time=%0t | reset=%b | all_done=%b | vault_escape=%b", $time, reset, all_done, vault_escape);
    end

    initial begin
        reset = 1;
        code_in = 0;
        switch_in = 4'b0000;
        dir_in = 3'b000;
        plate_in = 8'b00000000;

        #20 reset = 0;

        #100;

        if (all_done && vault_escape) begin
            $display(" All phases completed successfully!");
        end else begin
            $display(" Failed to complete all phases.");
        end

        $finish;  
    end

endmodule

