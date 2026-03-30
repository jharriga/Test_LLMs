Scripts useful in isolating GuideLLM timing comparisons when executing  
benchmarks using a variety of concurrency rates.  
Capturing results (GuideLLMM Reports and console msgs) and post-processing timings.  
*NOTE:* Requires a running inference server is available at http://localhost:8000 

# Sample Usage  
Run Script & Post-Process Results  
```bash
sut# ./check_pauses.sh RATES1_8
Testing sequence complete. RESULTS in: RESULTS_RATES1_8_<$TIMESTAMP>

sut# ./summarize_results.sh ./RESULTS_RATES1_8_<$TIMESTAMP>
------------------------------------------------  
Processing directory:   ../../GuideLLM_Results/RESULTS_RATES_1_8_<$TIMESTAMP>/run_1_rate_1  
Created pretty-print file:   ../../GuideLLM_Results/RESULTS_RATES_1_8_<$TIMESTAMP>/run_1_rate_1/benchmarks_PP_PP.json  
Searching for 'duration' in   ../../GuideLLM_Results/RESULTS_RATES_1_8_<$TIMESTAMP>/run_1_rate_1/benchmarks_PP_PP.json:  
      "duration": 244.47095155715942,  
Runtime information:  
/bin/time RUNTIME in seconds= 249970 ms for CMDSTR to complete  

<SNIP>
```

