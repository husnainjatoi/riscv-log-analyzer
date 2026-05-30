SCRIPT := scripts/analyze.sh
TEST_DIR := test_data
OUT_DIR := output

LOGS := $(wildcard $(TEST_DIR)/*.log)
# Dynamically generate the expected output filenames
REPORTS := $(LOGS:$(TEST_DIR)/%.log=$(OUT_DIR)/%.report.txt)

.PHONY: all test report clean help setup


all: $(REPORTS)

$(OUT_DIR)/%.report.txt: $(TEST_DIR)/%.log
	@echo "Analyzing $< -> $@"
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
