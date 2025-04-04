#!/bin/bash  

# define colors  
RED=$'\033[0;31m'  
GREEN=$'\033[0;32m'  
YELLOW=$'\033[1;33m'  
BLUE=$'\033[0;34m'  
NC=$'\033[0m'
                
usage() {  
    echo "用法: bash $0 [proj1 proj2 ... | all]" 
    echo "  proj: 构建指定的项目，例如 ${BLUE}bash Docker.sh CLIP${NC}"  
    echo "  all : 构建所有项目，例如 ${BLUE}bash Docker.sh all${NC}"  
    echo "  支持同时构建多个项目，例如 ${BLUE}bash Docker.sh CLIP YOLOv5${NC}"
    echo "Flags:"
    echo "  --no-cache   每次构建时清除缓存，例如 ${BLUE}bash --no-cache Docker.sh CLIP${NC}"  
    echo "  --cpu        仅构建 CPU 版本的镜像，例如 ${BLUE}bash --cpu Docker.sh CLIP${NC}"  
    echo "  --gpu        仅构建 GPU 版本的镜像，例如 ${BLUE}bash --gpu Docker.sh CLIP${NC}" 
    echo "Available Commands:"
    echo "  cleanlog: 清空日志和报错信息文件"
    echo "  cleanbuild: 清空所有docker镜像、容器和缓存"
    exit 1  
}  

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  
project_base_dir="${script_dir}"  

max_attempts=3
use_cache=true  
cpu_only=false  
gpu_only=false

error_dir="${project_base_dir}/error_logs"
mkdir -p ${error_dir}
log_file="logDocker.log"

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
        --amd)
            amd_env=true
            ;;
        --jetson)
            jetson_env=true
            ;;
        *)  
            project_args+=("$arg") # Collect additional arguments for projects  
            ;;  
    esac  
done 



clean_cache_if_needed() {  
    if [ "$use_cache" = false ]; then  
        clean_docker  
    fi  
} 

