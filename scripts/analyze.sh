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

# $# is the number of arguments passed to the script. Loop while there are arguments left.
while [ $# -gt 0 ]; do
    case $1 in
        # 'shift 2' discards the first two arguments
        # so the next iteration processes the remaining arguments.
        --format) FORMAT="$2"; shift 2 ;;
        --output) OUTPUT_FILE="$2"; shift 2 ;;
        # 'shift 1' because --verbose is a flag and doesn't take a value.
        --verbose) VERBOSE=1; shift 1 ;;
        --help) print_help ;;
        *)
            # If the argument doesn't match a flag, assume it's the log file path.
            if [[ -z "$LOG_FILE" ]]; then
                LOG_FILE="$1"
                shift 1
            else
                echo "Error: Unkown argument $1" 
                exit 1
            fi ;;
    esac
done

# -z checks if the string is empty
if [ -z "$LOG_FILE" ]; then
    echo "Error: Log file path is required."
    print_help
fi

# ! -f checks if the file does NOT exist
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: File '$LOG_FILE' does not exist."
    exit 1
fi

# Verbose output for initialization
if [ $VERBOSE -eq 1 ]; then
    echo "[VERBOSE] Log file validated: $LOG_FILE" 
    echo "[VERBOSE] Output format selected: $FORMAT" 
    echo "[VERBOSE] Target output path: $OUTPUT_FILE" 
fi

generate_summary() {
    local log="$1"

    # Verbose output before parsing
    if [ $VERBOSE -eq 1 ]; then echo "[VERBOSE] Extracting total, passed, failed, and skipped test counts..."; fi

    # grep options: -i (case-insensitive), -c (count matching lines).
    # '|| true' is CRITICAL here: Because 'set -e' is active, if grep finds 0 matches, 
    # it returns a non-zero exit code which would normally kill the whole script. '|| true' prevents this.
    local total_tests=$(grep -ic "TEST START" "$log" || true)
    local passed=$(grep -ic "TEST PASS" "$log" || true)
    local failed=$(grep -ic "TEST FAIL" "$log" || true)
    local skipped=$(grep -ic "TEST SKIP" "$log" || true)

    # Verbose output before math
    if [ $VERBOSE -eq 1 ]; then echo "[VERBOSE] Calculating pass/fail percentages..."; fi

        # awk -v passes shell variables into awk variables.
        # This calculates percentages safely, avoiding a divide-by-zero error if total_tests (t) is 0.
        local pass_rate=$(awk -v p="$passed" -v t="$total_tests" 'BEGIN { if (t>0) printf "%4.1f", (p/t)*100; else printf "%4.1f", 0 }')
        local fail_rate=$(awk -v f="$failed" -v t="$total_tests" 'BEGIN { if (t>0) printf "%4.1f", (f/t)*100; else printf "%4.1f", 0 }')
        local skip_rate=$(awk -v s="$skipped" -v t="$total_tests" 'BEGIN { if (t>0) printf "%4.1f", (s/t)*100; else printf "%4.1f", 0 }')

    # Verbose output before extracting test names
    if [ $VERBOSE -eq 1 ]; then echo "[VERBOSE] Fetching list of failed test names..."; fi

    # Extracts the 5th word/column from lines containing "TEST FAIL"
    local fail_list=$(grep -i "TEST FAIL" "$log" | awk '{print $5}' || true)

    # Verbose output before timing analysis
    if [ $VERBOSE -eq 1 ]; then echo "[VERBOSE] Parsing execution timing statistics..."; fi

    local timing_stats
    timing_stats=$(grep -E "TEST (PASS|FAIL)" "$log" | awk '{
        # $NF represents the last field/column of the current line
        time_str = $NF
        
        # gsub is a global substitution. This removes literal "(", ")", and "s" characters from the string.
        # Example: "(1.23s)" becomes "1.23"
        gsub(/[\(s\)]/, "", time_str)
        
        # Adding 0 forces awk to typecast the string variable 'time_str' into a numeric variable.
        time_val = time_str + 0 
        
        sum += time_val
        # NR is the current Record/Row Number.
        # $(NF-1) captures the second-to-last field (usually the test name).
        if (NR == 1 || time_val < min) { min = time_val; min_test = $(NF-1) }
        if (NR == 1 || time_val > max) { max = time_val; max_test = $(NF-1) }
    } END {
        if (NR > 0) {
            printf "Min time:  %.2fs (%s)\n", min, min_test
            printf "Max time:  %.2fs (%s)\n", max, max_test
            printf "Avg time:  %.2fs\n", sum/NR
        }
    }' || true)

    # Verbose output before generating file
    if [ $VERBOSE -eq 1 ]; then echo "[VERBOSE] Generating final $FORMAT report..."; fi

    # Wrap the output block in an if/else to support CSV format
    if [ "$FORMAT" == "csv" ]; then
        {
            local verdict="PASS"
            if [ $failed -gt 0 ]; then verdict="FAIL"; fi
            
            # Print CSV Headers
            echo "LogFile,AnalysisDate,TotalTests,Passed,Failed,Skipped,PassRate,Verdict"
            # Print CSV Values
            echo "$log,$(date +'%Y-%m-%d %H:%M:%S'),$total_tests,$passed,$failed,$skipped,${pass_rate}%,$verdict"
        } > "$OUTPUT_FILE"
    else
        # Curly braces { } group all the echo/printf commands so their combined output 
        # can be redirected into "$OUTPUT_FILE" all at once at the bottom.
        {
            echo " "
            echo "=== RISC-V Simulation Log Analysis ==="
            echo "Log file: $log"
            echo "Analysis date: $(date +'%Y-%m-%d %H:%M:%S')"
            echo ""
           
            echo "--- Results Summary ---"
            echo "Total tests: $total_tests"
            
        printf "Passed:      %2d (%s%%)\n" "$passed" "$pass_rate"
            printf "Failed:      %2d (%s%%)\n" "$failed" "$fail_rate"
            printf "Skipped:     %2d (%s%%)\n" "$skipped" "$skip_rate"
            
            if [ $failed -gt 0 ]; then
                echo ""
                echo "--- Failed Tests ---"
                local counter=1
                # Piping a multi-line string into a while loop reads it line-by-line
                echo "$fail_list" | while read -r test_name; do
                    echo "  $counter. $test_name"
                    ((counter++))
                done
            fi
            
            echo ""
            echo "--- Timing Statistics ---"
            echo "$timing_stats"
            
            echo ""
            if [ $failed -gt 0 ]; then
                echo "--- Verdict: FAIL ---"
                echo "Exit code: 1"
            else
                echo "--- Verdict: PASS ---"
                echo "Exit code: 0"
            fi
        } > "$OUTPUT_FILE"
    fi

    # The function returns the raw number of failed tests as its exit status
    return $failed
}

generate_summary "$LOG_FILE"
# $? captures the exit status of the very last command executed (which is the return value of generate_summary)
FAIL_COUNT=$?

# Final verbose exit message
if [ $VERBOSE -eq 1 ]; then echo "[VERBOSE] Analysis complete. Exiting with code: $(if [[ $FAIL_COUNT -gt 0 ]]; then echo 1; else echo 0; fi)"; fi

if [ $FAIL_COUNT -gt 0 ]; then
    exit 1
else
    exit 0
fi