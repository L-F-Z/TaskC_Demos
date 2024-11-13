#!/bin/bash  

# define colors  
RED=$'\033[0;31m'  
GREEN=$'\033[0;32m'  
YELLOW=$'\033[1;33m'  
BLUE=$'\033[0;34m'  
NC=$'\033[0m'
                
usage() {  
    echo "用法: bash $0 [proj1 proj2 ... | all]"
    echo "  proj: 构建指定的项目，例如 ${BLUE}bash Buildah.sh CLIP${NC}"  
    echo "  all : 构建所有项目，例如 ${BLUE}bash Buildah.sh all${NC}"  
    echo "  支持同时构建多个项目，例如 ${BLUE}bash Buildah.sh CLIP YOLOv5${NC}"
    echo "Flags:"
    echo "  --no-cache   每次构建时清除缓存"  
    echo "  --cpu        仅构建 CPU 版本的镜像"  
    echo "  --gpu        仅构建 GPU 版本的镜像" 
    echo "Available Commands:"
    echo "  cleanlog: 清空日志和报错信息文件"
    echo "  cleanbuild: 清空所有Buildah镜像和缓存"
    exit 1  
}  

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  
project_base_dir="${script_dir}"  

max_attempts=3
use_cache=true  
cpu_only=false  
gpu_only=false

# Parse command line arguments  
project_args=()  
for arg in "$@"; do  
    case "$arg" in  
        --no-cache)  
            use_cache=false  
            ;;  
        --cpu)  
            cpu_only=true  
            ;;  
        --gpu)  
            gpu_only=true  
            ;;  
        *)  
            project_args+=("$arg") # Collect additional arguments for projects  
            ;;  
    esac  
done 

log_file="logBuildah.log" 
error_dir="$project_base_dir/error_logs"
mkdir -p ${error_dir}

clean_cache_if_needed() {  
    if [ "$use_cache" = false ]; then  
        clean_buildah  
    fi  
} 

build_image() {
    clean_cache_if_needed
    attempt=1  

    local project=$1  
    local dockerfile=$2   # "Dockerfile"
    local project_dir="${project_base_dir}/${project}" 
    local error_logfile="buildah_${project,,}_error.log"


    if [ ! -d "$project_dir" ]; then  
        echo "${RED}错误: 项目目录不存在: $project_dir${NC}"  
        return 1  
    fi  
    cd "$project_dir" || { echo "${RED}错误: 无法进入项目目录: $project_dir${NC}"; return 1; }  

    echo "正在构建 ${project,,} 镜像..." 
    while [ $attempt -le $max_attempts ]; do
        if [ "$use_cache" = false ]; then
            { time buildah bud --no-cache -t "${project,,}" -f "$dockerfile" . > output.log; } 2> time_output.log  
        else
            { time buildah bud -t "${project,,}" -f "$dockerfile" . > output.log; } 2> time_output.log  
        fi

        build_status=$? 
        build_time=$(grep '^real' time_output.log | awk '{print $2}')  
        if [ $build_status -eq 0 ]; then  
            image_size=$(buildah inspect "${project,,}:latest" | jq '[.Manifest | fromjson | .config.size] + [.Manifest | fromjson | .layers[].size] | add')  
            # image_size_mb=$(echo "scale=2; $image_size/1024/1024" | bc)
            echo "${project,,}, ${build_time}, ${image_size}" | tee -a "../$log_file"
            echo "${GREEN}${project,,} 镜像构建完成${NC}"
            rm time_output.log
            rm output.log
            break
        else
            echo "${RED}构建 ${project,,} 镜像失败，尝试次数: $attempt${NC}"  
            echo -e "错误信息：\n$(<time_output.log)\n\n$(<output.log)\n" >> "${error_dir}/${error_logfile}"
            if [ $attempt -lt $max_attempts ]; then  
                clean_cache_if_needed
                echo "等待 1 秒后重试..."  
                sleep 1
            fi  
            attempt=$((attempt + 1))  
        fi
        rm time_output.log
        rm output.log 
    done

    cd "$script_dir" || exit
    echo "-----------------------------------"  
    sleep 5

}

