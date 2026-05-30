SCRIPT := scripts/analyze.sh
TEST_DIR := test_data
OUT_DIR := output

# $(wildcard ...) evaluates to a list of all matching files
LOGS := $(wildcard $(TEST_DIR)/*.log)
# Dynamically generate the expected output filenames
REPORTS := $(LOGS:$(TEST_DIR)/%.log=$(OUT_DIR)/%.report.txt)

# .PHONY prevents conflicts and guarantees the commands will run even if a file named "clean" or "test" exists.
.PHONY: all test report clean help setup


all: $(REPORTS)

# Pattern rule: Tells Make how to build ANY .report.txt file from its matching .log file
$(OUT_DIR)/%.report.txt: $(TEST_DIR)/%.log
    # Automatic variables:
    # $< represents the first prerequisite (the .log file)
    # $@ represents the target (the .report.txt file)
	@echo "Analyzing $< -> $@"
    # The '|| echo ...' catches a non-zero exit code from analyze.sh.
    # Without this, Make would immediately abort the entire run on the first failure.
	@./$(SCRIPT) $< --output $@ || echo "  -> Note: Script exited with 1 (Failures detected in $<)"

test:
	@echo "=== Running Output Tests ==="
    
	@for log in $(LOGS); do \
        echo "Testing $$log..."; \
        ./$(SCRIPT) $$log; \
        echo "---------------------------"; \
    done

report: all
	@echo "Summary reports successfully generated in $(OUT_DIR)/ directory."

clean:
	@echo "Cleaning output directory..."
	rm -f $(OUT_DIR)/*
    # .gitkeep ensures Git continues tracking the 'output' directory even when it's empty
	touch $(OUT_DIR)/.gitkeep

help:
	@echo "=== RISC-V Analyzer Makefile ==="
	@echo "Available targets:"
	@echo "  make setup  - Check system dependencies (bash, grep, awk)"
	@echo "  make test   - Run the analyzer on all log files and print to console"
	@echo "  make all    - Generate individual text reports for all log files"
	@echo "  make report - Alias for 'make all' with a summary message"
	@echo "  make clean  - Remove all generated files from the output directory"
	@echo "  make help   - Print this menu"

setup:
	@chmod +x scripts/setup_env.sh scripts/analyze.sh
	@./scripts/setup_env.sh