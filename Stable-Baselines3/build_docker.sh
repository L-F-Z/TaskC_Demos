#!/bin/bash
USE_GPU="True"

CPU_PARENT=mambaorg/micromamba:1.5-jammy
GPU_PARENT=mambaorg/micromamba:1.5-jammy-cuda-11.7.1

TAG=stable-baselines3

# VERSION=$(cat ./stable_baselines3/version.txt)

if [[ ${USE_GPU} == "True" ]]; then
  PARENT=${GPU_PARENT}
  PYTORCH_DEPS="pytorch-cuda=11.7"
  VERSION="gpu"
  echo "USE_GPU selected"
else
  PARENT=${CPU_PARENT}
  PYTORCH_DEPS="cpuonly"
  VERSION="cpu"
  # TAG="${TAG}-cpu"
fi

echo "docker build --build-arg PARENT_IMAGE=${PARENT} --build-arg PYTORCH_DEPS=${PYTORCH_DEPS} -t ${TAG}:${VERSION} ."
docker build --build-arg PARENT_IMAGE=${PARENT} --build-arg PYTORCH_DEPS=${PYTORCH_DEPS} -t ${TAG}:${VERSION} .

docker tag ${TAG}:${VERSION} ${TAG}:latest

if [[ ${RELEASE} == "True" ]]; then
  docker push ${TAG}:${VERSION}
  docker push ${TAG}:latest
fi
