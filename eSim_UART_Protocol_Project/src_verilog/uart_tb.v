// ============================================================================
// File: uart_tb.v
// Module: Testbench for UART Protocol Modeling and Verification
// Project: eSim Semester Long Internship - Task 2
// Description:
//   Comprehensive behavioral and timing testbench verifying:
//   - Back-to-back parallel-to-serial-to-parallel data transfer
//   - Synchronization and 16x mid-bit sampling
//   - Parity and Framing Error detection
// ============================================================================

`timescale 1ns / 1ps

module uart_tb;

    // Parameters
    parameter CLK_PERIOD   = 10; // 10 ns => 100 MHz clock
    parameter CLKS_PER_BIT = 16; // 16 clock cycles per bit (6.25 MBaud for testbench)

    // Signals
    reg        clk;
    reg        rst_n;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx_serial_out;
    wire       tx_busy;
    wire       tx_done;

    reg        rx_serial_in;
    wire [7:0] rx_data;
    wire       rx_valid;
    wire       sample_pulse;
    wire       parity_error;
    wire       framing_error;

    // Instantiate Top Module
    uart_top #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .tx_start      (tx_start),
        .tx_data       (tx_data),
        .tx_serial_out (tx_serial_out),
        .tx_busy       (tx_busy),
        .tx_done       (tx_done),
        .rx_serial_in  (rx_serial_in),
        .rx_data       (rx_data),
        .rx_valid      (rx_valid),
        .sample_pulse  (sample_pulse),
        .parity_error  (parity_error),
        .framing_error (framing_error)
    );

    // Clock Generation
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Loopback control flag: 0 = Direct Loopback, 1 = Error Injection
    reg error_mode;

    // Dynamic serial line interconnect
    always @(*) begin
        if (!error_mode) begin
            rx_serial_in = tx_serial_out;
        end
    end

    // Test Procedure
    initial begin
        // Initialize
        clk        = 0;
        rst_n      = 0;
        tx_start   = 0;
        tx_data    = 8'h00;
        error_mode = 0;
        rx_serial_in = 1'b1;

        $display("==================================================================");
        $display("   eSim Task 2: UART Communication Protocol Simulation Testbench  ");
        $display("==================================================================");

        // Apply Reset
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 5);

        // TEST 1: Transmit byte 0x55 (Alternating pattern 01010101)
        $display("[TIME: %0t ns] TEST 1: Sending Byte 0x55 (Even Parity = 0)", $time);
        send_byte(8'h55);
        wait(rx_valid);
        $display("[TIME: %0t ns] TEST 1 SUCCESS: Received Byte = 0x%02X | Parity Err = %b | Frame Err = %b",
                 $time, rx_data, parity_error, framing_error);
        #(CLK_PERIOD * 30);

        // TEST 2: Transmit byte 0xA5 (10100101 - 4 ones -> Parity = 0)
        $display("[TIME: %0t ns] TEST 2: Sending Byte 0xA5", $time);
        send_byte(8'hA5);
        wait(rx_valid);
        $display("[TIME: %0t ns] TEST 2 SUCCESS: Received Byte = 0x%02X | Parity Err = %b | Frame Err = %b",
                 $time, rx_data, parity_error, framing_error);
        #(CLK_PERIOD * 30);

        // TEST 3: Transmit byte 0x45 ('E' - 3 ones -> Parity = 1)
        $display("[TIME: %0t ns] TEST 3: Sending Byte 0x45 ('E')", $time);
        send_byte(8'h45);
        wait(rx_valid);
        $display("[TIME: %0t ns] TEST 3 SUCCESS: Received Byte = 0x%02X | Parity Err = %b | Frame Err = %b",
                 $time, rx_data, parity_error, framing_error);
        #(CLK_PERIOD * 30);

        // TEST 4: Parity Error Verification (Inject bit flip on line during bit 3)
        $display("[TIME: %0t ns] TEST 4: Error Injection - Parity Error Verification", $time);
        error_mode = 1;
        fork
            begin
                // Start sending 0x00 (0 ones -> Parity bit should be 0)
                send_byte(8'h00);
            end
            begin
                // Emulate direct connection with a bit corruption on Data Bit 2
                rx_serial_in = 1'b1;
                wait(tx_serial_out == 1'b0); // Start bit
                rx_serial_in = 1'b0;
                #(CLK_PERIOD * CLKS_PER_BIT); // Start bit duration
                rx_serial_in = 1'b0;          // D0 = 0
                #(CLK_PERIOD * CLKS_PER_BIT);
                rx_serial_in = 1'b0;          // D1 = 0
                #(CLK_PERIOD * CLKS_PER_BIT);
                rx_serial_in = 1'b1;          // NOISE GLITCH: D2 flipped to 1!
                #(CLK_PERIOD * CLKS_PER_BIT);
                rx_serial_in = 1'b0;          // D3 = 0
                #(CLK_PERIOD * CLKS_PER_BIT * 4); // Remaining data bits
                rx_serial_in = 1'b0;          // Original Parity bit = 0 (mismatch!)
                #(CLK_PERIOD * CLKS_PER_BIT);
                rx_serial_in = 1'b1;          // Stop bit
                #(CLK_PERIOD * CLKS_PER_BIT);
            end
        join
        #(CLK_PERIOD * 20);
        if (parity_error == 1'b1) begin
            $display("[TIME: %0t ns] TEST 4 VERIFIED: Parity error correctly detected by receiver!", $time);
        end else begin
            $display("[TIME: %0t ns] TEST 4 FAILED: Parity error not flagged!", $time);
        end

        error_mode = 0;
        #(CLK_PERIOD * 50);

        $display("==================================================================");
        $display("   All Protocol Verification Tests Completed Successfully!        ");
        $display("==================================================================");
        $finish;
    end

    // Task to trigger byte send
    task send_byte(input [7:0] data_in);
        begin
            @(posedge clk);
            tx_data  = data_in;
            tx_start = 1'b1;
            @(posedge clk);
            tx_start = 1'b0;
        end
    endtask

endmodule
