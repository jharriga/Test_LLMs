#!/bin/bash
# Script which downloads Models to be used in comparison of
# vLLM and llama.cpp 

model_arr=("https://huggingface.co/HuggingFaceTB/SmolLM2-135M-Instruct"
    "https://huggingface.co/HuggingFaceTB/SmolLM2-360M-Instruct"
    "https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B-Instruct")

if [ ! -d "./Models" ]; then
    echo "mkdir Models"         # DEBUG
    mkdir Models
fi
cd Models

dnf install git-lfs
git lfs install

echo "Start cloning the Model repos"
for model_repo in "${model_arr[@]}"; do
    model_name="$(basename "$model_repo")"
    model_path="$PWD/$model_name"
    if [ ! -d "$model_path" ]; then
       echo "Cloning $model_repo"
       git clone "${model_repo}"
    fi
done
echo "Done cloning the Model repos"
