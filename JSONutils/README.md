# Collection of helpful scripts for working with GuideLLM JSON Reports  

print_json_metrics.py  
* Requires two args: 'GuideLLM benchmarks.json file' and 'search string'
* USAGE: $ python print_json_metrics.py benchmarks.json p90 > P90.txt
* * Creates text file containing matches for string 'P90'  
  * CONTENTS looks like  
  * MATCH FOUND:  
  Path:  benchmarks[0] -> metrics -> text -> characters -> total_per_second -> total -> percentiles -> p90  
  Value: 875.1434983871435  

plot_json_metrics.py  
* Requires two args: 'GuideLLM benchmarks.json file' and 'TIMESTAMP string' and 'Metric string'  
* USAGE: $python plot_json_metrics.py PI34_RESULTS_onerun_8_1_4_20260221_160408/run_1_rate_1/benchmarks.json benchmarks[0].end_time benchmarks[0].duration  
laptop$ display benchmarks\[0\]_duration_plot.png  
* * Creates PNG file with plot/graph of metrics named on cmdline  
