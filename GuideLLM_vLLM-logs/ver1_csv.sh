#!/bin/bash
# Script which conducts testrun of GuideLLM workload against vllm server
# Creates these (results) files in a timestamped DIR ($results_dir)
#   - vllm_log.log
#   - loggers_log.log
#   - vllm_metrics.log
#   - benchmarks.json (.csv, .html)
#########################################
rate_type="throughput"      # GuideLLM param
max_seconds="120"           # GuideLLM param

##timestamp="$(date -d "today" +"%Y%m%d%H%M")"
timestamp="$(date --utc +"%FT%TZ")"
results_dir="$PWD/${rate_type}_${timestamp}" 
mkdir -p "$results_dir"
echo "Created RESULTS dir $results_dir"

# Results Files
vllm_log="$results_dir/vllm_log.log"
loggers_log="$results_dir/loggers_log.log"
vllm_metrics="$results_dir/vllm_metrics.log"

# vllm endpoint vars: key metrics, delay and tmp file
metrics_array=("vllm:time_per_output_token_seconds_count" \
    "vllm:time_to_first_token_seconds_count" \
    "vllm:inter_token_latency_seconds_count" \
    "vllm:e2e_request_latency_seconds_count" \
    "vllm:kv_cache_usage_perc")
delay_vllm_info="10s"       # Aligns with vllm INFO records
payload="/tmp/payload"

########################## END FUNCTIONS

# Echo the test run conditions
the_IMAGE="public.ecr.aws/q9t5s3a7/vllm-cpu-release-repo:v0.10.2"
the_IE="vllm-cpu"
the_MODEL="/model/Llama-3.2-1B-Instruct"

echo "IE params: ${the_IMAGE} ${the_IE} ${the_MODEL}"
echo "GuideLLM params: rate-type: ${rate_type}  max-seconds: ${max_seconds}"
echo "IE Metric sampling rate: ${delay_vllm_info}"

# Start the vllm server and verify it started
podman run --name $the_IE --rm -d --privileged=true --shm-size=4g -p 8000:8000 -e VLLM_CPU_KVCACHE_SPACE=40 -v $PWD/Models:/model public.ecr.aws/q9t5s3a7/vllm-cpu-release-repo:v0.10.2 --model "/model/Llama-3.2-1B-Instruct" --dtype=bfloat16

if [ $? -ne 0 ]; then
  error_handler "Podman run failed!"
fi

# Check that vllm server is ready
echo "Waiting for ${the_IE} to initialize..."
verifyIE $the_IE http://localhost:8000/v1/models
echo

# Start Guidellm Workload and record pid
guidellm benchmark --disable-progress --disable-console-outputs --target http://localhost:8000 --processor "$PWD/Models/Llama-3.2-1B-Instruct" --rate-type $rate_type --max-seconds $max_seconds --data "prompt_tokens=32,output_tokens=16" --output-dir $results_dir &
GUIDELLM_PID=$!
# Wait for guidellm to get running - brain-dead approach
sleep 5

# Create vllm_metrics file
rm -f $vllm_metrics
touch $vllm_metrics

# Write the header row
    header_str=""              # Reset to empty string
    printf -v header_str '%s' "TIMESTAMP,LOOP,"
    echo -n "${header_str}" >> $vllm_metrics
    header_str=""              # Reset to empty string
    printf -v header_str '%s,' "${metrics_array[@]}"
    echo "${header_str}" >> $vllm_metrics  

# Probe and record metrics from vllm endpoint every $delay_vllm_info
loopcntr=0
# Loop while the GUIDELLM Workload is running
while kill -0 "$GUIDELLM_PID" 2>/dev/null; do
   # Loop counter - increment and report
    ((loopcntr++))
    timestamp="$(date --utc +"%FT%TZ")"
    echo "$timestamp  Loop number: $loopcntr \
      Delay: $delay_vllm_info"           # DEBUG to the console
    echo -n "${timestamp},${loopcntr}," >> $vllm_metrics
   # Get the payload - only do CURL once
    rm -f $payload
    touch $payload
    curl http://0.0.0.0:8000/metrics>$payload 2>/dev/null
   # Search for metrics Loop and write in CSV format
    for this_metric in "${metrics_array[@]}"; do
        metric="^${this_metric}"       # add start of line
        grep -E "$metric" $payload | awk '{printf "%s,", $NF}' >> $vllm_metrics
    done
    echo >> $vllm_metrics    # insert newline
    sleep $delay_vllm_info   # pause to align with vllm INFO msgs
done

# Strip off EOL closing COMMA's  - THIS HAS STOPPED WORKING
sed -i -E 's/,[[:space:]]*$//' $vllm_metrics

####################
# SHUTDOWN Procedure
# Creates vllm_log
podman logs vllm-cpu > $vllm_log 2>&1

# Stop podman run vllm-cpu
##podman stop vllm-cpu 
stopIE $the_IE

# Extract loggers.py INFO records from vllm_log
grep "loggers.py:" $vllm_log | sed G > $loggers_log

rm -f $payload                   # Clean-up
echo "Wrote RESULTS to dir $results_dir"
# END