build_image() {
    clean_cache_if_needed
    attempt=1  

    local project=$1  
    local dockerfile=$2   # "Dockerfile"
    if [ "$amd_env" = true ]; then
        dockerfile="amdDockerfile"
    fi
    if [ "$jetson_env" = true ]; then
        dockerfile="jetsonDockerfile"
    fi

    local project_dir="${project_base_dir}/${project}" 
    local error_logfile="docker_${project,,}_error.log"

    if [ ! -d "$project_dir" ]; then  
        echo "${RED}错误: 项目目录不存在: $project_dir${NC}"  
        return 1  
    fi  
    cd "$project_dir" || { echo "${RED}错误: 无法进入项目目录: $project_dir${NC}"; return 1; }  

    echo "正在构建 ${project,,} 镜像..." 
    while [ $attempt -le $max_attempts ]; do
        if [ "$use_cache" = false ]; then
            { time docker build --no-cache -t "${project,,}" -f "$dockerfile" . > log.log ; } 2> output.log  
        else
            { time docker build -t "${project,,}" -f "$dockerfile" . > log.log ; } 2> output.log  
        fi

        build_status=$? 
        build_time=$(grep '^real' output.log | awk '{print $2}')  
        if [ $build_status -eq 0 ]; then  
            image_size=$(docker image inspect "${project,,}:latest" --format='{{.Size}}') 
            # image_size_mb=$(echo "scale=2; $image_size/1024/1024" | bc)
            echo "${project,,}, ${build_time}, ${image_size}" | tee -a "../$log_file"
            echo "${GREEN}${project,,} 镜像构建完成${NC}"
            rm log.log
            rm output.log
            break
        else
            echo "${RED}构建 ${project,,} 镜像失败，尝试次数: $attempt${NC}"  
            echo -e "错误信息：\n$(<log.log)\n$(<output.log)\n" >> "${error_dir}/${error_logfile}"
            if [ $attempt -lt $max_attempts ]; then  
                clean_cache_if_needed
                echo "等待 1 秒后重试..."  
                sleep 1
            fi  
            attempt=$((attempt + 1))  
        fi
        rm log.log
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
    local error_logfile="docker_${project,,}_${variant}_error.log"

    if [ ! -d "${project_dir}" ]; then  
        echo "${RED}}错误: 项目目录不存在: ${project_dir}${NC}"  
        return 1  
    fi  
    cd "${project_dir}" || { echo "${RED}错误: 无法进入项目目录: ${project_dir}${NC}"; return 1; }  

    echo "正在构建 ${project,,}-${variant} 镜像..."  
    while [ $attempt -le $max_attempts ]; do  
        if [ "$use_cache" = false ]; then
            { time docker build --no-cache -t "${project,,}-${variant}" -f "$dockerfile" . > log.log ; } 2> output.log  
        else
            { time docker build -t "${project,,}-${variant}" -f "$dockerfile" . > log.log ; } 2> output.log  
        fi

        build_status=$?  
        build_time=$(grep '^real' output.log | awk '{print $2}')  
        
        if [ $build_status -eq 0 ]; then  
            image_size=$(docker image inspect "${project,,}-${variant}:latest" --format='{{.Size}}')  
            # image_size_mb=$(echo "scale=2; $image_size/1024/1024" | bc)  
            echo "${project,,}-${variant}, ${build_time}, ${image_size}" | tee -a "../$log_file"
            echo "${GREEN}${project,,}-${variant} 镜像构建完成${NC}"  
            rm log.log
            rm output.log
            break  
        else  
            echo "${RED}构建 ${project,,}-${variant} 镜像失败，尝试次数: $attempt${NC}" 
            echo -e "错误信息：\n$(<log.log)\n$(<output.log)\n" >> "${error_dir}/${error_logfile}"

            # Retry
            if [ $attempt -lt $max_attempts ]; then 
                clean_cache_if_needed
                echo "等待 1 秒后重试..." 
                sleep 1  
            fi
            attempt=$((attempt + 1))  
        fi
        rm log.log
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
        curl http://192.168.143.41:9081/repository/storage/docker/${project}-cpu -o /tmp/${project}-cpu
        build_image2 "${project}" "cpu" "cpuDockerfile"  
        curl http://192.168.143.41:9081/repository/storage/docker/${project}-cpu -o /tmp/${project}-cpu
        TIMESTAMP=$(date +%s) 
        echo "end, $TIMESTAMP" | tee -a "$log_file"

    fi  
    if [ "$gpu_only" = true ]; then  
        TIMESTAMP=$(date +%s) 
        echo "start, $TIMESTAMP" | tee -a "$log_file"
        curl http://192.168.143.41:9081/repository/storage/docker/${project}-gpu -o /tmp/${project}-gpu
        build_image2 "${project}" "gpu" "gpuDockerfile"  
        curl http://192.168.143.41:9081/repository/storage/docker/${project}-gpu -o /tmp/${project}-gpu
        TIMESTAMP=$(date +%s) 
        echo "end, $TIMESTAMP" | tee -a "$log_file"

    fi 
    if [ "$cpu_only" = false ] && [ "$gpu_only" = false ]; then  
        TIMESTAMP=$(date +%s) 
        echo "start, $TIMESTAMP" | tee -a "$log_file"
        curl http://192.168.143.41:9081/repository/storage/docker/${project}-cpu -o /tmp/${project}-cpu
        build_image2 "${project}" "cpu" "cpuDockerfile"  
        curl http://192.168.143.41:9081/repository/storage/docker/${project}-cpu -o /tmp/${project}-cpu
        TIMESTAMP=$(date +%s) 
        echo "end, $TIMESTAMP" | tee -a "$log_file"

        TIMESTAMP=$(date +%s) 
        echo "start, $TIMESTAMP" | tee -a "$log_file"
        curl http://192.168.143.41:9081/repository/storage/docker/${project}-gpu -o /tmp/${project}-gpu
        build_image2 "${project}" "gpu" "gpuDockerfile"
        curl http://192.168.143.41:9081/repository/storage/docker/${project}-gpu -o /tmp/${project}-gpu
        TIMESTAMP=$(date +%s) 
        echo "end, $TIMESTAMP" | tee -a "$log_file"
    fi
}

buildImage() {
    local project=$1
    TIMESTAMP=$(date +%s) 
    echo "start, $TIMESTAMP" | tee -a "$log_file"
    curl http://192.168.143.41:9081/repository/storage/docker/${project} -o /tmp/${project}
    build_image "${project}" "Dockerfile"
    curl http://192.168.143.41:9081/repository/storage/docker/${project} -o /tmp/${project}
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
    if [ "$amd_env" = true ] || [ "$jetson_env" = true ] ; then
        buildImage "YOLO11"
    else
        buildImage2 "YOLO11"
    fi
}  

clean_logfile () {
    rm "$log_file" 
    rm -rf $error_dir 
    mkdir -p $error_dir
}

clean_docker() {
    if [ "$(docker ps -q)" ]; then
        docker stop $(docker ps -q) 
    fi
    if [ "$(docker images -q)" ]; then
        docker rmi --force $(docker images -q) 
    fi
    docker system prune -a -f 
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
    build_Transformers 
    build_TTS 
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
            clean_docker
            ;;
        *)  
            echo "${RED}错误: 未知的项目 '$arg'${NC}"  
            echo "可用的项目列表: CLIP, LoRA, SAM2, Stable-Baselines3, Transformers, Whisper, YOLO11, TTS, stablediffusion"  
            usage  
            ;;  
    esac  
done  

