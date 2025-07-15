# Test_vLLM_llama.cpp
Scripts which automate the testing comparison of two Inference Engines vLLM and llama.cpp  
Execute the scripts in this order: 
```
sut# git clone <repo>
sut# cd Test_vLLM_llama.cpp    
sut# get_models.sh  <-- Edit 'models_arr' for your model repos  
sut# convert2gguf.sh    
sut# build_IEs.sh  
sut# run_tests.sh  
```
