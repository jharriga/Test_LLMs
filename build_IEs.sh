#!/bin/bash
# Script which clones vLLM and llama.cpp repos and then builds them
# To be used in comparison of vLLM and llama.cpp Inference Engines

IErepo_arr=("https://github.com/ggml-org/llama.cpp"
    "https://github.com/vllm-project/vllm")

# Install necessary Tools
# llama.cpp requires python and cmake
# vLLM requires podman for build & run
dnf install -y podman python3 g++ cmake curl libcurl-devel

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

echo; echo "Build vLLM-CPU using 'podman build'"
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
# Build vllm-cpu-env image
podman build -f "${containerFile}" \
  --build-arg VLLM_CPU_DISABLE_AVX512="true" \
  --tag vllm-cpu-env --target "${targetName}" .

## OPTIONAL
##echo; echo "Build vLLM-GPU using 'podman build'"
# Build vllm-gpu image
# NOTE: this requires ALOT of disk space in '/var/lib' & TMPDIR.
#    May need to reassign TMPDIR location: "export TMPDIR=/home/tmpdir"
#    AND /var/lib/containers: "ln -s /home/containers/ /var/lib/containers; reboot"
##podman build -f docker/Dockerfile \
##  --build-arg RUN_WHEEL_CHECK="false" \
##  --tag vllm-gpu --target vllm-openai .

podman images

echo; echo "Build llama.cpp using 'cmake'"
cd ../llama.cpp
cmake -B build
cmake --build build --config Release -j $(nproc)


