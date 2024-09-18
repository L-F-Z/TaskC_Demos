commit 12b577c8d33d3a36e954cb3a9eca5fa55428563c (HEAD -> master, origin/master, origin/HEAD)

docker build -f cpuDockerfile -t yolov5:cpu .
docker run -it --rm -v ./test:/usr/src/app/test yolov5:cpu

docker build -f gpuDockerfile -t yolov5:gpu .
docker run -it --rm --gpus all -v ./test:/usr/src/app/test yolov5:gpu