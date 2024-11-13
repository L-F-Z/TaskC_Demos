#!/bin/bash  

# define colors  
RED=$'\033[0;31m'  
GREEN=$'\033[0;32m'  
YELLOW=$'\033[1;33m'  
BLUE=$'\033[0;34m'  
NC=$'\033[0m'
                
usage() {  
    echo "用法: bash $0 [proj1 proj2 ... | all]"  
    echo "  proj: 构建指定的项目，例如 ${BLUE}bash Taskc.sh CLIP${NC}"  
    echo "  all : 构建所有项目，例如 ${BLUE}bash Taskc.sh all${NC}"  
    echo "  支持同时构建多个项目，例如 ${BLUE}bash Taskc.sh CLIP YOLOv5${NC}"
    echo "Flags:"
    echo "  --no-cache   每次构建时清除缓存，例如 ${BLUE}bash Taskc.sh --no-cache all${NC}"  
    echo "  --full       使用full版blueprint，full优先级高于cpu/gpu，例如 ${BLUE}bash Taskc.sh --full all${NC}"
    echo "  --cpu        仅构建 CPU 版本的镜像，例如 ${BLUE}bash Taskc.sh --cpu all${NC}"  
    echo "  --gpu        仅构建 GPU 版本的镜像，例如 ${BLUE}bash Taskc.sh --gpu all${NC}"
    echo "Available Commands:"
    echo "  cleanlog: 清空日志和报错信息文件"
    echo "  cleanbuild: 清空所有Taskc镜像、容器和缓存"
    exit 1  
}  

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  
project_base_dir="${script_dir}"  

max_attempts=3
use_cache=true  
cpu_only=false  
gpu_only=false
full_version=false

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
        --full)  
            full_version=true  
            ;;  
        *)  
            # Collect project names, ensuring they do not start with --  
            if [[ "$arg" != --* ]]; then  
                project_args+=("$arg")   
            else  
                echo "${RED}错误: 未知的项目 '$arg'${NC}"  
                usage  
                exit 1  
            fi  
            ;;  
    esac  
done   

error_dir="$project_base_dir/error_logs"
mkdir -p ${error_dir}
log1="logTaskc.log"
log2="logTaskc_full.log" 
if [ "$full_version" = true ]; then
    log_file=$log2
else
    log_file=$log1
fi

if [ "$full_version" = true ]; then
    error_logfile="taskc_full_${project,,}_error.log"  
else
    error_logfile="taskc_${project,,}_error.log"
fi

clean_cache_if_needed() {  
    if [ "$use_cache" = false ]; then  
        clean_taskc  
    fi  
} 

avg(){
    echo "cache: $use_cache"
    echo "cpu: $cpu_only"
    echo "gpu: $gpu_only"
    echo "full: $full_version"
}

