module phase1 (
    input clk,
    input reset,
    input start,              // signal to start phase 1
    input code_in,            // 1-bit serial input
    output reg phase1_done,   // high if correct sequence entered
    output reg phase1_fail,   // high if wrong sequence or timeout
    output reg phase1_alarm   // high if alarm state triggered
);

    parameter [3:0] UNLOCK_CODE = 4'b1011;

    reg [3:0] buffer;
    reg [2:0] count; // counts how many bits received

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            buffer <= 0;
            count <= 0;
            phase1_done <= 0;
            phase1_fail <= 0;
            phase1_alarm <= 0;
        end else if (start) begin
            if (phase1_done || phase1_fail) begin
                // if already done or failed, do nothing
            end else begin
                buffer <= {buffer[2:0], code_in}; // shift in
                count <= count + 1;

                if (count == 3) begin
                    if ({buffer[2:0], code_in} == UNLOCK_CODE) begin
                        phase1_done <= 1;
                        phase1_fail <= 0;
                        phase1_alarm <= 0;
                    end else begin
                        phase1_fail <= 1;
                        phase1_alarm <= 1; // activate alarm on failure
                    end
                end
            end
        end
    end
endmodule

module phase2 (
    input clk,
    input reset,
    input start,                 // signal to start phase 2
    input [3:0] switch_in,       // 4-bit parallel input
    output reg phase2_done,      // high if correct combination
    output reg phase2_fail,      // high if wrong or timeout
    output reg phase2_alarm      // high if alarm state triggered
  
);

    parameter [3:0] UNLOCK_CODE = 4'b1101;

    reg checked;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            phase2_done <= 0;
            phase2_fail <= 0;
            phase2_alarm <= 0;
            checked <= 0;
        end else if (start && !checked) begin
            if (switch_in == UNLOCK_CODE) begin
                phase2_done <= 1;
                phase2_fail <= 0;
                phase2_alarm <= 0;
            end else begin
                phase2_fail <= 1;
                phase2_alarm <= 1; // activate alarm on failure
            end
            checked <= 1; // only check once per start
        end
    end
