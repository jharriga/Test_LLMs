# Collection of helpful scripts for working with GuideLLM JSON Reports  

print_json_metrics.py  
* Requires two args: 'GuideLLM benchmarks.json file' and 'search string'
* USAGE: $ python print_json_metrics.py benchmarks.json p90 > P90.txt
* * Creates text file containing matches for string 'P90'  
  * CONTENTS looks like  
  * MATCH FOUND:  
  Path:  benchmarks[0] -> metrics -> text -> characters -> total_per_second -> total -> percentiles -> p90  
  Value: 875.1434983871435  