build_image() {
    clean_cache_if_needed
    attempt=1  

    local project=$1
    local version=$2
    local buildfile="${project}.blueprint"
    local project_dir="${project_base_dir}/${project}" 
    local error_logfile="taskc_${project,,}_${version}_error.log"


    if [ ! -d "$project_dir" ]; then  
        echo "${RED}错误: 项目目录不存在: $project_dir${NC}"  
        return 1  
    fi  
    cd "$project_dir" || { echo "${RED}错误: 无法进入项目目录: $project_dir${NC}"; return 1; }  

    echo "正在构建 ${project,,} ${version} Tasck Image..." 
    while [ $attempt -le $max_attempts ]; do
        if [ "$version" = "cpu" ]; then
            { time taskc asm --id "${project,,}-${version}" --ignore-gpu "$buildfile" > output.log; } 2> time_output.log
        else
            { time taskc asm --id "${project,,}-${version}" "$buildfile" > output.log; } 2> time_output.log
        fi

        build_status=$? 
        build_time=$(grep '^real' time_output.log | awk '{print $2}')  

        if [ $build_status -eq 0 ]; then  
            image_size=$(du -sb /var/lib/taskc/Image/${project,,}-${version} | awk '{print $1}')
            # image_size_mb=$(echo "scale=2; $image_size/1024/1024" | bc)
            echo "${project,,}-${version}, ${build_time}, ${image_size}" | tee -a "../$log_file"
            echo "${GREEN}${project,,}-${version} Taskc Image 构建完成${NC}"
            rm time_output.log
            rm output.log
            break
        else
            echo "${RED}构建 ${project}-${version} Taskc Image 失败，尝试次数: $attempt${NC}"  
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

# build full with 1 version
build_image2() {
    clean_cache_if_needed
    attempt=1  

    local project=$1  
    local version=$2
    local buildfile="${project}-full.blueprint"
    local project_dir="${project_base_dir}/${project}" 
    local error_logfile="taskc_full_${project,,}_${version}_error.log"  

    if [ ! -d "$project_dir" ]; then  
        echo "${RED}错误: 项目目录不存在: $project_dir${NC}"  
        return 1  
    fi  
    cd "$project_dir" || { echo "${RED}错误: 无法进入项目目录: $project_dir${NC}"; return 1; }  

    echo "正在构建 ${project,,} Taskc Image..." 
    while [ $attempt -le $max_attempts ]; do
        if [ "$version" = "cpu" ]; then
            { time taskc asm --id "${project,,}-${version}-full" --ignore-gpu "$buildfile" > output.log; } 2> time_output.log
        else
            { time taskc asm --id "${project,,}-${version}-full" "$buildfile" > output.log; } 2> time_output.log
        fi
         
        build_status=$? 
        build_time=$(grep '^real' time_output.log | awk '{print $2}')  

        if [ $build_status -eq 0 ]; then  
            image_size=$(du -sb /var/lib/taskc/Image/${project,,}-${version}-full | awk '{print $1}')
            # image_size_mb=$(echo "scale=2; $image_size/1024/1024" | bc)
            echo "${project,,}-${version}-full, ${build_time}, ${image_size}" | tee -a "../$log_file"
            echo "${GREEN}${project,,}-${version}-full Taskc Image 构建完成${NC}"
            rm time_output.log
            rm output.log
            break
        else
            echo "${RED}构建 ${project,,}-${version}-full Taskc Image 失败，尝试次数: $attempt${NC}"  
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

# build full with 2 version
build_image3() {
    clean_cache_if_needed
    attempt=1  

    local project=$1  
    local version=$2
    local buildfile="${project}-full-${version}.blueprint"
    local project_dir="${project_base_dir}/${project}" 
    local error_logfile="taskc_full_${project,,}_${version}_error.log"  

    if [ ! -d "$project_dir" ]; then  
        echo "${RED}错误: 项目目录不存在: $project_dir${NC}"  
        return 1  
    fi  
    cd "$project_dir" || { echo "${RED}错误: 无法进入项目目录: $project_dir${NC}"; return 1; }  

    echo "正在构建 ${project,,} Taskc Image..." 
    while [ $attempt -le $max_attempts ]; do
        if [ "$version" = "cpu" ]; then
            { time taskc asm --id "${project,,}-${version}-full" --ignore-gpu "$buildfile" > output.log; } 2> time_output.log
        else
            { time taskc asm --id "${project,,}-${version}-full" "$buildfile" > output.log; } 2> time_output.log
        fi
         
        build_status=$? 
        build_time=$(grep '^real' time_output.log | awk '{print $2}')  

        if [ $build_status -eq 0 ]; then  
            image_size=$(du -sb /var/lib/taskc/Image/${project,,}-${version}-full | awk '{print $1}')
            # image_size_mb=$(echo "scale=2; $image_size/1024/1024" | bc)
            echo "${project,,}-${version}-full, ${build_time}, ${image_size}" | tee -a "../$log_file"
            echo "${GREEN}${project,,}-${version}-full Taskc Image 构建完成${NC}"
            rm time_output.log
            rm output.log
            break
        else
            echo "${RED}构建 ${project,,}-${version}-full Taskc Image 失败，尝试次数: $attempt${NC}"  
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

buildImage() {
    local project=$1
    if [ "$full_version" = false ]; then 
        if [ "$cpu_only" = true ]; then 
            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu -o /tmp/${project}-cpu
            build_image "${project}" "cpu" 
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu -o /tmp/${project}-cpu
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"

        fi
        if [ "$gpu_only" = true ]; then 
            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu -o /tmp/${project}-gpu
            build_image "${project}" "gpu" 
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu -o /tmp/${project}-gpu
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"
        fi
        if [ "$cpu_only" = false ] && [ "$gpu_only" = false ]; then 
            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu -o /tmp/${project}-cpu
            build_image "${project}" "cpu"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu -o /tmp/${project}-cpu
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"

            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu -o /tmp/${project}-gpu
            build_image "${project}" "gpu" 
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu -o /tmp/${project}-gpu
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"
        fi
    else
        if [ "$cpu_only" = true ]; then 
            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu-full -o /tmp/${project}-cpu-full
            build_image2 "${project}" "cpu" 
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu-full -o /tmp/${project}-cpu-full
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"
        fi
        if [ "$gpu_only" = true ]; then 
            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu-full -o /tmp/${project}-gpu-full
            build_image2 "${project}" "gpu" 
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu-full  -o /tmp/${project}-gpu-full
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"
        fi
        if [ "$cpu_only" = false ] && [ "$gpu_only" = false ]; then 
            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu-full -o /tmp/${project}-cpu-full
            build_image2 "${project}" "cpu"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu-full -o /tmp/${project}-cpu-full
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"

            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu-full -o /tmp/${project}-gpu-full
            build_image2 "${project}" "gpu" 
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu-full -o /tmp/${project}-gpu-full
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"
        fi
    fi
}

buildImage2() {
    local project=$1
    if [ "$full_version" = false ]; then 
        if [ "$cpu_only" = true ]; then 
            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu -o /tmp/${project}-cpu
            build_image "${project}" "cpu" 
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu -o /tmp/${project}-cpu
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"
        fi
        if [ "$gpu_only" = true ]; then 
            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu -o /tmp/${project}-gpu
            build_image "${project}" "gpu" 
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu -o /tmp/${project}-gpu
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"
        fi
        if [ "$cpu_only" = false ] && [ "$gpu_only" = false ]; then 
            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu -o /tmp/${project}-cpu
            build_image "${project}" "cpu"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu -o /tmp/${project}-cpu
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"

            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu -o /tmp/${project}-gpu
            build_image "${project}" "gpu" 
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu -o /tmp/${project}-gpu
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"
        fi
    else
        if [ "$cpu_only" = true ]; then 
            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu-full -o /tmp/${project}-cpu-full
            build_image3 "${project}" "cpu" 
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu-full -o /tmp/${project}-cpu-full
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"
        fi
        if [ "$gpu_only" = true ]; then 
            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu-full -o /tmp/${project}-gpu-full
            build_image3 "${project}" "gpu" 
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu-full -o /tmp/${project}-gpu-full
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"
        fi
        if [ "$cpu_only" = false ] && [ "$gpu_only" = false ]; then 
            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu-full -o /tmp/${project}-cpu-full
            build_image3 "${project}" "cpu"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-cpu-full -o /tmp/${project}-cpu-full
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"

            TIMESTAMP=$(date +%s) 
            echo "start, $TIMESTAMP" | tee -a "$log_file"
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu-full -o /tmp/${project}-gpu-full
            build_image3 "${project}" "gpu" 
            curl http://192.168.143.41:9081/repository/storage/taskc/${project}-gpu-full -o /tmp/${project}-gpu-full
            TIMESTAMP=$(date +%s) 
            echo "end, $TIMESTAMP" | tee -a "$log_file"
        fi
    fi
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

# build_YOLOv5() {  
#     buildImage "YOLOv5"
# }  

# build_YOLOv8() {  
#     buildImage "YOLOv8"
# }  

# build_mmpretrain() {  
#     buildImage "mmpretrain" 
# }  


clean_logfile () {
    < $log_file
    rm -rf $error_dir
    mkdir -p $error_dir
}

clean_taskc() {
    taskc purge 
}

if [ $# -eq 0 ]; then  
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
    echo "${GREEN}所有项目构建完成${NC}"  
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
            clean_taskc
            ;;
        *)  
            echo "${RED}错误: 未知的项目 '$arg'${NC}"  
            echo "可用的项目列表: CLIP, LoRA, SAM2, Stable-Baselines3, Transformers, Whisper, YOLO11, TTS, stablediffusion"  
            usage  
            ;;  
    esac  
done  

