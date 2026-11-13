# SoC Verification Portfolio

A solo, open-source learning project: a small RISC-V based SoC that is designed and verified in layers, using only free tools, open cores and public specs.

**Goal:** understand how design, verification and DFT of an SoC with DDR and PCIe work in practice, and publish verified blocks and reusable verification IP along the way.

## Phases

Each phase ends with a demo in this repo. The next phase does not start until the current demo is done.

| # | Phase | What gets built | Done when |
|---|-------|-----------------|-----------|
| 0 | Setup | WSL2, Verilator, RISC-V toolchain, Ibex simple system, Vivado xsim | Ibex runs a program; a UVM test runs on xsim |
| 1 | Core DV | Spike reference model, Ibex DV flow, riscv-dv, own tests | Coverage report, holes found and closed |
| 2 | Bus fabric | OBI to AXI-Lite bridge, AXI-Lite interconnect, AXI-Lite UVM agent with protocol assertions | Agent and assertions pass on the interconnect, with coverage |
| 3 | DMA | Medium DMA engine (descriptors, interrupt, bus master) and its own UVM environment | Coverage closed; injected bugs all caught |
| 4 | Cache and DDR | Small cache and its env (optional); LiteDRAM as DUT with own DDR checker, behavioral model, assertions, coverage | DDR VIP and cache env with coverage report |
| 5 | Low power | Clock gating, isolation, retention on the DMA; UPF intent written | Power lab and notes |
| 6 | DFT | Scan chain on the DMA; ATPG and scan-mode checks | DFT lab and notes |
| 7 | PCIe | Small TLP to AXI-Lite bridge, TLP-level agent against open RTL | PCIe TLP lab |
| 8 | Integration | Ibex, bus, DMA, LiteDRAM and DDR checker running real software | Final README and demo |

## Architecture (target)

Ibex (OBI) -> OBI-to-AXI-Lite bridge -> AXI-Lite interconnect, with the DMA as a second master. Slaves: SRAM, DMA registers, and later the cache/DDR path and a PCIe-side block.

## Verification layers

- **Core level:** Ibex is treated as trusted; its DV flow is run where the free tools allow.
- **Block level:** every block I design gets its own UVM environment (driver, monitor, scoreboard, assertions, functional coverage) on Vivado xsim. One AXI-Lite agent is reused across blocks.
- **SoC level:** whole-system runs with Ibex executing C programs, on Verilator.

## Weekly routine

- Days 1-2: learn one concept from one source.
- Days 3-5: build a lab under 200 lines.
- Day 6: break it on purpose and write down what was learned.
- Day 7: commit, write a short README, rest.

## Rules

- One phase at a time.
- Public specs and open cores only. Nothing from employer work, even from memory.
- Do not copy spec text or vendor models into the repo.
- If Ibex's UVM flow will not run on xsim, build a smaller UVM environment on xsim and continue.
- UPF needs a power-aware simulator with no free option: do the concepts and RTL models, and add tool runs only with legitimate access.
- DDR and PCIe: verify open RTL and design only small bridges; no full controller or core from scratch.

## Tools (all free)

WSL2 + Ubuntu 22.04, Git/GitHub, Verilator v4.210 (the version Ibex pins), Icarus, GTKWave, lowRISC RISC-V toolchain, Spike, Vivado 2026.1 Basic (xsim with UVM), cocotb + pyuvm (fallback), Yosys, OpenLane, KLayout (later phases).

See [SETUP.md](SETUP.md) for exact install steps.
