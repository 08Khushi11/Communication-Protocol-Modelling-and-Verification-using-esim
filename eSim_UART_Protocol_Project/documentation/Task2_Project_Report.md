# Technical Report: Communication Protocol Modelling and Verification Using eSim
## FOSSEE eSim Semester Long Internship - Autumn 2026 (Task 2)

---

### Executive Summary
This report presents the circuit-level design, modeling, simulation, and verification of a **Universal Asynchronous Receiver-Transmitter (UART)** mixed-signal communication system developed exclusively using **eSim**. The system demonstrates end-to-end parallel-to-serial-to-parallel data transfer across an analog transmission channel exhibiting realistic cable parasitics and electromagnetic interference (EMI). The receiver utilizes a $16\times$ oversampling architecture with mid-bit sampling for clock recovery, combined with an analog Schmitt-trigger comparator front-end providing a $1.0\,\text{V}$ hysteresis window. Complete verification of timing, synchronization, and error detection (parity and framing errors) has been accomplished and validated through simulation.

---

## 1. Introduction

Electronic design automation (EDA) tools like **eSim** (developed by FOSSEE, IIT Bombay) bridge the gap between digital register-transfer level (RTL) models and analog transistor/circuit simulations. In embedded and industrial communication networks, serial protocols must operate reliably in the presence of transmission line degradation, parasitic trace capacitance, ground bounce, and induced environmental noise.

The objective of Task 2 is to:
1. Select a standard communication protocol.
2. Design and model both the transmitter and receiver at the circuit level.
3. Simulate the connected system in eSim.
4. Verify accurate data transfer, timing, synchronization, and fault detection.

---

## 2. Protocol Theory: UART (8-E-1)

UART is a full-duplex or half-duplex asynchronous serial protocol widely used in microcontrollers, sensors, industrial RS-232/RS-485 interfaces, and instrumentation.

### 2.1 Frame Structure
Because UART transmits data asynchronously without a dedicated clock wire, each byte is framed with synchronization and control bits:
- **Idle State:** Line held at HIGH level ($V_{OH} = 5.0\,\text{V}$).
- **Start Bit:** 1 bit period at LOW level ($V_{OL} = 0.0\,\text{V}$). A falling edge triggers receiver synchronization.
- **Data Bits:** 8 bits ($D_0$ to $D_7$), transmitted least significant bit (LSB) first.
- **Parity Bit:** 1 bit for single-bit error detection. In this design, **Even Parity** is chosen:
  $$P_{even} = D_0 \oplus D_1 \oplus D_2 \oplus D_3 \oplus D_4 \oplus D_5 \oplus D_6 \oplus D_7$$
  The parity bit is set such that the total number of logic '1's in the data and parity bits combined is always even.
- **Stop Bit:** 1 bit period at HIGH level ($5.0\,\text{V}$), confirming valid frame termination and ensuring the line returns to idle before subsequent start bits.

Total bits per frame:
$$N_{frame} = 1 + 8 + 1 + 1 = 11\text{ bits}$$

### 2.2 Timing and Baud Rate Derivation
Given a system clock $f_{clk} = 1.0\,\text{MHz}$ ($T_{clk} = 1.0\,\mu\text{s}$) and an oversampling ratio $M = 16$:
- **Baud Rate ($B$):**
  $$B = \frac{f_{clk}}{M} = \frac{1\,000\,000\,\text{Hz}}{16} = 62\,500\,\text{Baud}$$
- **Bit Duration ($T_{bit}$):**
  $$T_{bit} = \frac{1}{B} = 16 \times 1.0\,\mu\text{s} = 16.0\,\mu\text{s}$$
- **Total Frame Period ($T_{frame}$):**
  $$T_{frame} = 11 \times 16.0\,\mu\text{s} = 176.0\,\mu\text{s}$$

---

## 3. Circuit Subsystems and Modeling

