# RISC-V Simulation Log Analyzer

[![Bash](https://img.shields.io/badge/Bash-121011?style=flat-square&logo=gnu-bash&logoColor=white)]()
[![Make](https://img.shields.io/badge/Make-008080?style=flat-square&logo=gnu&logoColor=white)]()
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat-square&logo=linux&logoColor=black)]()
[![Status](https://img.shields.io/badge/Status-Completed-success)]()
[![License](https://img.shields.io/badge/license-MIT-green)]()


## Description
`riscv-log-analyzer` is a shell-based automation tool designed to process RISC-V simulation log files. It extracts critical execution metrics, calculates pass/fail rates, isolates failing tests, and computes execution timing statistics (minimum, maximum, and average times). 

This project demonstrates core Linux text processing (`grep`, `awk`), Bash scripting with strict error handling, and `make` build automation.

## Project Structure
* `scripts/` - Contains the main analysis engine and environment setup scripts.
* `test_data/` - Synthetic RISC-V execution logs used for testing.
* `output/` - Directory for generated summary reports (ignored by Git).
* `Makefile` - Automation hub for testing and report generation.

## Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/husnainjatoi/riscv-log-analyzer
   cd riscv-log-analyzer
   ```

2. **Verify Environment Dependencies:**
   Ensure your system has `bash`, `grep`, `awk`, and `date` installed.
   ```bash
   make setup
   ```

## Quick Start Usage

**To run the analyzer against all test logs and view the output in your terminal:**
```bash
make test
```

**To generate saved text reports for all logs in the `output/` directory:**
```bash
make report
```

## Sample Output
Running the analyzer against a failing log (`test_data/sample_fail.log`) produces the following formatted summary:

```text
=== RISC-V Simulation Log Analysis ===
Log file: test_data/sample_fail.log
Analysis date: 2026-05-30 17:15:00

--- Results Summary ---
Total tests: 25
Passed:      22 (88.0%)
Failed:       2 ( 8.0%)
Skipped:      1 ( 4.0%)

--- Failed Tests ---
  1. rv32i-sll
  2. rv32i-beq

--- Timing Statistics ---
Min time:  0.42s (rv32i-nop)
Max time:  2.31s (rv32i-mul)
Avg time:  0.87s

--- Verdict: FAIL ---
Exit code: 1
```
