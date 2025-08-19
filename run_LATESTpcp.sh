#!/bin/bash
# Script which executes vLLM and llama.cpp Inference Engines
# Uses workload https://github.com/robert-mcdermott/openai-llm-benchmark.git
# which is executed within a python 'uv' environment
# To be used in comparison of vLLM and llama.cpp Inference Engines
#------------------------------------------------------------------------
# GLOBAL vars
# Initialize vars used in 'startIE' and 'runBmark' functions
testIE_arr=("vllm-gpu" "vllm-cpu-env" "llama.cpp-CPU")
testURL_arr=("http://localhost:8000" \
             "http://localhost:8000" \
             "http://localhost:8080")
testMODELS_arr=("SmolLM2-135M-Instruct" \
                "SmolLM2-360M-Instruct" \
                "SmolLM2-1.7B-Instruct")
testPROMPT="What is the capital of Washington state in the USA?  /no_think"
RESULTS_path="$PWD/Results/Started_$(date +"%b%d-%Y-%H%M%S")"

BMARKrepo_arr=("https://github.com/robert-mcdermott/openai-llm-benchmark" \
    "https://github.com/vllm-project/guidellm")

#------------------------------------------------------------------------
# BEGIN: PCPrecord related 
# Bring in FUNCTIONS and GLOBALS, inc $FIFO
source /home/jharriga/PCPrecord_systemd/Clients/client.inc
pmlog_cfg="$PWD/llm.cfg"
archive_dir="${RESULTS_path}/archive_${the_IE}_${the_model}"

PCPrecord_verify() {
  # Check that PCPrecord.SVC is running
  systemctl is-active --quiet PCPrecord.service
  fail_exit "PCPrecord.service not running"
}

# END: PCPrecord related
#------------------------------------------------------------------------
# FUNCTIONS
error_handler() {
  local the_msg="$1"

  echo "ERROR Exiting: ${the_msg}"
  # Additional error handling logic can be added here

  exit 30            # pick a number for universal exit code
}

verifyIE() {
# Wait for Inference Engine to initialize. Verify by listing available Models
  local the_IE="$1"
  local the_model_url="$2"
  local wait_sec=600                # BIG for TIMEOUT cmd
  local curl_sec=5                  # retry interval for 'curl'
  # Poke at IE for list of Models and record time til response
  preaction=$(mark_ms)
  timeout "$wait_sec" bash -c \
    "until curl -s --max-time "$curl_sec" \
      "${the_model_url}">/dev/null; do sleep 1; done"
  # Trap timeout condition
  if [ $? -eq 124 ]; then
    stopIE "${the_IE}"           # be thorough
    error_handler "verifyIE timed-out starting ${the_IE}. Waited $wait_sec sec"
  fi
  # Measure and report time interval for curl response
  postaction=$(mark_ms)
  interval=$(( 10*(postaction - preaction) ))
  echo "STARTup= $interval ms for ${the_IE} at ${the_model_url}"
  echo "Succesfully verified ${the_IE}"
}

runBmark() {
# Add "the_Bmark" and "the_BmarkCMD" to enable other Benchmarks to be run
#############
  # Execute the Benchmark/Workload
  local the_IE="$1"
  local the_url="$2"
  local the_model="$3"
  local the_prompt="$4"
  local model_url="${the_url}/v1/models"    # used to verify startup
  # Create LOGFILE w/results
  local BMARK_log="${RESULTS_path}/${the_IE}_${the_model}.BMARKlog"
  # Vars used to start PMLOGGER
  local PCP_dir="${RESULTS_path}/PCParchive_${the_IE}_${the_model}"
  local TEST_name="${the_IE}_${the_model}"
  local PMLOG_cfg="$PWD/pcp_llm.cfg"
  
  # Check that PCPrecord.SVC is running
  PCPrecord_verify

  cd openai-llm-benchmark
  if [ "$?" != "0" ]; then
    error_handler "Unable to find Bmark directory"
  fi
  # Verify the_IE is actually running
  verifyIE "${the_IE}" "${model_url}"
  # Start PMLOGGER
  PCParchive_start "${PCP_dir} ${TEST_name} $PMLOG_cfg"
  sleep 10         # add delay

  echo "Run starting..."
  uv sync > /dev/null 2>&1                # Silence
  # OPTIONAL add '--quiet' to silence the progress-bar
  uv run openai-llm-benchmark.py \
      --base-url "${the_url}" \
      --model "/model/${the_model}" --requests 1000 \
      --concurrency 1 --max-tokens 100 \
      --prompt "${the_prompt}" | tee "${BMARK_log}"
# check return code
  if [ "$?" != "0" ]; then
    cd ..
    error_handler "Unable to start the Workload. Exit status: $?"
  fi
  echo "Run complete - RESULTS file: ${BMARK_log}"
  sleep 10         # add delay
  # Stop PMLOGGER
  PCParchive_end
  # Notify user of PCP-Archive location
  echo "PCP Archive directory: ${PCP_dir}" 
##  ls -l "${PCP_dir}"            # DEBUG
##  error_handler "DEBUG - early exit"
  cd ..
}