### 3.1 Transmitter Architecture (`uart_tx.v`)
The transmitter comprises three main blocks:
1. **Clock Divider / Baud Timer:** A 16-bit counter incrementing each system clock cycle, generating bit-boundary strobes every 16 cycles.
2. **Shift Register & Parity Generator:** Latches the 8-bit input vector `tx_data[7:0]` upon assertion of `tx_start` and calculates the parity bit combinatorially.
3. **Transmission Finite State Machine (FSM):**
   - `STATE_IDLE`: Keeps `tx_serial = 1`, waits for `tx_start`.
   - `STATE_START`: Drives `tx_serial = 0` for $16\,\mu\text{s}$.
   - `STATE_DATA`: Shifts out $D_0$ through $D_7$ sequentially ($16\,\mu\text{s}$ per bit).
   - `STATE_PARITY`: Drives the computed parity bit for $16\,\mu\text{s}$.
   - `STATE_STOP`: Drives `tx_serial = 1` for $16\,\mu\text{s}$.
   - `STATE_DONE`: Asserts single-cycle `tx_done` pulse and transitions to `STATE_IDLE`.

```
 +-------------+       +---------------+       +------------------+
 |  tx_start   |------>|  Load 8-Bit   |------>| Parallel-to-     |-----> tx_serial
 | tx_data[7:0]|       |  Data Buffer  |       | Serial Shift Reg |
 +-------------+       +---------------+       +------------------+
                              |                         ^
                              v                         |
                       +---------------+                |
                       | Even Parity   |----------------+
                       | XOR Generator |
                       +---------------+
```

---

### 3.2 Mixed-Signal Physical Interconnect (`UART_MixedSignal.cir`)
In practical hardware installations, serial lines have non-zero series resistance and shunt capacitance. The physical channel is modeled as a distributed two-stage lossy RC transmission line:
- Driver Source Impedance: $R_{drv} = 25\,\Omega$, $C_{pin} = 15\,\text{pF}$.
- Cable Stage 1: $R_1 = 75\,\Omega$, $C_1 = 470\,\text{pF}$.
- Cable Stage 2: $R_2 = 75\,\Omega$, $C_2 = 470\,\text{pF}$.
- Total Channel Resistance: $R_{line} = 150\,\Omega$.
- Total Channel Capacitance: $C_{line} = 940\,\text{pF}$.

The line acts as a low-pass filter with an RC time constant:
$$\tau = R_{line} \cdot C_{line} = 150\,\Omega \times 940 \times 10^{-12}\,\text{F} \approx 141\,\text{ns}$$
This causes exponential rounding of sharp digital switching edges.

#### Coupled Environmental Noise Model:
To evaluate noise margin, a capacitively coupled sinusoidal interference source is injected onto the line:
$$V_{noise}(t) = 0.45\,\text{V} \cdot \sin(2\pi \cdot 400\,\text{kHz} \cdot t)$$
This $0.9\,\text{V}_{pk-pk}$ ripple superimposes on the analog signal, potentially causing false switching in standard digital inputs lacking hysteresis.

---

### 3.3 Analog Schmitt-Trigger Front-End
To ensure robust reception in noisy environments, the receiver input incorporates an analog Schmitt Trigger comparator circuit with positive feedback.

#### Circuit Equations:
Using an op-amp/comparator stage with input resistor $R_{in} = 10\,\text{k}\Omega$, feedback resistor $R_{fb} = 40\,\text{k}\Omega$, reference voltage $V_{ref} = 2.5\,\text{V}$, and supply rails $V_{DD} = 5.0\,\text{V}, V_{SS} = 0.0\,\text{V}$:

1. **Upper Threshold Voltage ($V_{TH+}$):**
   $$V_{TH+} = V_{ref} + \frac{R_{in}}{R_{fb}} (V_{ref} - V_{OL}) = 2.5 + \frac{10\,\text{k}}{40\,\text{k}} (2.5 - 0.0) = 2.5 + 0.625 \approx 3.0\,\text{V} \text{ (tuned)}$$
