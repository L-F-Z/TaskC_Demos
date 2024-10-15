#!/bin/bash  
  
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
  
log_file="logBuildah_withCache.log"  
  
> "$log_file"  
  
for project in "${projects[@]}"; do  
    echo "Building project:$project"  
  
    cd "$project" || { 
        echo "Failed to enter project directory:$project" | tee -a "../$log_file" 
        continue 
    }  
  
    build_image() {  
        local variant=$1      # "cpu" or "gpu"  
        local dockerfile=$2   # "cpuDockerfile" or "gpuDockerfile"  
  
        echo "Building ${variant^^} image..."  
  
        attempt=1  
        max_attempts=3    
  
        while [ $attempt -le $max_attempts ]; do 
            { time buildah bud -t "${project,,}-${variant}" -f "$dockerfile" . > build_output.log; } 2> time_output.log
            build_status=$?

            build_output=$(cat build_output.log)
            rm build_output.log

            build_time=$(grep real time_output.log | awk '{print $2}')
            rm time_output.log

            if [ $build_status -eq 0 ]; then
                image_size=$(buildah inspect "${project,,}-${variant}" --format='{{.Size}}')
                image_size_mb=$(echo "scale=2; $image_size/1024/1024" | bc)
                echo "${project}-${variant}, ${build_time}, ${image_size_mb}MB" | tee -a "../$log_file"
                break
            else
                echo "Failed to build ${variant^^} image, attempt: $attempt"
                if [ $attempt -eq $max_attempts ]; then
                    echo "${project}-${variant} failed to build after ${max_attempts} attempts" | tee -a "../$log_file"
                    # store error message in an another log file
                    {mkdir -p ./error_logs}
                    echo "$build_output" > "./error_logs/${project,,}-${variant}_error.log"
                else
                    echo "Waiting 1 second before retrying..."
                    sleep 1
                fi
                attempt=$((attempt + 1))
            fi
        done  
    }  
  
    build_image "cpu" "cpuDockerfile"
    echo "Waiting 1s before starting the next image build task..."
    sleep 1

    build_image "gpu" "gpuDockerfile"
    echo "Waiting 1s before continuing to the next project..."
    sleep 1
  
    cd ..  
  
    echo "$project build completed"  
    echo "---------------------------"  
done