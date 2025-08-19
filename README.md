# Test_LLMs
Scripts which automate the testing comparison of two Inference Engines vLLM and llama.cpp  
Execute the scripts in this order: 
```
sut# git clone <repo>
sut# cd Test_vLLM_llama.cpp    
sut# get_models.sh  <-- Edit 'models_arr' for your model repos  
sut# convert2gguf.sh    
sut# build_IEs.sh  
sut# run_tests.sh | tee console.txt  
```
Results from 'run_tests.sh' can be found in timestamped dirs  
located within the ./Results dir  

# run_LATESTpcp.sh 
UNDER DEVELOPMENT  
A script which utilizes PCPrecord_systemd to create PCP-Archives during LLM test-runs  
Requires that jharriga/PCPrecord_systemd be installed and configured on the system  
pulls in 'PCPrecord_systemd/Clients/client.inc' bash functions  