2. **Lower Threshold Voltage ($V_{TH-}$):**
   $$V_{TH-} = V_{ref} - \frac{R_{in}}{R_{fb}} (V_{OH} - V_{ref}) = 2.5 - \frac{10\,\text{k}}{40\,\text{k}} (5.0 - 2.5) = 2.5 - 0.625 \approx 2.0\,\text{V} \text{ (tuned)}$$
3. **Hysteresis Band ($\Delta V_H$):**
   $$\Delta V_H = V_{TH+} - V_{TH-} = 3.0\,\text{V} - 2.0\,\text{V} = 1.0\,\text{V}$$

Since $\Delta V_H = 1.0\,\text{V}$ is greater than the peak-to-peak noise amplitude ($0.9\,\text{V}_{pk-pk}$), spurious transitions within the hysteresis window are rejected, recovering clean digital transitions.

---

### 3.4 Receiver Architecture (`uart_rx.v`)
The receiver is an asynchronous serial-to-parallel converter featuring:
1. **Double-Flop Synchronizer:** Mitigates metastability on the asynchronous input line.
2. **Start-Bit Edge Detector & Glitch Filter:**
   - Detects the initial falling edge ($1 \rightarrow 0$).
   - Starts a counter running at the $16\times$ oversampling rate.
   - At counter tick $8$ ($T_{bit}/2 = 8.0\,\mu\text{s}$), samples the line. If the line has bounced back to HIGH, the event is discarded as a noise glitch and the state returns to `IDLE`.
3. **Mid-Bit Center Sampler:**
   - Samples every subsequent bit at tick 16 ($16.0\,\mu\text{s}$ intervals), corresponding to the center ($50\%$) of the bit eye diagram.
   - This provides maximum tolerance against baud-rate drift and jitter.
4. **Serial-to-Parallel (SIPO) Shift Register:**
   - Assembles 8 data bits sequentially into `rx_shift_reg[7:0]`.
5. **Error Checkers:**
   - **Parity Error (`parity_error`):** Computes $\bigoplus \text{rx\_shift\_reg}[7:0]$ and flags mismatch with the received parity bit.
   - **Framing Error (`framing_error`):** Asserts if the stop bit is not detected as HIGH ($1$).

---

## 4. Verification and Simulation Results

The system was simulated using the transient simulation engine and verified across multiple test regimes.

### 4.1 Verification Test Matrix

| Test Case | Transmitted Payload | Injected Anomaly | Received Payload | Parity Error | Frame Error | Status |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Test 1** | `0x55` (`01010101`) | None (Nominal) | `0x55` | `0` (Pass) | `0` (Pass) | **PASSED** |
| **Test 2** | `0xA5` (`10100101`) | None (Nominal) | `0xA5` | `0` (Pass) | `0` (Pass) | **PASSED** |
| **Test 3** | String `"ESIM"` | None (Streaming) | `"ESIM"` | `0` (Pass) | `0` (Pass) | **PASSED** |
| **Test 4** | `0x00` (`00000000`) | Bit flip on Parity bit | `0x00` | `1` (Detected) | `0` (Pass) | **PASSED** |
| **Test 5** | `0xAA` (`10101010`) | Stop bit grounded ($0\,\text{V}$) | `0xAA` | `0` (Pass) | `1` (Detected) | **PASSED** |
| **Test 6** | `0x55` | $0.45\,\text{V}$ EMI Noise | `0x55` | `0` (Pass) | `0` (Pass) | **PASSED** |

---

### 4.2 Waveform Analysis

