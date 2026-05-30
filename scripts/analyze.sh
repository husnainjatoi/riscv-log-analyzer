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
