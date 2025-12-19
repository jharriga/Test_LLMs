Scripts which conduct testruns of GuideLLM workload against vllm server  
Creates these (results) files in a timestamped DIR ($results_dir)  
- vllm_log.log  
- loggers_log.log  
- vllm_metrics.log  
- benchmarks.json (.csv, .html)  

Coordinate test-runs for vLLM and GuideLLM as the Workload  
They log runtime information from the vLLM Metrics endpoint (http://0.0.0.0:8000/metrics)  
and the vLLM console log messages. The logs are CSV formatted with timestamped records.  
In addition they also store GuideLLM 'benchmarks' results files.  
Per run logfiles and benchmarks results files are stored in a timestamped directory.  

# Configurable test-run components
./Models  directory containing previously downloaded models, typically from Hugging Face  
VAR "rate-type"   GuideLLM parameter (throughput, sweep, ...)  
VAR "max-seconds"   GuideLLM parameter

# Example Console Output
sut# ./ver1_csv.sh  
Created RESULTS dir /home/jharriga/GuideLLM-work/throughput_2025-12-19T14:27:44Z  
IE params: public.ecr.aws/q9t5s3a7/vllm-cpu-release-repo:v0.10.2 vllm-cpu /model/Llama-3.2-1B-Instruct  
GuideLLM params: rate-type: throughput  max-seconds: 120  
IE Metric sampling rate: 10s  
Waiting for vllm-cpu to initialize...  
STARTup= 78160 ms for vllm-cpu at http://localhost:8000/v1/models  
Succesfully verified vllm-cpu  

