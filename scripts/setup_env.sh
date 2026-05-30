#!/bin/bash

# Enable bash "strict mode" for safer script execution
set -euo pipefail

echo "=== Checking Environment Dependencies ==="

TOOLS=("bash" "grep" "awk" "date")
MISSING_COUNT=0

# Iterate over all elements in the TOOLS array. 
# "${TOOLS[@]}" expands to each element as a separate word, safely handling spaces.
for tool in "${TOOLS[@]}"; do
    
    # 'command -v' to check if a command exists in the system's PATH.
    # '>/dev/null' redirects standard output to the void.
    if command -v "$tool" >/dev/null ; then
        echo "[OK] Found: $tool"
    else
        echo "[ERROR] Missing: $tool"
        
        ((MISSING_COUNT++))
    fi
done

echo "========================================="

if [ $MISSING_COUNT -gt 0 ]; then
    echo "Setup Failed: Please install the $MISSING_COUNT missing tool(s)."
    
    exit 1
else
    echo "Setup Complete: All dependencies are met."
    
    exit 0
fi