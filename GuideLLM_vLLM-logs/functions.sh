#!/bin/bash
# Functions utilized by the GuideLLM_vLLM-logs scripting
#
########################## START FUNCTIONS
mark_ms() {
    read up rest </proc/uptime; marker="${up%.*}${up#*.}"
    echo "$marker"                 # return value
}

error_handler() {
  local the_msg="$1"

  echo "ERROR Exiting: ${the_msg}"
  # Additional error handling logic can be added here

  exit 30            # pick a number for universal exit code
}

verifyIE() {
## Need to extend verifyIE() to probe if PID died early
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
  echo
  echo "Successfully Killed ${the_IE}"
  sleep 10              # DEBUG - find a better way to confirm
}
########################## END FUNCTIONS
