# eSim Semester Long Internship - Autumn 2026: Task 2 Submission
## Communication Protocol Modelling and Verification Using eSim

**Project:** Circuit-Level Modeling & Verification of a Mixed-Signal UART Communication Transceiver  
**Protocol:** Universal Asynchronous Receiver-Transmitter (UART) 8-E-1 with 16x Oversampling Clock Recovery  
**EDA Tool:** eSim (KiCad Eeschema + NgVeri Verilog + Ngspice)

---

### Overview
This project contains the complete implementation, schematic designs, Verilog RTL models, Ngspice netlists, simulation plots, and documentation required for **Task 2 of the FOSSEE eSim Semester Long Internship - Autumn 2026**.

The design models a mixed-signal communication system comprising:
1. **Transmitter (TX):** Serializes an 8-bit parallel byte into an 11-bit UART frame with even parity generator and calibrated baud timer.
2. **Physical Interconnect:** Distributed lossy RC transmission line ($R = 150\,\Omega, C = 940\,\text{pF}$) subjected to coupled high-frequency EMI noise ($0.45\,\text{V}_{pk}$ @ $400\,\text{kHz}$).
3. **Analog Receiver Front-End:** Schmitt Trigger comparator with a $1.0\,\text{V}$ hysteresis window ($V_{TH+} = 3.0\,\text{V}, V_{TH-} = 2.0\,\text{V}$) for noise rejection and edge regeneration.
4. **Receiver (RX):** Asynchronous $16\times$ oversampling receiver with falling-edge start-bit synchronization, noise glitch filter, mid-bit eye-center sampling, SIPO shift register, and Parity/Framing error detectors.

---

### Directory Structure

```
eSim_UART_Protocol_Project/
├── README.md                      # This file
├── src_verilog/                   # Verilog RTL files (NgVeri compatible)
│   ├── uart_tx.v                  # UART Transmitter Module
│   ├── uart_rx.v                  # UART Receiver Module (16x oversampling)
│   ├── uart_top.v                 # Transceiver Top Module (Full Duplex)
│   └── uart_tb.v                  # Cycle-accurate verification testbench
├── esim_schematic_netlist/        # eSim / KiCad and Ngspice files
│   ├── UART_MixedSignal.kicad_sch # KiCad Eeschema schematic file
│   ├── UART_MixedSignal.kicad_pro # eSim Project file
│   └── UART_MixedSignal.cir       # Ngspice transient simulation netlist
├── verification/                  # Automated verification suite
│   ├── verify_simulation.py       # Mixed-signal transient simulation & plotting script
│   └── simulation_summary.txt     # Test report & metrics summary
├── plots/                         # High-resolution simulation plots
│   ├── 01_full_system_timing.png  # End-to-end multi-channel timing diagram
│   ├── 02_mixed_signal_physical_channel.png # Signal degradation & hysteresis restoration
│   ├── 03_receiver_sampling_synchronization.png # 16x clock sync & eye center sampling
│   └── 04_error_detection_verification.png # Parity & framing error verification
└── documentation/                 # Formal documents for submission
    ├── Task2_Project_Proposal.md  # Official Circuit Proposal document
    ├── Task2_Project_Report.md    # Comprehensive Technical Report
    └── Submission_Email_Task2.txt # Submission email draft for contact-esim@fossee.in
```

---

### How to Run the Verification Script

Ensure Python 3 with `numpy` and `matplotlib` is installed, then run:

```bash
cd eSim_UART_Protocol_Project
python verification/verify_simulation.py
```

This runs the transient simulation across all test cases (nominal, multi-byte, noise injection, parity error, framing error), asserts all assertions, and outputs the plots into the `plots/` directory.

---

### Evaluation Criteria Verification Matrix

| Criterion | Implementation | Result |
| :--- | :--- | :---: |
| **Modelled in eSim** | KiCad schematic (`.kicad_sch`), NgVeri modules (`.v`), and Ngspice netlist (`.cir`) | **PASS** |
| **Data Flow Demonstration** | Bit-exact recovery on `0x55`, `0xA5`, and continuous multi-byte stream `"ESIM"` | **PASS (100%)** |
| **Timing & Synchronization** | $16\times$ oversampled mid-bit clock recovery, glitch filter, and zero-drift sampling | **PASS** |
| **Error Verification** | Single-bit parity error and framing error detection verified | **PASS** |

---

### Submission Instructions
1. Review the proposal: `documentation/Task2_Project_Proposal.md`
2. Review the technical report: `documentation/Task2_Project_Report.md`
3. Send email to `contact-esim@fossee.in` with subject:  
   `"eSim Semester Long Internship - Autumn 2026 Submission Task 2"`  
   using the template in `documentation/Submission_Email_Task2.txt`.
