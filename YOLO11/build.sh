commit fe61f9d54a69c837a09c4f18668aecc169556e96 (HEAD -> main, tag: v8.3.5, origin/main, origin/HEAD)

cd ultralytics && docker build -f ../cpuDockerfile -t yolo11:cpu .
docker run -it --rm -v ./test:/ultralytics/runs yolo11:cpu


cd ultralytics && docker build -f ../gpuDockerfile -t yolo11:gpu .
docker run -it --rm --gpus all -v ./test:/ultralytics/runs yolo11:gpu