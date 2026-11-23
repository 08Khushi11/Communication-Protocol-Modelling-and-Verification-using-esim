// ============================================================================
// File: uart_tx.v
// Module: UART Transmitter with Even Parity and Parameterized Baud Rate
// Project: eSim Semester Long Internship - Task 2: Communication Protocol Modeling
// Author: FOSSEE eSim Project Contributor
// Description:
//   Models a hardware-level UART transmitter module.
//   Serializes an 8-bit parallel data word into a standard 11-bit UART frame:
//   [1 START BIT (0)] + [8 DATA BITS (LSB FIRST)] + [1 PARITY BIT (EVEN)] + [1 STOP BIT (1)]
// ============================================================================

`timescale 1ns / 1ps

module uart_tx #(
    parameter CLKS_PER_BIT = 16  // Oversampling factor / clock divider per bit
)(
    input  wire       clk,       // System clock
    input  wire       rst_n,     // Active-low asynchronous reset
    input  wire       tx_start,  // Trigger pulse to initiate transmission
    input  wire [7:0] tx_data,   // 8-bit parallel payload to transmit
    output reg        tx_serial, // Serial line output (idle HIGH)
    output reg        tx_busy,   // High while a transmission frame is active
    output reg        tx_done    // Single-cycle strobe when transmission finishes
);

    // FSM State Encoding
    localparam [2:0] 
        STATE_IDLE    = 3'b000,
        STATE_START   = 3'b001,
        STATE_DATA    = 3'b010,
        STATE_PARITY  = 3'b011,
        STATE_STOP    = 3'b100,
        STATE_DONE    = 3'b101;

    reg [2:0]  state_reg, state_next;
    reg [15:0] clk_count_reg, clk_count_next;
    reg [2:0]  bit_index_reg, bit_index_next;
    reg [7:0]  data_reg, data_next;
    reg        parity_bit;

    // Even Parity Calculation: 1 if odd number of 1s (making total ones even)
    always @(*) begin
        parity_bit = ^data_reg;
    end

    // Sequential State & Counter Updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg      <= STATE_IDLE;
            clk_count_reg  <= 16'd0;
            bit_index_reg  <= 3'd0;
            data_reg       <= 8'd0;
            tx_serial      <= 1'b1;
            tx_busy        <= 1'b0;
            tx_done        <= 1'b0;
        end else begin
            state_reg      <= state_next;
            clk_count_reg  <= clk_count_next;
            bit_index_reg  <= bit_index_next;
            data_reg       <= data_next;

            // Output logic based on current state
            case (state_reg)
                STATE_IDLE: begin
                    tx_serial <= 1'b1;
                    tx_busy   <= 1'b0;
                    tx_done   <= 1'b0;
                end

                STATE_START: begin
                    tx_serial <= 1'b0; // Start bit is active LOW
                    tx_busy   <= 1'b1;
                    tx_done   <= 1'b0;
                end

                STATE_DATA: begin
                    tx_serial <= data_reg[bit_index_reg]; // LSB first
                    tx_busy   <= 1'b1;
                    tx_done   <= 1'b0;
                end

                STATE_PARITY: begin
                    tx_serial <= parity_bit; // Even parity bit
                    tx_busy   <= 1'b1;
                    tx_done   <= 1'b0;
                end

                STATE_STOP: begin
                    tx_serial <= 1'b1; // Stop bit is active HIGH
                    tx_busy   <= 1'b1;
                    tx_done   <= 1'b0;
                end

                STATE_DONE: begin
                    tx_serial <= 1'b1;
                    tx_busy   <= 1'b0;
                    tx_done   <= 1'b1; // Completion strobe
                end

                default: begin
                    tx_serial <= 1'b1;
                    tx_busy   <= 1'b0;
                    tx_done   <= 1'b0;
                end
            endcase
        end
    end

    // Combinational Next-State Logic
    always @(*) begin
        state_next      = state_reg;
        clk_count_next  = clk_count_reg;
        bit_index_next  = bit_index_reg;
        data_next       = data_reg;

        case (state_reg)
            STATE_IDLE: begin
                clk_count_next = 16'd0;
                bit_index_next = 3'd0;
                if (tx_start) begin
                    data_next  = tx_data; // Latch input data
                    state_next = STATE_START;
                end
            end

            STATE_START: begin
                if (clk_count_reg < (CLKS_PER_BIT - 1)) begin
                    clk_count_next = clk_count_reg + 1'b1;
                end else begin
                    clk_count_next = 16'd0;
                    state_next     = STATE_DATA;
                end
            end

            STATE_DATA: begin
                if (clk_count_reg < (CLKS_PER_BIT - 1)) begin
                    clk_count_next = clk_count_reg + 1'b1;
                end else begin
                    clk_count_next = 16'd0;
                    if (bit_index_reg < 3'd7) begin
                        bit_index_next = bit_index_reg + 1'b1;
                    end else begin
                        bit_index_next = 3'd0;
                        state_next     = STATE_PARITY;
                    end
                end
            end

            STATE_PARITY: begin
                if (clk_count_reg < (CLKS_PER_BIT - 1)) begin
                    clk_count_next = clk_count_reg + 1'b1;
                end else begin
                    clk_count_next = 16'd0;
                    state_next     = STATE_STOP;
                end
            end

            STATE_STOP: begin
                if (clk_count_reg < (CLKS_PER_BIT - 1)) begin
                    clk_count_next = clk_count_reg + 1'b1;
                end else begin
                    clk_count_next = 16'd0;
                    state_next     = STATE_DONE;
                end
            end

            STATE_DONE: begin
                state_next = STATE_IDLE;
            end

            default: begin
                state_next = STATE_IDLE;
            end
        endcase
    end

endmodule