build_image2() {
    clean_cache_if_needed
    attempt=1  

    local project=$1  
    local variant=$2      # "cpu" 或 "gpu"  
    local dockerfile=$3   # "cpuDockerfile" 或 "gpuDockerfile"  
    local project_dir="${project_base_dir}/${project}" 
    local error_logfile="buildah_${project,,}_${variant}_error.log"


    if [ ! -d "${project_dir}" ]; then  
        echo "${RED}}错误: 项目目录不存在: ${project_dir}${NC}"  
        return 1  
    fi  
    cd "${project_dir}" || { echo "${RED}错误: 无法进入项目目录: ${project_dir}${NC}"; return 1; }  

    echo "正在构建 ${project,,}-${variant} 镜像..."  
    while [ $attempt -le $max_attempts ]; do  
        if [ "$use_cache" = false ]; then
            { time buildah bud --no-cache -t "${project,,}-${variant}" -f "$dockerfile" . > output.log; } 2> time_output.log  
        else
            { time buildah bud -t "${project,,}-${variant}" -f "$dockerfile" . > output.log; } 2> time_output.log  
        fi

        build_status=$?  
        build_time=$(grep '^real' time_output.log | awk '{print $2}')  
        
        if [ $build_status -eq 0 ]; then  
            image_size=$(buildah inspect "${project,,}-${variant}:latest" | jq '[.Manifest | fromjson | .config.size] + [.Manifest | fromjson | .layers[].size] | add')  
            # image_size_mb=$(echo "scale=2; $image_size/1024/1024" | bc)  
            echo "${project,,}-${variant}, ${build_time}, ${image_size}" | tee -a "../$log_file"
            echo "${GREEN}${project,,}-${variant} 镜像构建完成${NC}"  
            rm time_output.log
            rm output.log
            break  
        else  
            echo "${RED}构建 ${project,,}-${variant} 镜像失败，尝试次数: $attempt${NC}" 
            echo -e "错误信息：\n$(<time_output.log)\n\n$(<output.log)\n" >> "${error_dir}/${error_logfile}"

            # Retry
            if [ $attempt -lt $max_attempts ]; then 
                clean_cache_if_needed
                echo "等待 1 秒后重试..." 
                sleep 1  
            fi
            attempt=$((attempt + 1))  
        fi
        rm time_output.log
        rm output.log 
    done  

    cd "$script_dir" || exit  
    echo "-----------------------------------"  
    sleep 5

} 

buildImage2() {
    local project=$1
    if [ "$cpu_only" = true ]; then  
        TIMESTAMP=$(date +%s) 
        echo "start, $TIMESTAMP" | tee -a "$log_file"
        curl http://192.168.143.41:9081/repository/storage/buildah/${project}-cpu -o /tmp/${project}-cpu
        build_image2 "${project}" "cpu" "cpuDockerfile"  
        curl http://192.168.143.41:9081/repository/storage/buildah/${project}-cpu -o /tmp/${project}-cpu
        TIMESTAMP=$(date +%s) 
        echo "end, $TIMESTAMP" | tee -a "$log_file"
    fi  
    if [ "$gpu_only" = true ]; then  
        TIMESTAMP=$(date +%s) 
        echo "start, $TIMESTAMP" | tee -a "$log_file"
        curl http://192.168.143.41:9081/repository/storage/buildah/${project}-gpu -o /tmp/${project}-gpu
        build_image2 "${project}" "gpu" "gpuDockerfile"  
        curl http://192.168.143.41:9081/repository/storage/buildah/${project}-gpu -o /tmp/${project}-gpu
        TIMESTAMP=$(date +%s) 
        echo "end, $TIMESTAMP" | tee -a "$log_file"
    fi 
    if [ "$cpu_only" = false ] && [ "$gpu_only" = false ]; then
        TIMESTAMP=$(date +%s) 
        echo "start, $TIMESTAMP" | tee -a "$log_file"
        curl http://192.168.143.41:9081/repository/storage/buildah/${project}-cpu -o /tmp/${project}-cpu
        build_image2 "${project}" "cpu" "cpuDockerfile"  
        curl http://192.168.143.41:9081/repository/storage/buildah/${project}-cpu -o /tmp/${project}-cpu
        TIMESTAMP=$(date +%s) 
        echo "end, $TIMESTAMP" | tee -a "$log_file"

        TIMESTAMP=$(date +%s) 
        echo "start, $TIMESTAMP" | tee -a "$log_file"
        curl http://192.168.143.41:9081/repository/storage/buildah/${project}-gpu -o /tmp/${project}-gpu
        build_image2 "${project}" "gpu" "gpuDockerfile"
        curl http://192.168.143.41:9081/repository/storage/buildah/${project}-gpu -o /tmp/${project}-gpu
        TIMESTAMP=$(date +%s) 
        echo "end, $TIMESTAMP" | tee -a "$log_file"
    fi
}

