#!/bin/bash
# Script which converts pre-existing Hugging-Face Models to GGUF
# for use with llama.cpp

# Look for pre-existing Models
if [ ! -d "./Models" ]; then
    echo "Models not found. Run 'getModels.sh first' "
    exit
fi

# Clone the repo which provides the conversion tool
clone_repo="https://github.com/ggml-org/llama.cpp"
clone_dir="$(basename "$clone_repo")"
if [ ! -d "$clone_dir" ]; then
    echo "Cloning repo ${clone_repo}"
    git clone https://github.com/ggml-org/llama.cpp
fi

# Start a python venv as execution environment
python -m venv ~/llama-cpp-venv
source ~/llama-cpp-venv/bin/activate
# Execute within venv
python -m pip install --upgrade pip wheel setuptools
python -m pip install --upgrade -r llama.cpp/requirements/requirements-convert_hf_to_gguf.txt

# For each available Model, perform the conversion
echo "Start converting the Models"
for model_dir in ./Models/*; do
##    echo "${model_dir}"           # DEBUG
    if [ -d "${model_dir}" ]; then
        model_name="$(basename "${model_dir}")"
        gguf_name="Models/${model_name}.gguf"
##    model_path="$PWD/$model_name"
       echo "Converting ${model_name} to ${gguf_name}"
       python llama.cpp/convert_hf_to_gguf.py "${model_dir}" \
         --outfile "${gguf_name}"
    fi
done

# Exit the venv
deactivate
echo "Done converting the Models. 'ls -l ./Models' "
ls -l ./Models

# END
