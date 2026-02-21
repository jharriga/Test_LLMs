#!/bin/bash

# Check if a directory path was provided
if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/main_directory"
    exit 1
fi

# Assign the input path to a variable
BASE_DIR="$1"

# Check if the provided path is actually a directory
if [ ! -d "$BASE_DIR" ]; then
    echo "Error: $BASE_DIR is not a directory."
    exit 1
fi

# Loop through each item in the base directory
for SUB_DIR in "$BASE_DIR"/*; do
    
    # Process only if it is a directory
    if [ -d "$SUB_DIR" ]; then
        echo "------------------------------------------------"
        echo "Processing directory: $SUB_DIR"

        # 1. Traverse into the directory (logic handled by path)
        # 2. Find the JSON file (assuming one JSON file per directory)
        ORIG_JSON=$(find "$SUB_DIR" -maxdepth 1 -name "*.json" | head -n 1)

        if [ -f "$ORIG_JSON" ]; then
            # Define the name for the new pretty-print file
            # This creates a file like "original_PP.json"
            PP_JSON="${ORIG_JSON%.json}_PP.json"

            # 3. Use jq to pretty-print the JSON
            jq '.' "$ORIG_JSON" > "$PP_JSON"
            echo "Created pretty-print file: $PP_JSON"

            # 4. Search the new file for "duration" and show 2 lines of context before
            echo "Searching for 'duration' in $PP_JSON:"
            grep -B 2 '"duration"' "$PP_JSON"
        else
            echo "No JSON file found in $SUB_DIR"
        fi

        # 5. Search console.log for the line starting with "RUNTIME"
        CONSOLE_LOG="$SUB_DIR/console.log"
        if [ -f "$CONSOLE_LOG" ]; then
            echo "Runtime information:"
            grep "^RUNTIME" "$CONSOLE_LOG"
        else
            echo "console.log not found in $SUB_DIR"
        fi
    fi
done

echo "------------------------------------------------"
echo "Processing complete."
