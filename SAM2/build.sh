# repo commit id
commit 7e1596c0b6462eb1d1ba7e1492430fed95023598 (HEAD -> main, origin/main, origin/HEAD)

# docker CPU version
docker build -f cpuDockerfile -t sam2:cpu .

docker run -it \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ./test:/app/test \
  -e DISPLAY=$DISPLAY \
  --rm \
  sam2:cpu \
  python3 /app/test/test.py

# clear test file
rm ./test/res*

# docker GPU version
docker build -f gpuDockerfile -t sam2:gpu .

docker run -it \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ./test:/app/test \
  -e DISPLAY=$DISPLAY \
  --gpus all \
  --rm \
  sam2:gpu \
  python3 /app/test/test.py

# clear test file
rm ./test/res*

# Apptainer CPU version
apptainer build /tmp/sam2_cpu.sif ./cpuApptainer.def
apptainer exec --bind ./test:/app/test --bind /tmp/.X11-unix:/tmp/.X11-unix /tmp/sam2_gpu.sif python3 /app/test/test.py 

# Apptainer GPU version
apptainer build /tmp/sam2_gpu.sif ./gpuApptainer.def
apptainer exec --nv --bind ./test:/app/test --bind /tmp/.X11-unix:/tmp/.X11-unix /tmp/sam2_gpu.sif python3 /app/test/test.py 