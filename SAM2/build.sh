# CPU version
docker build -f cpuDockerfile -t sam2:cpu .


# GPU version
docker build -f gpuDockerfile -t sam2:gpu .