buildImage() {
    local project=$1
    TIMESTAMP=$(date +%s) 
    echo "start, $TIMESTAMP" | tee -a "$log_file"
    curl http://192.168.143.41:9081/repository/storage/buildah/${project} -o /tmp/${project}
    build_image "${project}" "Dockerfile"
    curl http://192.168.143.41:9081/repository/storage/buildah/${project} -o /tmp/${project}
    TIMESTAMP=$(date +%s) 
    echo "end, $TIMESTAMP" | tee -a "$log_file"

}

build_CLIP() {  
    buildImage "CLIP"
}  

build_LoRA() {  
    buildImage2 "LoRA"
}  

build_SAM2() {  
    buildImage "SAM2"
}  

build_Stable-Baselines3() {  
    buildImage2 "Stable-Baselines3"
}

build_stablediffusion() {  
    buildImage "stablediffusion"
}  

build_TTS() {  
    buildImage "TTS"
}  

build_Transformers() {  
    buildImage2 "Transformers"  
}  

build_Whisper() {  
    buildImage "Whisper"
}  

build_YOLO11() {
    buildImage2 "YOLO11"
}  

clean_logfile () {
    rm "$log_file" 
    rm -rf $error_dir 
    mkdir -p $error_dir
}

clean_buildah() {
    if [ "$(buildah images -q)" ]; then
        buildah rmi -f --all 
    fi
    rm /var/lib/containers/cache/*
}

if [ ${#project_args[@]} -eq 0 ]; then  
    usage  
fi 

if [[ " ${project_args[*]} " == *" all "* ]]; then
    clean_logfile
    echo "开始构建所有项目..."  
    build_CLIP  
    build_LoRA  
    build_SAM2  
    build_Stable-Baselines3  
    build_stablediffusion  
    build_TTS
    build_Transformers  
    build_Whisper  
    build_YOLO11  
    echo "${GREEN}所有项目构建完成。${NC}"  
    exit 0  
fi  

for arg in "${project_args[@]}"; do 
    case "$arg" in  
        CLIP)  
            build_CLIP  
            ;;  
        LoRA)  
            build_LoRA  
            ;;  
        SAM2)  
            build_SAM2  
            ;;  
        Stable-Baselines3)  
            build_Stable-Baselines3  
            ;;  
        TTS)  
            build_TTS  
            ;;  
        Transformers)  
            build_Transformers  
            ;;  
        Whisper)  
            build_Whisper  
            ;;  
        YOLO11)  
            build_YOLO11  
            ;;  
        stablediffusion)  
            build_stablediffusion  
            ;;
        cleanlog)
            clean_logfile
            ;;
        cleanbuild)
            clean_buildah
            ;;
        *)  
            echo "${RED}错误: 未知的项目 '$arg'${NC}"  
            echo "可用的项目列表: CLIP, LoRA, SAM2, Stable-Baselines3, Transformers, Whisper, YOLO11, TTS, stablediffusion"  
            usage  
            ;;  
    esac  
done  

