# 🔐 Secure Vault Unlock System — Hackathon Project (Pure Verilog)

This project was developed by **Dileep and team** as part of a **Hackathon conducted by Elevium**. It implements a **five-phase secure vault unlock system** using **pure Verilog**, all in a single file.

---

## 📌 Overview

The system mimics a layered security vault where each phase expects a unique unlock input:
- Phase 1: Serial code entry
- Phase 2: Parallel switch combination
- Phase 3: Directional pattern
- Phase 4: Binary plate pattern
- Phase 5: Timed lock sequence

A finite state machine (FSM) manages transitions between phases. On successful completion, the vault unlocks (`vault_escape` signal).

---

## 🔧 Inputs and Outputs

| Signal         | Description                          |
|----------------|--------------------------------------|
| `clk`, `reset` | Global clock and reset               |
| `code_in`      | Serial input for Phase 1             |
| `switch_in`    | 4-bit input for Phase 2              |
| `dir_in`       | 3-bit direction input for Phase 3    |
| `plate_in`     | 8-bit plate input for Phase 4        |
| `time_lock_out`| Timed 2-bit output from Phase 5      |
| `all_done`     | Indicates all phases passed          |
| `vault_escape` | Final unlock flag                    |

---

## 🛠 Tech Stack

- **Language:**Verilog
- **Design Style:** Behavioral + FSM
- **Simulation Tools:** EDA Playground
---
