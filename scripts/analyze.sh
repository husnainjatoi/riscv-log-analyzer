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

        local pass_rate=$(awk -v p="$passed" -v t="$total_tests" 'BEGIN { if (t>0) printf "%4.1f", (p/t)*100; else printf "%4.1f", 0 }')
        local fail_rate=$(awk -v f="$failed" -v t="$total_tests" 'BEGIN { if (t>0) printf "%4.1f", (f/t)*100; else printf "%4.1f", 0 }')
        local skip_rate=$(awk -v s="$skipped" -v t="$total_tests" 'BEGIN { if (t>0) printf "%4.1f", (s/t)*100; else printf "%4.1f", 0 }')

	local fail_list=$(grep -i "TEST FAIL" "$log" | awk '{print $5}' || true)

    local timing_stats
    timing_stats=$(grep -E "TEST (PASS|FAIL)" "$log" | awk '{
        time_str = $NF
        gsub(/[\(s\)]/, "", time_str)
        time_val = time_str + 0
        
        sum += time_val
        if (NR == 1 || time_val < min) { min = time_val; min_test = $(NF-1) }
        if (NR == 1 || time_val > max) { max = time_val; max_test = $(NF-1) }
    } END {
        if (NR > 0) {
            printf "Min time:  %.2fs (%s)\n", min, min_test
            printf "Max time:  %.2fs (%s)\n", max, max_test
            printf "Avg time:  %.2fs\n", sum/NR
        }
    }' || true)

    {
        echo "=== RISC-V Simulation Log Analysis ==="
        echo "Log file: $log"
        echo "Analysis date: $(date +'%Y-%m-%d %H:%M:%S')"
        echo ""
       
       	echo "--- Results Summary ---"
        echo "Total tests: $total_tests"
        
	printf "Passed:      %2d (%s%%)\n" "$passed" "$pass_rate"
        printf "Failed:      %2d (%s%%)\n" "$failed" "$fail_rate"
        printf "Skipped:     %2d (%s%%)\n" "$skipped" "$skip_rate"
        
        if [[ $failed -gt 0 ]]; then
            echo ""
            echo "--- Failed Tests ---"
            local counter=1
            echo "$fail_list" | while read -r test_name; do
                echo "  $counter. $test_name"
                ((counter++))
            done
        fi
        
        echo ""
        echo "--- Timing Statistics ---"
        echo "$timing_stats"
        
        echo ""
        if [[ $failed -gt 0 ]]; then
            echo "--- Verdict: FAIL ---"
            echo "Exit code: 1"
        else
            echo "--- Verdict: PASS ---"
            echo "Exit code: 0"
        fi
    } > "$OUTPUT_FILE"

    return $failed
}

generate_summary "$LOG_FILE"
FAIL_COUNT=$?

if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
