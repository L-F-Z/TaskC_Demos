# repo commit id
commit dc8563372db7032d13c6dffa0a6349e2e9f897d4 (HEAD -> main, origin/main, origin/HEAD)

# CPU version
docker build -f cpuDockerfile -t cam:cpu .
docker run -v ./test:/app/test \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e DISPLAY=$DISPLAY \
    --rm \
    -it \
    cam:cpu \
    python3 run.py --execution-provider cpu -s /app/test/pic.jpg -t /app/test/video360.mp4 -o /app/test/res.mp4

rm  ./test/res*

# GPU version
docker build -f gpuDockerfile -t cam:gpu .
docker run -v ./test:/app/test \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e DISPLAY=$DISPLAY \
    --gpus all \
    --rm \
    -it \
    cam:gpu \
    python3 /app/Deep-Live-Cam/run.py --execution-provider cuda -s /app/test/pic.jpg -t /app/test/video360.mp4 -o /app/test/res.mp4

rm  ./test/res*

# Apptainer CPU version
apptainer build /tmp/cam_cpu.sif ./cpuApptainer.def
apptainer exec --bind ./test:/app/test --bind /tmp/.X11-unix:/tmp/.X11-unix /tmp/cam_cpu.sif python3 run.py --execution-provider cpu -s /app/test/pic.jpg -t /app/test/video360.mp4 -o /app/test/res.mp4

# Apptainer GPU version
apptainer build /tmp/cam_gpu.sif ./gpuApptainer.def
apptainer exec --nv --bind ./test:/app/test --bind /tmp/.X11-unix:/tmp/.X11-unix /tmp/cam_gpu.sif python3 /app/Deep-Live-Cam/run.py --execution-provider cuda -s /app/test/pic.jpg -t /app/test/video360.mp4 -o /app/test/res.mp4