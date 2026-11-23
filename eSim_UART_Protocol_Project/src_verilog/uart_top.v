// ============================================================================
// File: uart_top.v
// Module: UART Transceiver Top Module (Full-Duplex / Mixed-Signal Bridge)
// Project: eSim Semester Long Internship - Task 2: Communication Protocol Modeling
// Author: FOSSEE eSim Project Contributor
// Description:
//   Instantiates the UART Transmitter (TX) and Receiver (RX).
//   Provides external serial interface ports (tx_serial_out, rx_serial_in)
//   allowing mixed-signal co-simulation with an analog physical channel
//   (transmission line + Schmitt trigger) in eSim / NgVeri.
// ============================================================================

`timescale 1ns / 1ps

module uart_top #(
    parameter CLKS_PER_BIT = 16
)(
    input  wire       clk,             // System Clock (16x Baud Rate)
    input  wire       rst_n,           // Asynchronous Active-Low Reset
    
    // Transmitter Interface
    input  wire       tx_start,        // Trigger transmission
    input  wire [7:0] tx_data,         // 8-bit parallel byte to send
    output wire       tx_serial_out,   // Serial bitstream to analog physical channel
    output wire       tx_busy,         // Transmitter busy indicator
    output wire       tx_done,         // Transmit completed strobe
    
    // Receiver Interface
    input  wire       rx_serial_in,    // Serial bitstream returned from analog channel
    output wire [7:0] rx_data,         // 8-bit recovered parallel byte
    output wire       rx_valid,        // Asserted on valid frame reception
    output wire       sample_pulse,    // Pulse showing mid-bit sampling instance
    output wire       parity_error,    // Parity error flag
    output wire       framing_error    // Framing error flag
);

    // Instantiate UART Transmitter
    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_tx (
        .clk       (clk),
        .rst_n     (rst_n),
        .tx_start  (tx_start),
        .tx_data   (tx_data),
        .tx_serial (tx_serial_out),
        .tx_busy   (tx_busy),
        .tx_done   (tx_done)
    );

    // Instantiate UART Receiver
    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) u_uart_rx (
        .clk           (clk),
        .rst_n         (rst_n),
        .rx_serial     (rx_serial_in),
        .rx_data       (rx_data),
        .rx_valid      (rx_valid),
        .sample_pulse  (sample_pulse),
        .parity_error  (parity_error),
        .framing_error (framing_error)
    );

endmodule
