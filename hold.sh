
#!/bin/bash
# Script which executes vLLM and llama.cpp Inference Engines
# Uses workload https://github.com/robert-mcdermott/openai-llm-benchmark.git
# which is executed within a python 'uv' environment
# To be used in comparison of vLLM and llama.cpp Inference Engines

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
  # Is two minutes ENOUGH?
  timeout 120 bash -c \
    "until curl -s "${the_model_url}">/dev/null; do sleep 1; done"
  # Trap timeout condition
  if [ $? -eq 124 ]; then
    stopIE "${the_IE}"           # be thorough
    error_handler "verifyIE timed-out starting ${the_IE}"
  fi
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
  model_url="${the_url}/v1/models"    # used to verify startup
  # Create a timestamped LOGFILE
  BMARK_log="${the_IE}_${the_model}_$(date +"%b%d-%Y-%H%M%S").BMARKlog 2>&1"
  cd openai-llm-benchmark
  error_handler "Unable to find Bmark directory"
  # Verify the_IE is actually running
  verifyIE "${the_IE}" "${model_url}"
##  uv sync
##  uv run openai-llm-benchmark.py \
##      --base-url "${the_url}" \
##      --model "${the_model}" --requests 1000 \
##      --concurrency 1 --max-tokens 100 \
##      --prompt "${the_prompt}" --output-file "${BMARK_log}"
#### check return code
##  if [ "$?" != "0" ]; then
##    cd ..
##    error_handler "Unable to start the Workload. Exit status: $?"
##  fi
  cd ..
}

startIE() {
  # Start Inference Engine in the background
  local the_IE="$1"
  local the_url="$2"
  local the_model="$3"
  model_url="${the_url}/v1/models"    # used to verify startup
  # Create a timestamped LOGFILE and execute as Background process
  IE_log="${the_IE}_${the_model}_$(date +"%b%d-%Y-%H%M%S").IElog"
  
 echo "Attempting to Start: ${the_IE}. Expect long delay..."
  if [[ $the_IE == "vllm-cpu-env" ]]; then
    podman run --name "${the_IE}" -d --rm --privileged=true \
      --shm-size=4g -p 8000:8000 \
      -e VLLM_CPU_KVCACHE_SPACE=40 \
      -e VLLM_CPU_OMP_THREADS_BIND=0-5 \
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
    ./build/bin/llama-server -m "../Models/${the_model}" --log-file "${IE_log}"
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
      pkill -f "${the_IE}"
  else
      podman kill "${the_IE}"
  fi
  # check KILL return code
  if [ "$?" != "0" ]; then
    error_handler "Unable to kill ${the_IE}. Exit status: $?"
  fi
  echo "Succesfully Killed ${the_IE}"
}
# END FUNCTIONS

#------------------------------------------------------------------------
# MAIN
BMARKrepo_arr=("https://github.com/robert-mcdermott/openai-llm-benchmark" \
    "https://github.com/vllm-project/guidellm")

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

# Initialize vars used in 'startIE' and 'runBmark' functions
testIE_arr=("vllm-gpu" "vllm-cpu-env" "llama.cpp-CPU")
testURL_arr=("http://localhost:8000" \
             "http://localhost:8000" \
             "http://localhost:8080")
testMODELS_arr=("SmolLM2-135M-Instruct" \
                "SmolLM2-360M-Instruct" \
                "SmolLM2-1.7B-Instruct")
testPROMPT="What is the capital of Washington state in the USA?  /no_think"

# Now get to work with TEST Loop
url_index=0                         # used to pickup correct IE url
for ie in "${testIE_arr[@]}"; do
    url="${testURL_arr[url_index]}"     # get proper URL for this IE
    echo "Entering main TEST Loop with $ie and $url"
    for model in "${testMODELS_arr[@]}"; do
        echo "Entering inner TEST Loop with $ie & $model"
        startIE "${ie}" "${url}" "${model}"          # Start the Inference Engine
        runBmark "{$ie}" "${url}" "${model}" "${testPROMPT}"  # Run the Benchmark
        stopIE "${ie}"                                # Stop the Inference Engine
    done                  # Inner FOR Loop
    ((url_index+=1))      # increment to pickup (next) correct IE url
done                      # Outer FOR Loop

echo "Done with testing"

