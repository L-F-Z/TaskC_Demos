
#!/bin/bash

# Define project list
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

log_file="logApptainer_withCache.log"

> "$log_file"

for project in "${projects[@]}"; do
    echo "Building project: $project"

    cd "$project" || {
        echo "Failed to enter project directory: $project" | tee -a "../$log_file"
        continue
    }

    build_container() {
        local variant=$1      # "cpu" or "gpu"
        local def_file=$2     # "cpuApptainer.def" or "gpuApptainer.def"
        local output_sif="/tmp/${project}_${variant}.sif"

        echo "Building ${variant^^} container..."

        attempt=1
        max_attempts=3

        while [ $attempt -le $max_attempts ]; do
            { time apptainer build --no-https "$output_sif" "$def_file" > build_output.log; } 2> time_output.log
            build_status=$?

            build_output=$(cat build_output.log)
            rm build_output.log

            build_time=$(grep real time_output.log | awk '{print $2}')
            rm time_output.log

            if [ $build_status -eq 0 ]; then
                if [ -f "$output_sif" ]; then
                    image_size=$(stat -c%s "$output_sif")
                    image_size_mb=$(echo "scale=2; $image_size/1024/1024" | bc)
                    echo "${project}-${variant}, ${build_time}, ${image_size_mb}MB" | tee -a "../$log_file"
                else
                    echo "SIF file not found for ${project}-${variant}" | tee -a "../$log_file"
                fi
                break
            else
                echo "Failed to build ${variant^^} container, attempt: $attempt"
                if [ $attempt -eq $max_attempts ]; then
                    echo "${project}-${variant} failed to build after ${max_attempts} attempts" | tee -a "../$log_file"
                    # echo -e "Error message:\n$build_output" | tee -a "../$log_file"
                    # store error message in an another log file
                    # create a new dir if it doesn't exist
                    {mkdir -p ./error_logs}
                    echo "Error message: \n $build_output" | tee -a "./error_logs/apptainer_${project}-${variant}_error.log"
                    
                else
                    echo "Waiting 1 second before retrying..."
                    sleep 1
                fi
                attempt=$((attempt + 1))
            fi

            # clean apptainer cache
            # rm all sif
            {rm -rf /tmp/*}
            # clean cache
            {apptainer cache clean}
            sleep 1
        done
    }

    build_container "cpu" "cpuApptainer.def"
    echo "Waiting 1s before starting the next container build task..."
    sleep 1

    build_container "gpu" "gpuApptainer.def"
    echo "Waiting 1s before continuing to the next project..."
    sleep 1

    cd ..

    echo "$project build completed"
    echo "-----------------------------------"
done
