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
log_file="docker_build_with_cache.log"  
  
# 清空或创建记录文件  
> "$log_file"  
  
# 遍历每个项目  
for project in "${projects[@]}"; do  
    echo "正在构建项目：$project"  
  
    # 进入项目目录  
    cd "$project" || { 
        echo "进入项目目录失败：$project" | tee -a "../$log_file" 
        continue 
    }  
  
    # 函数：构建镜像  
    build_image() {  
        local variant=$1      # "cpu" 或 "gpu"  
        local dockerfile=$2   # "cpuDockerfile" 或 "gpuDockerfile"  
  
        echo "构建${variant^^}镜像..."  
  
        attempt=1  
        max_attempts=3      # 总共尝试次数，包括初次构建和两次重试  
  
        while [ $attempt -le $max_attempts ]; do  
            start_time=$(date +%s.%N)  
            # 捕获构建输出  
            build_output=$(buildah bud -t "${project,,}-${variant}" -f "$dockerfile" . 2>&1)  
            build_status=$?  
            end_time=$(date +%s.%N)  
            # 计算构建时间（秒，保留小数）  
            build_time=$(echo "$end_time - $start_time" | bc)  
  
            if [ $build_status -eq 0 ]; then  
                image_size=$(buildah images --format '{{.Size}}' "localhost/${project,,}-${variant}")  
                echo "${project}-${variant} 构建时间：${build_time}秒，镜像大小：${image_size}字节" | tee -a "../$log_file"  
                # 将镜像保存到 /tmp 目录下  
                buildah push "${project,,}-${variant}" docker-archive:"/tmp/${project,,}-${variant}.tar"  
                break  
            else  
                echo "构建${variant^^}镜像失败，重试次数：$attempt"  
                if [ $attempt -eq $max_attempts ]; then  
                    echo "${project}-${variant} 构建失败，已重试${max_attempts}次" | tee -a "../$log_file"  
                    echo "失败信息：$build_output" | tee -a "../$log_file"  
                else  
                    echo "等待5秒后重试..."  
                    sleep 5  
                fi  
                attempt=$((attempt + 1))  
            fi  
        done  
    }  
  
    # 构建 CPU 镜像  
    build_image "cpu" "cpuDockerfile"  
  
    # 构建镜像任务之间休息30秒  
    echo "等待5秒后开始下一个镜像构建任务..."  
    sleep 5  
  
    # 构建 GPU 镜像  
    build_image "gpu" "gpuDockerfile"  
  
    # 构建任务之间休息30秒  
    echo "等待30秒后继续下一个项目..."  
    sleep 5  
  
    # 返回上级目录  
    cd ..  
  
    echo "$project 构建完成"  
    echo "---------------------------"  
done
