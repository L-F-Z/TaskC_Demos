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
log_file="buildah_build_no_cache.log"  

# 清空或创建记录文件  
> "$log_file"  

# 遍历每个项目  
for project in "${projects[@]}"; do  
    echo "正在构建项目：$project"  

    # 进入项目目录  
    cd "$project" || exit 1  

    # 构建CPU镜像并记录时间和镜像大小（无缓存）  
    echo "构建CPU镜像（无缓存）..."  
    attempt=1  
    max_attempts=3  # 总共尝试次数，包括初次构建和两次重试  

    while [ $attempt -le $max_attempts ]; do  
        start_time=$(date +%s)  
        buildah bud --layers=false -t ${project,,}-cpu -f cpuDockerfile .  
        build_status=$?  
        end_time=$(date +%s)  
        build_time=$((end_time - start_time))  

        if [ $build_status -eq 0 ]; then  
            image_size=$(buildah images --format '{{.Size}}' localhost/${project,,}-cpu)  
            echo "${project}-cpu 构建时间（无缓存）：${build_time}秒，镜像大小：${image_size}" | tee -a "../$log_file"  
            # 将镜像保存到/tmp目录下  
            buildah push ${project,,}-cpu docker-archive:/tmp/${project,,}-cpu.tar  
            break  
        else  
            echo "构建CPU镜像失败，重试次数：$attempt"  
            if [ $attempt -eq $max_attempts ]; then  
                echo "${project}-cpu 构建失败，已重试${max_attempts}次" | tee -a "../$log_file"  
            fi  
            attempt=$((attempt + 1))  
        fi  
    done  

    # 构建GPU镜像并记录时间和镜像大小（无缓存）  
    echo "构建GPU镜像（无缓存）..."  
    attempt=1  

    while [ $attempt -le $max_attempts ]; do  
        start_time=$(date +%s)  
        buildah bud --layers=false -t ${project,,}-gpu -f gpuDockerfile .  
        build_status=$?  
        end_time=$(date +%s)  
        build_time=$((end_time - start_time))  

        if [ $build_status -eq 0 ]; then  
            image_size=$(buildah images --format '{{.Size}}' localhost/${project,,}-gpu)  
            echo "${project}-gpu 构建时间（无缓存）：${build_time}秒，镜像大小：${image_size}" | tee -a "../$log_file"  
            # 将镜像保存到/tmp目录下  
            buildah push ${project,,}-gpu docker-archive:/tmp/${project,,}-gpu.tar  
            break  
        else  
            echo "构建GPU镜像失败，重试次数：$attempt"  
            if [ $attempt -eq $max_attempts ]; then  
                echo "${project}-gpu 构建失败，已重试${max_attempts}次" | tee -a "../$log_file"  
            fi  
            attempt=$((attempt + 1))  
        fi  
    done  

    # 返回上级目录  
    cd ..  

    echo "$project 构建完成"  
    echo "---------------------------"  
done