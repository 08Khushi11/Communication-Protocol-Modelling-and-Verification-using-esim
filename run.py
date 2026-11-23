#!/usr/bin/env python3
"""
Top-level runner for eSim UART Protocol Project.
Execute with:
    python run.py
"""

import sys
import os

script_dir = os.path.dirname(os.path.abspath(__file__))
sim_script = os.path.join(script_dir, "eSim_UART_Protocol_Project", "verification", "verify_simulation.py")

if not os.path.exists(sim_script):
    sim_script = os.path.join(script_dir, "verification", "verify_simulation.py")

if os.path.exists(sim_script):
    import runpy
    runpy.run_path(sim_script, run_name="__main__")
else:
    print(f"[!] Error: Could not locate verify_simulation.py at: {sim_script}")
    sys.exit(1)
