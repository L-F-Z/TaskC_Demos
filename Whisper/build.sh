# repo commit id
commit ba3f3cd54b0e5b8ce1ab3de13e32122d0d5f98ab (HEAD -> main, origin/main, origin/HEAD)

# CPU version
docker build -f cpuDockerfile -t whisper:cpu .
docker run -v ./test:/app/test \
     --rm \
     -it \
     whisper:gpu \
     python3 /app/test/test.py

rm ./test/res*

# GPU version
docker build -f gpuDockerfile -t whisper:gpu .
docker run -v ./test:/app/test \
     --gpus all \
     --rm \
     -it \
     whisper:gpu \
     python3 /app/test/test.py

rm ./test/res*