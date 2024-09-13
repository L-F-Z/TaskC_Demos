commit 1210b49cd2cb21bb70ed92b04f872317c18d1fbb (HEAD -> main, origin/main, origin/HEAD)


docker build -f cpuDockerfile -t yolov8:cpu .

docker run -it --rm -v ./test:/ultralytics/runs yolov8:cpu

docker build -f gpuDockerfile -t yolov8:gpu .

docker run -it --rm --gpus all -v ./test:/ultralytics/runs yolov8:gpu