startIE() {
  # Start Inference Engine in the background
  local the_IE="$1"
  local the_url="$2"
  local the_model="$3"
  local model_url="${the_url}/v1/models"    # used to verify startup
  # Create a timestamped LOGFILE and execute as Background process
  local IE_log="${RESULTS_path}/${the_IE}_${the_model}.IElog"

  # Add LOGGING to the 'podman run' cmdlines
  echo "Attempting to Start: ${the_IE}. Possible long delay..."
  if [[ $the_IE == "vllm-cpu-env" ]]; then
    podman run --name "${the_IE}" -d --rm --privileged=true \
      --shm-size=4g -p 8000:8000 \
      -e VLLM_CPU_KVCACHE_SPACE=40 \
      -e VLLM_CPU_OMP_THREADS_BIND=1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,33,35,37,39,41,43,45,47,49,51,53,55,57,59,61,63,65,67,69,71,73,75,77,79,81,83,85,87,89,91,93,95,97,99,101,103,105,107,109,111 \
      -v $PWD/Models:/model \
      "${the_IE}" --model "/model/${the_model}" --block-size 16
  elif [[ $the_IE == "vllm-gpu" ]]; then
    podman run --name "${the_IE}" -d --rm --privileged=true \
      --security-opt=label=disable --device=nvidia.com/gpu=all \
      -p 8000:8000 --ipc=host \
      -v $PWD/Models:/model \
      "${the_IE}" --model "/model/${the_model}"
  elif [[ $the_IE == "llama.cpp-CPU" ]]; then
    cd llama.cpp
    # Look into use of '--metrics'. Capture with PCP OpenMetrics
    ./build/bin/llama-server --metrics -m "../Models/${the_model}.gguf" \
      --log-file "${IE_log}" >/dev/null 2>&1 &
    cd ..
  else
    error_handler "Unrecognized IE ${the_IE}. ABORTING Test"
  fi
  # check return code
  if [ "$?" != "0" ]; then
    error_handler "Unable to start ${the_IE}. Exit status: $?"
  fi
  
# Wait for Inference Engine to initialize. Verify by listing available Models
  verifyIE "${the_IE}" "${model_url}"
}

stopIE() {
  # Stop Inference Engine background process using PKILL or 'podman kill'
  local the_IE="$1"

  if [[ $the_IE == "llama.cpp-CPU" ]]; then
      the_IE="llama-server"         # match syntax w/startIE() cmdline
      pkill -f "${the_IE}" > /dev/null 2>&1
  else
      podman kill "${the_IE}" > /dev/null 2>&1
  fi
  # check KILL return code
  if [ "$?" != "0" ]; then
    error_handler "Unable to kill ${the_IE}"
  fi
  echo "Successfully Killed ${the_IE}"
  sleep 10              # DEBUG - find a better way to confirm
}
# END FUNCTIONS

#------------------------------------------------------------------------
# MAIN

# Install necessary Tools
curl -LsSf https://astral.sh/uv/install.sh | sh>/dev/null
# check KILL return code
if [ "$?" != "0" ]; then
    error_handler "Unable to install UV. Exit status: $?"
fi

echo; echo "Clone the BENCHMARK Inference Engine repos"
for BMARK_repo in "${BMARKrepo_arr[@]}"; do
    BMARK_name="$(basename "$BMARK_repo")"
    BMARK_path="$PWD/$BMARK_name"
    if [ ! -d "$BMARK_path" ]; then
       echo "Cloning $BMARK_repo"
       git clone "${BMARK_repo}">/dev/null
       error_handler "Unable to git clone ${BMARK_repo}. Exit status: $?"
    fi
done
echo "Done cloning the BENCHMARK Inference Engine repos"

# Determine which vLLM podman images are available (locally)
#podman images

# Create RESULTS dir - timestamped
mkdir -p "${RESULTS_path}"
if [ "$?" != "0" ]; then
    error_handler "Unable to create Results directory"
fi

# Now get to work with TEST Loop
url_index=0                         # used to pickup correct IE url
for ie in "${testIE_arr[@]}"; do
    url="${testURL_arr[url_index]}"     # get proper URL for this IE
    echo; echo "Entering main TEST Loop with $ie and $url"
    for model in "${testMODELS_arr[@]}"; do
        echo; echo "> Entering inner TEST Loop with $ie & $model"
        startIE "${ie}" "${url}" "${model}"          # Start the Inference Engine
        runBmark "${ie}" "${url}" "${model}" "${testPROMPT}"  # Run the Benchmark
        stopIE "${ie}"                               # Stop the Inference Engine
        echo "> Completed inner TEST Loop with $ie & $model"
    done                  # Inner FOR Loop
    echo "Completed main TEST Loop with $ie & $url"
    ((url_index+=1))      # increment to pickup (next) correct IE url
done                      # Outer FOR Loop

echo "Done with testing"
