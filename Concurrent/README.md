Scripts which automate running GuideLLM concurrent test-runs, capturing  
results (GuideLLMM Reports and console msgs) and post-processing timings.  

# Sample Usage  
Run Script & Post-Process Results  
```bash
pi-34# ./concur_rates.sh RATES1_8
Testing sequence complete. RESULTS in: RESULTS_RATES1_8_20260220_134125

pi-34# ./concur_summarize.sh ./RESULTS_RATES1_8_20260220_134125
------------------------------------------------  
Processing directory:   ../../GuideLLM_Results/PI34_RESULTS_onerun_8_1_4_20260221_160408//run_1_rate_1  
Created pretty-print file:   ../../GuideLLM_Results/PI34_RESULTS_onerun_8_1_4_20260221_160408//run_1_rate_1/benchmarks_PP_PP.json  
Searching for 'duration' in   ../../GuideLLM_Results/PI34_RESULTS_onerun_8_1_4_20260221_160408//run_1_rate_1/benchmarks_PP_PP.json:  
      "duration": 244.47095155715942,  
Runtime information:  
RUNTIME= 249970 ms for CMDSTR to complete  

<SNIP>
```

