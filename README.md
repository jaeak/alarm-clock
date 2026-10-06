# FPGA Digital Alarm Clock (VHDL)

A fully functional digital alarm clock implemented on an FPGA using VHDL. Designed with a clean, modular hardware architecture, this project features precise timekeeping, FSM-driven mode control, custom alarm matching, and dynamic display multiplexing.

## Key Features

* **Precise Timekeeping Engine:** Utilizes clock divider logic to scale down the board clock into a stable 1 Hz tick, driving cascading second, minute, and hour counters in a 24-hour format.
* **Finite State Machine (FSM) Control:** Manages operational modes seamlessly via push-button inputs, allowing users to switch between normal display mode, time adjustment, and alarm configuration.
* **Alarm & Comparator Logic:** Continuously compares current time registers against preset alarm registers, triggering outputs when a match occurs.
* **Multiplexed Display Driver:** Drives multi-digit 7-segment displays through high-frequency multiplexing, minimizing hardware pin usage while maintaining a flicker-free visual output.
* **Input Debouncing:** Incorporates custom synchronization circuitry to eliminate mechanical switch bounce for reliable, glitch-free user inputs.

## 💻 Tech Stack & Tools
* **Language:** VHDL
* **Hardware:** Cyclone V FPGA (DE10-Standard)
* **Design & Simulation Tools:** Intel Quartus Prime, ModelSim
