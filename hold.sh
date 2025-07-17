
#!/bin/bash
# Script which executes vLLM and llama.cpp Inference Engines
# Uses workload https://github.com/robert-mcdermott/openai-llm-benchmark.git
# which is executed within a python 'uv' environment
# To be used in comparison of vLLM and llama.cpp Inference Engines

#------------------------------------------------------------------------
# FUNCTIONS
runBmark() {
  # Execute the Benchmark/Workload
  local the_url="$1"
  local the_model="$2"
  local the_prompt="$3"
  # Create a timestamped LOGFILE
  BMARK_log=" | tee ${the_IE}_${the_model}_$(date +"%b%d-%Y-%H%M%S").BMARKlog 2>&1"
  cd openai-llm-benchmark
  uv sync
  uv run openai-llm-benchmark.py \
      --base-url "${the_url}" \
      --model "${the_model}" --requests 1000 \
      --concurrency 1 --max-tokens 100 \
      --prompt "${the_prompt}" "${BMARK_log}"
  cd ..
}

startIE() {
  # Start Inference Engine in the background
  local the_IE="$1"
  local the_model="$2"
  local the_url="$3"
  model_url="${the_url}/v1/models"    # used to verify startup
  # Create a timestamped LOGFILE and execute as Background process
  IE_log=" > ${the_IE}_${the_model}_$(date +"%b%d-%Y-%H%M%S").IElog 2>&1 &"
  
  if [[ $the_IE == "vllm-cpu-env" ]]; then
    echo "Starting ${the_IE}"
    podman run --rm --privileged=true --shm-size=4g -p 8000:8000 \
      -e VLLM_CPU_KVCACHE_SPACE=40 \
      -e VLLM_CPU_OMP_THREADS_BIND=0-5 \
      -v $PWD/Models:/model \
      "${the_IE}" --model "${the_model}" \
      --block-size 16 "${IE_log}"
  elif [[ $the_IE == "vllm-gpu" ]]; then
    echo "Starting ${the_IE}"
    podman run --rm --security-opt=label=disable \
      --device=nvidia.com/gpu=all -p 8000:8000 --ipc=host \
      -v $PWD/Models:/model \
      "${the_IE}" --model "${the_model}" "${IE_log}"
  elif [[ $the_IE == "llama.cpp-CPU" ]]; then
    echo "Starting ${the_IE}"
    cd llama.cpp
    ./build/bin/llama-server -m "../Models/${the_model}" "${IE_log}"
    cd ..
  else
    echo "Unrecognized IE ${the_IE}. ABORTING Test"
    exit
  fi
# Wait for Inference Engine to initialize. Verify by listing Models
  timeout 10 bash -c \
    "until curl -s "${model_url}">/dev/null; do sleep 1; done"
  # Trap timeout condition
  if [ $? -eq 124 ]; then
    echo "Timed out waiting for ${the_IE} to Start"
    exit 30
  fi
}

stopIE() {
  # Stop Inference Engine background process using PGREP
  local the_IE="$1"

  if [[ $the_IE == "llama.cpp-CPU" ]]; then
      the_IE="llama-server"         # match syntax w/startIE() cmdline
  fi
  pkill -f "${the_IE}"
  if [ $? -eq 0 ]; then
      echo "Killed ${the_IE} - IE background process"
  else
      echo "Unable to PKILL ${the_IE}. Exit status: $?"
      exit 20
  fi
}
# END FUNCTIONS

#------------------------------------------------------------------------
# MAIN
BMARKrepo_arr=("https://github.com/robert-mcdermott/openai-llm-benchmark.git" \
    "https://github.com/vllm-project/guidellm")

# Install necessary Tools
curl -LsSf https://astral.sh/uv/install.sh | sh>/dev/null

echo; echo "Clone the BENCHMARK Inference Engine repos"
for BMARK_repo in "${BMARKrepo_arr[@]}"; do
    BMARK_name="$(basename "$BMARK_repo")"
    BMARK_path="$PWD/$BMARK_name"
    if [ ! -d "$BMARK_path" ]; then
       echo "Cloning $BMARK_repo"
       git clone "${BMARK_repo}">/dev/null
    fi
done
echo "Done cloning the BENCHMARK Inference Engine repos"

# Determine which vLLM podman images are available (locally)
#podman images

# Initialize vars used in 'startIE' and 'runBmark' functions
testIE_arr=("vllm-gpu" "vllm-cpu-env" "llama.cpp-CPU")
testURL_arr=("http://127.0.0.1:8000" \
             "http://127.0.0.1:8000" \
             "http://127.0.0.1:8080")
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
        startIE "${ie}" "${url}" "${model}"           # Start the Inference Engine
        runBmark "${url}" "${model}" "${testPROMPT}"  # Run the Benchmark
        stopIE "${ie}"                                  # Stop the Inference Engine
    done                  # Inner FOR Loop
    ((url_index+=1))      # increment to pickup (next) correct IE url
done                      # Outer FOR Loop

echo "Done with testing"