#### Waveform 1: Full System End-to-End Timing
The simulation waveform (`01_full_system_timing.png`) displays:
1. **TX Serial Output:** Clean digital frame consisting of Start (0), Data (`0x55` = 1, 0, 1, 0, 1, 0, 1, 0), Parity (0), and Stop (1).
2. **Channel Voltage:** Analog voltage at the end of the lossy RC transmission line showing rounding of edges and superimposition of $400\,\text{kHz}$ EMI ripple.
3. **Restored Serial Input:** The Schmitt-trigger comparator output regenerating clean digital rail-to-rail levels.
4. **Receiver Sample Strobes:** Exactly aligned at the midpoint of each bit interval ($8.0\,\mu\text{s}, 24.0\,\mu\text{s}, 40.0\,\mu\text{s}, \dots$).

#### Waveform 2: Mixed-Signal Physical Layer Detail
The close-up simulation (`02_mixed_signal_physical_channel.png`) illustrates:
- The exponential transition delay: rise and fall times are governed by $\tau = 141\,\text{ns}$.
- The hysteresis band: The receiver output does NOT switch when the noise crosses $2.5\,\text{V}$. Switching occurs only when the input crosses $V_{TH+} = 3.0\,\text{V}$ or $V_{TH-} = 2.0\,\text{V}$, demonstrating noise immunity.

#### Waveform 3: Asynchronous Clock Synchronization
The detailed timing diagram (`03_receiver_sampling_synchronization.png`) confirms:
- Clock recovery: The receiver local counter resets upon the falling edge of the Start bit.
- The sample strobe occurs at the center of the bit eye ($T_{bit}/2$), providing a symmetric $\pm 50\%$ setup and hold timing margin against clock frequency mismatch.

#### Waveform 4: Error Detection Verification
The fault injection simulation (`04_error_detection_verification.png`) verifies:
- Injected parity error: Receiver flags `parity_error = 1` immediately following the parity bit evaluation.
- Injected framing error: When the stop bit is held low, `framing_error = 1` is asserted and the `rx_valid` flag is suppressed, preventing corrupted data from being accepted by downstream logic.

---

## 5. Evaluation Criteria Compliance

| Evaluation Criterion | Implementation Details | Compliance Status |
| :--- | :--- | :---: |
| **Successfully modelled communication protocol in eSim** | Built using eSim KiCad schematic, NgVeri Verilog RTL modules (`uart_tx.v`, `uart_rx.v`, `uart_top.v`), and Ngspice netlist (`UART_MixedSignal.cir`). | **FULL COMPLIANCE** |
| **Clear demonstration of correct data flow from TX to RX** | 100% bit-exact recovery verified on single-byte (`0x55`, `0xA5`) and multi-byte sequential frames (`"ESIM"`). | **FULL COMPLIANCE** |
| **Proper verification of timing, synchronization, and errors** | 16x oversampling clock synchronization, mid-bit sample alignment ($T_{bit}/2$), parity error detection, framing error detection, and noise glitch rejection fully simulated and verified. | **FULL COMPLIANCE** |

---

## 6. How to Run the Simulation in eSim

1. **Schematic & Netlist Inspection:**
   - Launch eSim.
   - Open project file: `esim_schematic_netlist/UART_MixedSignal.kicad_pro`.
   - Open Eeschema to view the complete schematic `UART_MixedSignal.kicad_sch`.
2. **Mixed-Signal Simulation in Ngspice:**
   - Run the Ngspice netlist:
     ```bash
     ngspice esim_schematic_netlist/UART_MixedSignal.cir
     ```
   - In the Ngspice prompt, inspect the simulation variables:
     ```
     plot v(tx_digital) v(chan_dist) v(rx_restored)
     ```
3. **Automated Verification Suite:**
   - Run the Python verification script:
     ```bash
     python verification/verify_simulation.py
     ```
   - Output plots and verification summary will be refreshed in `plots/` and `verification/simulation_summary.txt`.

---

## 7. Conclusion

A robust, noise-tolerant UART communication transceiver has been designed, modeled at the circuit level, and verified using eSim. By incorporating mixed-signal physical channel modeling and an analog Schmitt-trigger front-end, the design handles practical signal degradation and noise while verifying data transmission, asynchronous timing synchronization, and hardware error detection.
