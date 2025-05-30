module fsm_code_lock (
    input clk,
    input rst,
    input code_in,
    output reg phase1_done,
    output reg phase1_fail
);
    parameter IDLE = 3'd0,
              S1   = 3'd1,
              S10  = 3'd2,
              S101 = 3'd3,
              DONE = 3'd4,
              FAIL = 3'd5;
    reg [2:0] state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        phase1_done = 0;
        phase1_fail = 0;
        case (state)
            IDLE:   next_state = (code_in) ? S1 : IDLE;
            S1:     next_state = (code_in) ? S1 : S10;
            S10:    next_state = (code_in) ? S101 : IDLE;
            S101:   next_state = (code_in) ? DONE : IDLE;
            DONE: begin
                next_state = IDLE;
                phase1_done = 1;
            end
            FAIL: begin
                next_state = IDLE;
                phase1_fail = 1;
            end
            default: next_state = IDLE;
        endcase
    end
endmodule

module fsm_switch_room (
    input [3:0] switch_in,
    input clk,
    input rst,
    output reg phase2_done,
    output reg phase2_fail
);
    parameter UNLOCK_CODE = 4'b1101;
    parameter IDLE = 2'b00,
              CHECK = 2'b01,
              DONE = 2'b10,
              FAIL = 2'b11;
    reg [1:0] state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        phase2_done = 0;
        phase2_fail = 0;
        case (state)
            IDLE: next_state = CHECK;
            CHECK: begin
                if (switch_in == UNLOCK_CODE)
                    next_state = DONE;
                else
                    next_state = FAIL;
            end
            DONE: phase2_done = 1;
            FAIL: phase2_fail = 1;
            default: next_state = IDLE;
        endcase
    end
endmodule

module phase3 (
    input clk,
    input reset,
    input enable,
    input [2:0] dir_in,
    output reg status_done,
    output reg alarm
);
    reg [2:0] expected_seq [0:4];
    reg [2:0] count;

    initial begin
        expected_seq[0] = 3'b000;
        expected_seq[1] = 3'b011;
        expected_seq[2] = 3'b001;
        expected_seq[3] = 3'b010;
        expected_seq[4] = 3'b000;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            status_done <= 0;
            alarm <= 0;
        end else if (enable) begin
            if (status_done || alarm) begin
                count <= 0;
                status_done <= 0;
                alarm <= 0;
            end else begin
                if (dir_in != expected_seq[count]) begin
                    alarm <= 1;
                    count <= 0;
                end else begin
                    count <= count + 1;
                    if (count == 4)
                        status_done <= 1;
                end
            end
        end
    end
endmodule

module phase4 (
    input clk,
    input reset,
    input [7:0] plate_in,
    output reg phase4_done,
    output reg phase4_fail
);
    reg [23:0] entered_seq;
    integer count;
    parameter [23:0] EXPECTED_SEQUENCE = {8'b10101010, 8'b11001100, 8'b11110000};

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            entered_seq <= 24'b0;
            phase4_done <= 0;
            phase4_fail <= 0;
        end else begin
            if (count < 3) begin
                entered_seq <= {entered_seq[15:0], plate_in};
                count <= count + 1;
            end
            if (count == 3) begin
                if (entered_seq == EXPECTED_SEQUENCE) begin
                    phase4_done <= 1;
                    phase4_fail <= 0;
                end else begin
                    phase4_done <= 0;
                    phase4_fail <= 1;
                end
            end
        end
    end
endmodule

module phase5 (
    input clk,
    input reset,
    output reg [1:0] time_lock_out,
    output reg phase5_done,
    output reg phase5_fail
);
    reg [2:0] step_counter;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            step_counter <= 0;
            time_lock_out <= 2'b00;
            phase5_done <= 0;
            phase5_fail <= 0;
        end else begin
            case (step_counter)
                0: time_lock_out <= 2'b01;
                1: time_lock_out <= 2'b10;
                2: time_lock_out <= 2'b11;
                default: time_lock_out <= 2'b00;
            endcase

            if (step_counter == 2) begin
                phase5_done <= 1;
                phase5_fail <= 0;
            end else begin
                phase5_done <= 0;
                phase5_fail <= 0;
            end

            step_counter <= step_counter + 1;
        end
    end
endmodule

module vault_fsm(
    input clk,
    input rst,
    input code_in,
    input [3:0] switch_in,
    input [2:0] dir_in,
    input [7:0] plate_in,
    output reg done,
    output reg fail,
    output [1:0] time_lock_out
);
    reg phase1_done, phase1_fail;
    reg phase2_done, phase2_fail;
    reg phase3_done, phase3_fail;
    reg phase4_done, phase4_fail;
    reg phase5_done, phase5_fail;

    reg phase3_enable;
    reg reset_internal;

    reg [2:0] state, next_state;

    parameter P1 = 3'd0,
              P2 = 3'd1,
              P3 = 3'd2,
              P4 = 3'd3,
              P5 = 3'd4,
              SUCCESS = 3'd5,
              FAILURE = 3'd6;

    fsm_code_lock phase1(clk, reset_internal, code_in, phase1_done, phase1_fail);
    fsm_switch_room phase2(switch_in, clk, reset_internal, phase2_done, phase2_fail);
    phase3 phase3_mod(clk, reset_internal, phase3_enable, dir_in, phase3_done, phase3_fail);
    phase4 phase4_mod(clk, reset_internal, plate_in, phase4_done, phase4_fail);
    phase5 phase5_mod(clk, reset_internal, time_lock_out, phase5_done, phase5_fail);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= P1;
            reset_internal <= 1;
            phase3_enable <= 0;
            done <= 0;
            fail <= 0;
        end else begin
            reset_internal <= 0;
            case(state)
                P1: begin
                    phase3_enable <= 0;
                    if (phase1_done) state <= P2;
                    else if (phase1_fail) state <= FAILURE;
                end
                P2: begin
                    phase3_enable <= 0;
                    if (phase2_done) state <= P3;
                    else if (phase2_fail) state <= FAILURE;
                end
                P3: begin
                    phase3_enable <= 1;
                    if (phase3_done) state <= P4;
                    else if (phase3_fail) state <= FAILURE;
                end
                P4: begin
                    phase3_enable <= 0;
                    if (phase4_done) state <= P5;
                    else if (phase4_fail) state <= FAILURE;
                end
                P5: begin
                    phase3_enable <= 0;
                    if (phase5_done) state <= SUCCESS;
                    else if (phase5_fail) state <= FAILURE;
                end
                SUCCESS: begin
                    done <= 1;
                    fail <= 0;
                end
                FAILURE: begin
                    done <= 0;
                    fail <= 1;
                    state <= P2;  // Reset to phase 2 on failure
                    reset_internal <= 1; 
                end
                default: state <= P1;
            endcase
        end
    end
endmodule
