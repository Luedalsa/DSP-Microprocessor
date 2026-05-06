# DSP Microprocessor — Digital Signal Generation & Processing

A custom RISC-like softcore processor designed for parallel, memory-to-memory digital signal processing on FPGAs. Version history and comparisons are tracked in the Git log.

---

## Overview

This is a minimalist, Harvard-architecture microprocessor optimized for DSP workloads. It borrows several traits from VLIW designs while remaining a RISC core, with a focus on high clock frequency, low resource utilization, and efficient parallel data processing.

---

## Key Features

- **Dual 32-bit registers** with fixed-size 32-bit instructions
- **Dual opcode system** — primary opcode + sub-opcode for data operations (preserved from original design)
- **VLIW-like parallelism** — up to 12 operations per cycle (+16 ALU ops)
- **Pipelined multiplier** (4 cycles) and **pipelined divider/modulo** (34 cycles), decoupled so other non-dependent instructions can execute concurrently
- **Dual-port memory access** — can read and/or write to 2 addresses simultaneously
- **Single-cycle execution** for nearly all instructions, including most memory reads and writes
- **2-stage pipeline**
- **Multi-master capable** — has its own buffer for incoming samples
- **Minimalist architecture** — small footprint, high frequency

---

## Architecture Decisions

### Von Neumann → Harvard
**Problem:** Von Neumann bottleneck was limiting throughput.  
**Solution:** Switched to Harvard architecture, using the FPGA's built-in Dual-Port BRAM. This simplified the finite state machine, increased maximum frequency, and eliminated the memory bus bottleneck at the cost of a minimal increase in routing complexity.

### Pipelined Multiply & Divide
**Problem:** A combinational multiplier increased the critical path by ~400%; the divider consumed ~500% more area.  
**Solution:** Both operations are segmented and decoupled — `MUL`/`RECM` for multiplication (4 cycles) and `DIV`/`RECD` for division (34 cycles) — allowing other independent instructions to execute in parallel.

### Flexible Memory Access
**Problem:** Stack-based memory limited addressing flexibility.  
**Solution:** Eliminated the stack in favor of direct-address memory access, enabling arbitrary read/write locations and easier variable management. Trade-off: one additional pipeline stage.

### RESET Fanout
**Problem:** The RESET signal had excessively high fanout.  
**Solution:** Routed RESET through global FPGA buffers.

### Memory Access Latency
**Problem:** Memory operations required one cycle for the address and another for the data.  
**Proposed solution:** Desynchronize the instruction from the address/data by one clock cycle using an intermediate register, and insert intermediate registers in the opcodes to pre-fetch memory accesses.  
**Alternative considered:** Stack-based addressing (rejected — removes write flexibility).

### SWP Structural Hazard
**Problem:** The `SWP` instruction introduced a structural hazard due to the dual-opcode system.  
**Solution 1:** Separate copy instructions — `A→B` as primary opcode, `B→A` as sub-opcode (1 cycle).  
**Solution 2:** Use a data bit (desynchronized 1 cycle ahead of opcodes) with a bus switch to swap A and B roles on the next clock cycle (0 cycles).

---

## Data Hazard Table

| Operation      | Cycles to Complete | Solution                                      |
|----------------|--------------------|-----------------------------------------------|
| Division       | 34                 | Two separate instructions: `DIV`, `RECD`      |
| Multiplication | 4                  | Two separate instructions: `MUL`, `RECM`      |
| Write          | 2                  | Data and operation desynchronized (same instr)|
| Read           | 2                  | Same as above                                 |

> The compiler will handle hazard scheduling automatically.

---

## Performance & Resource Comparison

| Processor          | FMax          | LUTs        | FFs         | BRAM  | DSP |
|--------------------|---------------|-------------|-------------|-------|-----|
| **This design**    | **284 MHz**   | **568**     | **420**     | 2     | 3   |
| MicroBlaze (AMD)   | 137–267 MHz   | 625–9366    | 227–8725    | 0–20  | —   |
| PicoRV32           | 250–450 MHz   | 750–2000    | —           | —     | —   |
| VexRiscv           | 151–243 MHz   | 504–2883    | 505–2130    | —     | —   |
| Intel Nios II      | —             | —           | —           | —     | —   |
| ARM Cortex-M1      | —             | —           | —           | —     | —   |
| LatticeMicro32     | —             | —           | —           | —     | —   |

---

## Limitations

- **No dedicated MAC unit** — multiply-accumulate must be done in software
- **Unusual ISA** — requires a custom compiler (in progress)

---

## I/O Protocol

SPI is used for all data I/O: instruction writes, input variables, and audio output.

---

## References

- [MicroBlaze MCS Parameter Values — AMD](https://docs.amd.com/r/en-US/pg440-microblaze-mcs-v/Parameter-Values)
- [MicroBlaze MCS v3.0 Performance & Resource Utilization — AMD](https://download.amd.com/docnav/documents/ip_attachments/microblaze-mcs.html)
- [VexRiscv — SpinalHDL (GitHub)](https://github.com/SpinalHDL/VexRiscv)
- [7 Series DSP48E1 Slice User Guide (UG479)](https://0x04.net/~mwk/xidocs/ug/ug479_7Series_DSP48E1.pdf)
