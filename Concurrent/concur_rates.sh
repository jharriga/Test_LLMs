#!/bin/bash

########################## START FUNCTIONS
mark_ms() {
    read up rest </proc/uptime; marker="${up%.*}${up#*.}"
    echo "$marker"                 # return value
}
########################## END FUNCTIONS

# 1. Check if a test name was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <test_name>"
    exit 1
fi

TEST_NAME=$1
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_DIR="RESULTS_${TEST_NAME}_${TIMESTAMP}"

# 2. Define the rates as an array of strings
## SINGULAR Values
RATES=("1,1,1" "2,2,2" "8,8,8")         # singular_1_2_8
#RATES=("8,8,8" "1,1,1" "4,4,4")        # singular_8_1_4
#RATES=("8" "1" "4")                    # onerun_8_1_4
##  MULTI Values
#RATES=("12,4,8" "12,12,12" "8,4,12")
##RATES=("1,8")                  # DEBUG

# 3. Define the command to be executed
#CMDSTR="echo 'Processing rates: \$rate | Attempt: \$run'"

# 4. Create the RESULTS directory
mkdir -p "$RESULTS_DIR"
echo "Directory created: $RESULTS_DIR"

# 5. Outer for loop: Iterating through the array
for rate in "${RATES[@]}"; do
    
    # 6. Inner for loop: Iterating through run numbers
    for run in 1 2 3; do
        
        # Format filename (replacing commas with underscores)
        safe_rate=$(echo "$rate" | tr ',' '_')
##        LOG_FILE="${RESULTS_DIR}/run_${run}_rate_${safe_rate}.log"
        LOG_DIR="${RESULTS_DIR}/run_${run}_rate_${safe_rate}"
        mkdir -p "$LOG_DIR"
        echo "Directory created: $LOG_DIR"
        LOG_FILE="$LOG_DIR/console.log"
        CMDSTR="taskset -ac 128-138 guidellm benchmark --target http://localhost:8000 --processor $PWD/Models/Llama-3.2-1B-Instruct --data "prompt_tokens=256,output_tokens=128" --profile concurrent --max-requests 100 --rate=${rate} --output-dir ${LOG_DIR}"
        
        echo "--> Starting: Rate [$rate] Run [$run]" | tee "$LOG_FILE"
        echo "--> CMDSTR: [$CMDSTR]" | tee -a "$LOG_FILE"

        # 7. Execute the command and redirect stdout/stderr
	pre_cmd=$(mark_ms)
        eval "$CMDSTR" >> "$LOG_FILE" 2>&1
	# Measure and report time interval for curl response
        post_cmd=$(mark_ms)
        interval=$(( 10*(post_cmd - pre_cmd) ))
        echo "RUNTIME= $interval ms for CMDSTR to complete"| tee -a "$LOG_FILE"
        
    done
done

echo "---"
echo "Testing sequence complete. RESULTS in: $RESULTS_DIR"

