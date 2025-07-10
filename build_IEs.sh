#!/bin/bash
# Script which clones vLLM and llama.cpp repos and then builds them
# To be used in comparison of vLLM and llama.cpp Inference Engines

IErepo_arr=("https://github.com/ggml-org/llama.cpp"
    "https://github.com/vllm-project/vllm")

# Install necessary Tools
# llama.cpp requires python and cmake
# vLLM requires podman for build & run
dnf install -y podman python3 cmake curl libcurl-devel

echo "Clone the Inference Engine repos"
for IE_repo in "${IErepo_arr[@]}"; do
    IE_name="$(basename "$IE_repo")"
    IE_path="$PWD/$IE_name"
    if [ ! -d "$IE_path" ]; then
       echo "Cloning $IE_repo"
       git clone "${IE_repo}"
    fi
done
echo "Done cloning the Inference Engine repos"

echo "Build vLLM using 'podman build'"
podman build -f vllm/docker/Dockerfile.cpu \
  --build-arg VLLM_CPU_DISABLE_AVX512="false" \
  --tag vllm-cpu-env --target vllm-openai .

echo "Build llama.cpp using 'cmake'"
cd llama.cpp
cmake -B build
cmake --build build --config Release -j $(nproc)


