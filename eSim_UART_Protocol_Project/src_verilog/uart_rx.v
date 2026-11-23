// ============================================================================
// File: uart_rx.v
// Module: UART Receiver with 16x Oversampling, Mid-Bit Sampling & Error Checking
// Project: eSim Semester Long Internship - Task 2: Communication Protocol Modeling
// Author: FOSSEE eSim Project Contributor
// Description:
//   Models a hardware-level UART receiver module.
//   Synchronizes to incoming asynchronous serial stream via 16x oversampling,
//   samples in the middle of each bit period to reject jitter,
//   deserializes 8-bit payload, and checks for Parity and Framing Errors.
// ============================================================================

`timescale 1ns / 1ps

module uart_rx #(
    parameter CLKS_PER_BIT = 16  // Oversampling factor (typically 16 clocks per baud bit)
)(
    input  wire       clk,          // System oversampling clock (16x baud rate)
    input  wire       rst_n,        // Active-low asynchronous reset
    input  wire       rx_serial,    // Filtered/conditioned serial input line
    output reg  [7:0] rx_data,      // Deserialized 8-bit parallel output
    output reg        rx_valid,     // Strobe asserted when a valid frame is received
    output reg        sample_pulse, // Diagnostics: pulse indicating mid-bit sampling instant
    output reg        parity_error, // High if received parity does not match calculated parity
    output reg        framing_error // High if stop bit was not valid '1'
);

    // FSM State Encoding
    localparam [2:0]
        STATE_IDLE         = 3'b000,
        STATE_START_CHECK  = 3'b001,
        STATE_DATA_BITS    = 3'b010,
        STATE_PARITY_CHECK = 3'b011,
        STATE_STOP_CHECK   = 3'b100,
        STATE_OUTPUT       = 3'b101;

    reg [2:0]  state_reg, state_next;
    reg [15:0] clk_count_reg, clk_count_next;
    reg [2:0]  bit_index_reg, bit_index_next;
    reg [7:0]  rx_shift_reg, rx_shift_next;
    reg        rx_parity_bit_reg, rx_parity_bit_next;

    // Synchronizer flip-flops to prevent metastability on asynchronous input
    reg rx_sync_1, rx_sync_2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync_1 <= 1'b1;
            rx_sync_2 <= 1'b1;
        end else begin
            rx_sync_1 <= rx_serial;
            rx_sync_2 <= rx_sync_1;
        end
    end

    // Sequential Process
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg         <= STATE_IDLE;
            clk_count_reg     <= 16'd0;
            bit_index_reg     <= 3'd0;
            rx_shift_reg      <= 8'd0;
            rx_parity_bit_reg <= 1'b0;
            rx_data           <= 8'd0;
            rx_valid          <= 1'b0;
            sample_pulse      <= 1'b0;
            parity_error      <= 1'b0;
            framing_error     <= 1'b0;
        end else begin
            state_reg         <= state_next;
            clk_count_reg     <= clk_count_next;
            bit_index_reg     <= bit_index_next;
            rx_shift_reg      <= rx_shift_next;
            rx_parity_bit_reg <= rx_parity_bit_next;

            // Default strobes
            sample_pulse <= 1'b0;
            rx_valid     <= 1'b0;

            case (state_reg)
                STATE_IDLE: begin
                    // Maintain idle registers
                end

                STATE_START_CHECK: begin
                    if (clk_count_reg == ((CLKS_PER_BIT / 2) - 1)) begin
                        sample_pulse <= 1'b1; // Sample midpoint of start bit
                    end
                end

                STATE_DATA_BITS: begin
                    if (clk_count_reg == (CLKS_PER_BIT - 1)) begin
                        sample_pulse <= 1'b1; // Sample midpoint of data bit
                    end
                end

                STATE_PARITY_CHECK: begin
                    if (clk_count_reg == (CLKS_PER_BIT - 1)) begin
                        sample_pulse <= 1'b1; // Sample midpoint of parity bit
                    end
                end

                STATE_STOP_CHECK: begin
                    if (clk_count_reg == (CLKS_PER_BIT - 1)) begin
                        sample_pulse <= 1'b1; // Sample midpoint of stop bit
                    end
                end

                STATE_OUTPUT: begin
                    rx_data <= rx_shift_reg;

                    // Parity Verification: calculated even parity must match received parity bit
                    if ((^rx_shift_reg) != rx_parity_bit_reg) begin
                        parity_error <= 1'b1;
                    end else begin
                        parity_error <= 1'b0;
                    end

                    // Framing Verification: stop bit must be '1'
                    if (rx_sync_2 != 1'b1) begin
                        framing_error <= 1'b1;
                    end else begin
                        framing_error <= 1'b0;
                    end

                    // Only assert rx_valid if no framing error occurred
                    if (rx_sync_2 == 1'b1) begin
                        rx_valid <= 1'b1;
                    end
                end

                default: begin
                    rx_valid <= 1'b0;
                end
            endcase
        end
    end

    // Combinational Next-State Logic
    always @(*) begin
        state_next         = state_reg;
        clk_count_next     = clk_count_reg;
        bit_index_next     = bit_index_reg;
        rx_shift_next      = rx_shift_reg;
        rx_parity_bit_next = rx_parity_bit_reg;

        case (state_reg)
            // Wait for falling edge indicating Start Bit
            STATE_IDLE: begin
                clk_count_next = 16'd0;
                bit_index_next = 3'd0;
                if (rx_sync_2 == 1'b0) begin
                    state_next = STATE_START_CHECK;
                end
            end

            // Verify start bit at center (CLKS_PER_BIT / 2) to reject noise glitch
            STATE_START_CHECK: begin
                if (clk_count_reg == ((CLKS_PER_BIT / 2) - 1)) begin
                    if (rx_sync_2 == 1'b0) begin
                        // Valid start bit confirmed; reset counter for full bit period
                        clk_count_next = 16'd0;
                        state_next     = STATE_DATA_BITS;
                    end else begin
                        // False alarm / noise spike: revert to IDLE
                        state_next = STATE_IDLE;
                    end
                end else begin
                    clk_count_next = clk_count_reg + 1'b1;
                end
            end

            // Sample 8 data bits sequentially at each bit center
            STATE_DATA_BITS: begin
                if (clk_count_reg < (CLKS_PER_BIT - 1)) begin
                    clk_count_next = clk_count_reg + 1'b1;
                end else begin
                    clk_count_next = 16'd0;
                    rx_shift_next[bit_index_reg] = rx_sync_2; // Sample LSB first

                    if (bit_index_reg < 3'd7) begin
                        bit_index_next = bit_index_reg + 1'b1;
                    end else begin
                        bit_index_next = 3'd0;
                        state_next     = STATE_PARITY_CHECK;
                    end
                end
            end

            // Sample parity bit
            STATE_PARITY_CHECK: begin
                if (clk_count_reg < (CLKS_PER_BIT - 1)) begin
                    clk_count_next = clk_count_reg + 1'b1;
                end else begin
                    clk_count_next     = 16'd0;
                    rx_parity_bit_next = rx_sync_2;
                    state_next         = STATE_STOP_CHECK;
                end
            end

            // Sample stop bit (must be HIGH)
            STATE_STOP_CHECK: begin
                if (clk_count_reg < (CLKS_PER_BIT - 1)) begin
                    clk_count_next = clk_count_reg + 1'b1;
                end else begin
                    clk_count_next = 16'd0;
                    state_next     = STATE_OUTPUT;
                end
            end

            // Output strobe & error status
            STATE_OUTPUT: begin
                state_next = STATE_IDLE;
            end

            default: begin
                state_next = STATE_IDLE;
            end
        endcase
    end

endmodule
