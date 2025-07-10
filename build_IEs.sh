#!/bin/bash
# Script which clones vLLM and llama.cpp repos and then builds them
# To be used in comparison of vLLM and llama.cpp Inference Engines

IErepo_arr=("https://github.com/ggml-org/llama.cpp"
    "https://github.com/vllm-project/vllm")

# Install necessary Tools
# llama.cpp requires python and cmake
# vLLM requires podman for build & run
dnf install -y podman python3 cmake curl libcurl-devel

echo; echo "Clone the Inference Engine repos"
for IE_repo in "${IErepo_arr[@]}"; do
    IE_name="$(basename "$IE_repo")"
    IE_path="$PWD/$IE_name"
    if [ ! -d "$IE_path" ]; then
       echo "Cloning $IE_repo"
       git clone "${IE_repo}"
    fi
done
echo "Done cloning the Inference Engine repos"

echo; echo "Build vLLM using 'podman build'"
# Determine CPU Arch to set Dockerfile
if [[ $(arch) == "aarch64" ]]; then
    echo "System is AArch64. Using docker/Dockerfile.arm"
    containerFile="docker/Dockerfile.arm"
    targetName="build"
elif [[ $(arch) == "x86_64" ]]; then
    echo "System is x86_64. Using docker/Dockerfile.cpu"  
    containerFile="docker/Dockerfile.cpu"
    targetName="vllm-openai"
else
    echo "Unrecognized system: not AArch64 or x86_64. ABORTING Build"
    exit
fi

cd vllm
podman build -f "${containerFile}" \
  --build-arg VLLM_CPU_DISABLE_AVX512="false" \
  --tag vllm-cpu-env --target "${targetName}" .
podman images

echo; echo "Build llama.cpp using 'cmake'"
cd ../llama.cpp
cmake -B build
cmake --build build --config Release -j $(nproc)


