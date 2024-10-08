#!/bin/bash

# 定义项目列表
projects=(
    "CLIP"
    "Deep_Live_Cam"
    "LoRA"
    "SAM2"
    "Stable-Baselines3"
    "TTS"
    "Transformers"
    "Whisper"
    "YOLOv5"
    "YOLOv8"
    "mmpretrain"
    "stablediffusion"
)

# 构建时间和镜像大小记录文件
log_file="apptainer_build_with_cache.log"

# 清空或创建日志文件
> "$log_file"

# 遍历每个项目
for project in "${projects[@]}"; do
    echo "Building project: $project"

    # 进入项目目录
    cd "$project" || {
        echo "Failed to enter project directory: $project" | tee -a "../$log_file"
        continue
    }

    # 定义构建镜像的函数
    build_image() {
        local variant=$1      # "cpu" 或 "gpu"
        local deffile=$2   # "cpuApptainer.def" 或 "gpuApptainer.def"

        echo "Building ${variant^^} image..."

        attempt=1
        max_attempts=3      # 总共尝试次数，包括初始构建和两次重试

        while [ $attempt -le $max_attempts ]; do
            # 使用内置的 time 命令测量构建时间
            # 将构建输出和时间输出分别重定向
            # apptainer build /tmp/whisper_cpu.sif ./cpuApptainer.def
            { time apptainer build /tmp/"${project,,}-${variant}".sif ./"$deffile"> build_output.log; } 2> time_output.log
            build_status=$?

            # 读取构建输出
            build_output=$(cat build_output.log)
            rm build_output.log

            # 提取构建时间（real 时间）
            build_time=$(grep real time_output.log | awk '{print $2}')
            rm time_output.log

            if [ $build_status -eq 0 ]; then
                if [ -f /tmp/"${project,,}-${variant}".sif ]; then  
                    image_size=$(stat -c%s "/tmp/${project,,}-${variant}.sif")  
                    image_size_mb=$(echo "scale=2; $image_size/1024/1024" | bc)  
                else  
                    image_size_mb="N/A"  
                fi  

                echo "${project}-${variant}, ${build_time}, ${image_size_mb}MB" | tee -a "../$log_file"
                break
            else
                echo "Failed to build ${variant^^} image, attempt: $attempt"
                if [ $attempt -eq $max_attempts ]; then
                    echo "${project}-${variant} failed to build after ${max_attempts} attempts" | tee -a "../$log_file"
                    echo "Error message: $build_output" | tee -a "../$log_file"
                else
                    echo "Waiting 1 second before retrying..."
                    sleep 1
                fi
                attempt=$((attempt + 1))
            fi
        done
    }

    # 构建 CPU 镜像
    build_image "cpu" "cpuApptainer.def"

    # 在开始下一个镜像构建任务前暂停 1 秒
    echo "Waiting 1 second before starting the next image build task..."
    sleep 1

    # 构建 GPU 镜像
    build_image "gpu" "gpuApptainer.def"

    # 在继续下一个项目前暂停 1 秒
    echo "Waiting 1 second before continuing to the next project..."
    sleep 1

    # 返回到父目录
    cd ..

    echo "$project build completed"
    echo "---------------------------"
done