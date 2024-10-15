#!/bin/bash

# 定义项目列表
projects=(
    "CLIP"
    "Deep_Live_Cam"
    "LoRA"
    "SAM2"
    "Stable-Baselines3"
    # "TTS"
    "Transformers"
    "Whisper"
    "YOLO11"
    "YOLOv5"
    "YOLOv8"
    "mmpretrain"
    "stablediffusion"
)

log_file="logDocker_noCache.log"

> "$log_file"

for project in "${projects[@]}"; do
    echo "Building project: $project"

    cd "$project" || {
        echo "Failed to enter project directory: $project" | tee -a "../$log_file"
        continue
    }

    build_image() {
        local variant=$1 # cpu or gpu
        local dockerfile=$2 # cpuDockerfile or gpuDockerfile

        echo "Building ${variant^^} image..."

        # set attempt number
        attempt=1
        max_attempts=3 # total attempts including initial build and two retries
        while [ $attempt -le $max_attempts ]; do
            # use built-in time command to measure build time
            {time docker build --no-cache -t "${project,,}-${variant}" -f "$dockerfile" . > build_output.log;} 2> time_output.log
            build_status=$?

            # read build output
            build_output=$(cat build_output.log)
            rm build_output.log

            if [ $build_status -eq 0 ]; then
                # extract build time (real time)
                build_time=$(grep real time_output.log | awk '{print $2}')
                rm time_output.log

                # get image size
                image_size=$(docker image inspect "${project,,}-${variant}:latest" --format='{{.Size}}')
                image_size_mb=$(echo "scale=2; $image_size/1024/1024" | bc)
                echo "${project}-${variant}, ${build_time}, ${image_size_mb}MB" | tee -a "../$log_file"
                break
            else
                echo "Failed to build ${variant^^} image, attempt: $attempt"
                if [ $attempt -eq $max_attempts ]; then
                    echo "${project}-${variant} failed to build after $max_attempts attempts" | tee -a "../$log_file"
                    # echo "Error message: \n $build_output" | tee -a "../$log_file"
                    {mkdir -p ./error_logs}
                    echo "Error message: \n $build_output" | tee -a "./error_logs/docker_${project}-${variant}_error.log"
                else
                    echo "Waiting for retrying..."
                fi
                attempt=$((attempt + 1))
            fi

            # clean all docker cache 
            {docker rmi $(docker images -q) > /dev/null;} 2> /dev/null
            {docker system prune -a -f > /dev/null;} 2> /dev/null
            {docker system df}
            
            sleep 1
        done
    }
    # build CPU image
    build_image "cpu" "cpuDockerfile"
    echo "Waiting 1s before starting the next image build task..."
    sleep 1

    # build GPU image
    build_image "gpu" "gpuDockerfile"
    echo "Waiting 1s before starting the next project..."
    sleep 1

    cd ..
    echo "$project done"
    echo "-----------------------------------"

done