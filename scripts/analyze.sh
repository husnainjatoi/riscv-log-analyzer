#!/bin/bash

set -euo pipefail

FORMAT="text"
OUTPUT_FILE="/dev/stdout"
VERBOSE=0
LOG_FILE=""

print_help() {
	echo "Usage: $0 <path_to_log> [options]"
	echo "Options:"
	echo " --format [text/csv]    Output format (default:text)"
	echo "  --output <path>       Output file path (default: stdout)"
       	echo "  --verbose             Enable verbose output"
       	echo "  --help                Show this help message"
	exit 0
}

while [[ $# -gt 0 ]]; do
	case $1 in
		--format) FORMAT="$2"; shift 2 ;;
		--output) OUTPUT_FILE="$2"; shift 2 ;;
		--verbose) VERBOSE=1; shift 1 ;;
		--help) print_help ;;
		*)
			if [[ -z "$LOG_FILE" ]]; then
				LOG_FILE="$1"
				shift 1
			else
				echo "Error: Unkown argument $1" 
				exit 1
			fi ;;
	esac
done

if [[ -z "$LOG_FILE" ]]; then
	echo "Error: Log file path is required."
	print_help
fi

if [[ ! -f "$LOG_FILE" ]]; then
	echo "Error: File '$LOG_FILE' does not exist."
	exit 1
fi


generate_summary() {
	local log="$1"

	local total_tests=$(grep -ic "TEST START" "$log" || true)
	local passed=$(grep -ic "TEST PASS" "$log" || true)
	local failed=$(grep -ic "TEST FAIL" "$log" || true)
	local skipped=$(grep -ic "TEST SKIP" "$log" || true)

	local pass_rate=$(awk -v p="$passed" -v t="$total_tests" 'BEGIN { if (t>0) printf "%.1f", (p/t)*100; else print 0 }')
        local fail_rate=$(awk -v f="$failed" -v t="$total_tests" 'BEGIN { if (t>0) printf "%.1f", (f/t)*100; else print 0 }')
        local skip_rate=$(awk -v s="$skipped" -v t="$total_tests" 'BEGIN { if (t>0) printf "%.1f", (s/t)*100; else print 0 }')

	local fail_list=$(grep -ic "TEST FAIL" "$log" | awk '{print $3} || true)
}