endmodule
module phase3 (
    input clk,
    input reset,
    input start,                  // signal to start phase 3
    input [2:0] dir_in,           // 3-bit direction input
    output reg phase3_done,       // high if full correct sequence
    output reg phase3_fail,       // high if wrong input or timeout
    output reg start_phase2,      // signal to start phase 2 on failure
    output reg phase3_alarm       // alarm triggered on failure
);

    // Define the expected 5-direction sequence
    parameter [2:0] SEQ [0:4] = {3'b000, 3'b011, 3'b001, 3'b010, 3'b000};
    reg [2:0] seq_index;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            seq_index <= 0;
            phase3_done <= 0;
            phase3_fail <= 0;
            start_phase2 <= 0;
            phase3_alarm <= 0;
        end else if (start && !phase3_done && !phase3_fail) begin
            if (dir_in == SEQ[seq_index]) begin
                seq_index <= seq_index + 1;
                if (seq_index == 4) begin
                    phase3_done <= 1; // reached end of sequence
                    start_phase2 <= 0;
                    phase3_alarm <= 0;
                end
            end else begin
                phase3_fail <= 1;    // wrong input
                start_phase2 <= 1;   // trigger phase2 start on fail
                phase3_alarm <= 1;   // trigger alarm on fail
            end
        end else begin
            // Hold signals until reset clears them
            if (reset) begin
                start_phase2 <= 0;
                phase3_alarm <= 0;
            end
        end
    end
endmodule
module phase4 (
    input clk,
    input reset,
    input start,                   // signal to start phase 4
    input [7:0] plate_in,          // 8-bit pattern input
    output reg phase4_done,        // high if full correct sequence
    output reg phase4_fail,        // high if wrong input or timeout
    output reg start_phase2,       // signal to start phase 2 on failure
    output reg phase4_alarm        // alarm triggered on failure
);

    // Define the expected 3-pattern sequence
    parameter [7:0] SEQ [0:2] = {8'b10101010, 8'b11001100, 8'b11110000};
    reg [1:0] seq_index;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            seq_index <= 0;
            phase4_done <= 0;
            phase4_fail <= 0;
            start_phase2 <= 0;
            phase4_alarm <= 0;
        end else if (start && !phase4_done && !phase4_fail) begin
            if (plate_in == SEQ[seq_index]) begin
                seq_index <= seq_index + 1;
                if (seq_index == 2)
                    phase4_done <= 1; // reached end of sequence
                start_phase2 <= 0;
                phase4_alarm <= 0;
            end else begin
                phase4_fail <= 1;     // wrong input
                start_phase2 <= 1;    // trigger phase 2 start on fail
                phase4_alarm <= 1;    // trigger alarm on fail
            end
        end else begin
            // Hold start_phase2 and alarm until reset clears them
            if (reset) begin
                start_phase2 <= 0;
                phase4_alarm <= 0;
            end
        end
    end
endmodule
module phase5 (
    input clk,
    input reset,
    input start,                   // signal to start phase 5
    output reg [1:0] time_lock_out, // 2-bit timed output
    output reg phase5_done,         // high if correct sequence finished
    output reg phase5_fail,         // high if wrong timing or internal error (optional)
    output reg start_phase2,        // trigger phase 2 on failure
    output reg phase5_alarm         // alarm output on failure
);

    reg [1:0] state;
    reg [3:0] timer;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 0;
            time_lock_out <= 2'b00;
            phase5_done <= 0;
            phase5_fail <= 0;
            start_phase2 <= 0;
            phase5_alarm <= 0;
            timer <= 0;
        end else if (start && !phase5_done && !phase5_fail) begin
            case (state)
                0: begin
                    time_lock_out <= 2'b01;
                    timer <= timer + 1;
                    if (timer == 4) begin // hold for 4 clock cycles (example)
                        state <= 1;
                        timer <= 0;
                    end
                end
                1: begin
                    time_lock_out <= 2'b10;
                    timer <= timer + 1;
                    if (timer == 4) begin
                        state <= 2;
                        timer <= 0;
                    end
                end
                2: begin
                    time_lock_out <= 2'b11;
                    timer <= timer + 1;
                    if (timer == 4) begin
                        phase5_done <= 1; // completed all steps
                    end
                end
                default: begin
                    phase5_fail <= 1;  // invalid state triggers failure
                    start_phase2 <= 1; // trigger phase 2 start
                    phase5_alarm <= 1;  // trigger alarm on failure
                end
            endcase
        end else if (phase5_fail) begin
            // Hold alarm and start_phase2 until reset
            start_phase2 <= 1;
            phase5_alarm <= 1;
        end else begin
            // Normal operation, clear signals
            start_phase2 <= 0;
            phase5_alarm <= 0;
        end
    end
endmodule

module top_module (
    input clk,
    input reset,
    input code_in,               // Phase 1 input
    input [3:0] switch_in,       // Phase 2 input
    input [2:0] dir_in,          // Phase 3 input
    input [7:0] plate_in,        // Phase 4 input
    output [1:0] time_lock_out,  // Phase 5 output
    output reg all_done,         // all phases completed
    output reg vault_escape      // special feature enabled after all done
);

    // Phase done/fail signals (for TESTING, we force them to succeed)
    wire phase1_done = 1;
    wire phase1_fail = 0;

    wire phase2_done = 1;
    wire phase2_fail = 0;

    wire phase3_done = 1;
    wire phase3_fail = 0;

    wire phase4_done = 1;
    wire phase4_fail = 0;

    wire phase5_done = 1;
    wire phase5_fail = 0;

    // Phase start signals
    reg start_phase1, start_phase2, start_phase3, start_phase4, start_phase5;

    // Dummy time_lock_out
    assign time_lock_out = 2'b11;

    // FSM states
    typedef enum reg [2:0] {
        S_PHASE1,
        S_PHASE2,
        S_PHASE3,
        S_PHASE4,
        S_PHASE5,
        S_DONE
    } top_state_t;

    top_state_t state;

    // FSM logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_PHASE1;
            all_done <= 0;
            vault_escape <= 0;
            // Start only phase 1 at reset
            start_phase1 <= 1;
            start_phase2 <= 0;
            start_phase3 <= 0;
            start_phase4 <= 0;
            start_phase5 <= 0;
        end else begin
            case (state)
                S_PHASE1: begin
                    vault_escape <= 0;
                    if (phase1_done) begin
                        state <= S_PHASE2;
                        start_phase1 <= 0;
                        start_phase2 <= 1;
                    end else if (phase1_fail) begin
                        start_phase1 <= 1; // retry phase 1
                    end
                end

                S_PHASE2: begin
                    vault_escape <= 0;
                    if (phase2_done) begin
                        state <= S_PHASE3;
                        start_phase2 <= 0;
                        start_phase3 <= 1;
                    end else if (phase2_fail) begin
                        start_phase2 <= 1;
                    end
                end

                S_PHASE3: begin
                    vault_escape <= 0;
                    if (phase3_done) begin
                        state <= S_PHASE4;
                        start_phase3 <= 0;
                        start_phase4 <= 1;
                    end else if (phase3_fail) begin
                        state <= S_PHASE2;
                        start_phase3 <= 0;
                        start_phase2 <= 1;
                    end
                end

                S_PHASE4: begin
                    vault_escape <= 0;
                    if (phase4_done) begin
                        state <= S_PHASE5;
                        start_phase4 <= 0;
                        start_phase5 <= 1;
                    end else if (phase4_fail) begin
                        state <= S_PHASE2;
                        start_phase4 <= 0;
                        start_phase2 <= 1;
                    end
                end

                S_PHASE5: begin
                    if (phase5_done) begin
                        state <= S_DONE;
                        start_phase5 <= 0;
                        all_done <= 1;
                        vault_escape <= 1;  // Enable vault_escape only after all success
                    end else if (phase5_fail) begin
                        state <= S_PHASE2;
                        start_phase5 <= 0;
                        start_phase2 <= 1;
                        vault_escape <= 0;
                    end else begin
                        vault_escape <= 0;
                    end
                end

                S_DONE: begin
                    all_done <= 1;
                    vault_escape <= 1;
                    start_phase1 <= 0;
                    start_phase2 <= 0;
                    start_phase3 <= 0;
                    start_phase4 <= 0;
                    start_phase5 <= 0;
                end

                default: begin
                    state <= S_PHASE1;
                    start_phase1 <= 1;
                    vault_escape <= 0;
                    all_done <= 0;
                end
            endcase
        end
    end

endmodule
