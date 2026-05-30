# Command Reference Guide

This document outlines the detailed usage of the underlying scripts and automation targets for the RISC-V Log Analyzer.

## The Analysis Script (`scripts/analyze.sh`)

The core engine can be executed manually for granular control over individual log files.

**Syntax:**
```bash
./scripts/analyze.sh <path_to_log_file> [options]
```

**Positional Arguments:**
* `$1` (Required): The relative or absolute path to the RISC-V log file you wish to analyze.

**Options / Flags:**
* `--format [text/csv]`: Defines the output format. *(Note: CSV formatting is a planned future feature; defaults to text).*
* `--output <path>`: Redirects the generated summary to a specific file path. If omitted, the script prints to standard output (the terminal).
* `--verbose`: Enables verbose debugging output *(placeholder for future implementation)*.
* `--help`: Prints the help menu and immediately exits with code 0.

**Exit Codes:**
* `0`: Script executed successfully AND all parsed tests passed.
* `1`: Script failed due to missing arguments, missing files, missing dependencies, OR the log file contained one or more `FAIL` results.

---

## Automation Targets (`Makefile`)

The `Makefile` at the root of the project provides standard targets to automate repetitive workflows.

**Available Commands:**

* `make setup`
  Executes `scripts/setup_env.sh`. Verifies that all required POSIX utilities (`bash`, `grep`, `awk`, `date`) are available in the current environment's `$PATH`.

* `make test`
  Iterates through every `.log` file located in the `test_data/` directory and executes the analyzer script, printing the results directly to the terminal. Useful for rapid visual validation.

* `make all`
  Utilizes Makefile pattern rules to map every `.log` input in `test_data/` to a corresponding `.report.txt` output file inside the `output/` directory.

* `make report`
  An alias for `make all` that provides cleaner console output and a summary message upon completion.

* `make clean`
  Safely removes all generated `.txt` files from the `output/` directory, maintaining the `.gitkeep` file to preserve the directory structure in version control.

* `make help`
  Prints an inline reference menu of all available Makefile targets.