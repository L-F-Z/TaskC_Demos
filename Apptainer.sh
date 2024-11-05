#!/bin/bash  

# define colors  
RED=$'\033[0;31m'  
GREEN=$'\033[0;32m'  
YELLOW=$'\033[1;33m'  
BLUE=$'\033[0;34m'  
NC=$'\033[0m'

usage() {  
    echo "用法: bash $0 [proj1 proj2 ... | all]"  
    echo "  --no-cache   每次构建时清除缓存"  
    echo "  --cpu        仅构建 CPU 版本的镜像"  
    echo "  --gpu        仅构建 GPU 版本的镜像" 
    echo "  proj: 构建指定的项目，例如 ${BLUE}bash buildApptainer_noCache.sh CLIP${NC}"  
    echo "  all : 构建所有项目，例如 ${BLUE}bash buildApptainer_noCache.sh all${NC}"  
    echo "  支持同时构建多个项目，例如 ${BLUE}bash buildApptainer_noCache.sh CLIP YOLOv5${NC}"
    echo "  cleanlog: 清空日志和报错信息文件"
    echo "  cleanbuild: 清空所有apptainer镜像和缓存"
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

error_dir="$project_base_dir/error_logs"
mkdir -p ${error_dir}
log_file="logApptainer.log"

clean_cache_if_needed() {  
    if [ "$use_cache" = false ]; then  
        clean_apptainer 
    fi  
} 

build_image() {
    clean_cache_if_needed
    attempt=1  

    local project=$1  
    local def_file=$2   # "Apptainer.def"
    local output_sif="/tmp/${project,,}.sif"
    local project_dir="${project_base_dir}/${project}" 
    local error_logfile="apptainer_${project,,}_error.log"

    if [ ! -d "$project_dir" ]; then  
        echo "${RED}错误: 项目目录不存在: $project_dir${NC}"  
        return 1  
    fi  
    cd "$project_dir" || { echo "${RED}错误: 无法进入项目目录: $project_dir${NC}"; return 1; }  

    echo "正在构建 ${project,,} 镜像..." 
    while [ $attempt -le $max_attempts ]; do
        if [ "$use_cache" = false ]; then
            { time apptainer build --no-https --disable-cache "$output_sif" "$def_file" > output.log; } 2> time_output.log
        else
            { time apptainer build --no-https "$output_sif" "$def_file" > output.log; } 2> time_output.log
        fi

        build_status=$? 
        build_time=$(grep '^real' time_output.log | awk '{print $2}')  

        if [ $build_status -eq 0 ]; then  
             if [ -f "$output_sif" ]; then
                image_size=$(stat -c%s "$output_sif")
                # image_size_mb=$(echo "scale=2; $image_size/1024/1024" | bc)
                echo "${project,,}, ${build_time}, ${image_size}" | tee -a "../$log_file"
                echo "${GREEN}${project,,}.sif 构建完成${NC}"
            else
                echo "SIF file not found for ${project}-${variant}"
            fi
            rm time_output.log
            rm output.log
            break
        else
            echo "${RED}构建 ${project,,}.sif 失败，尝试次数: $attempt${NC}"  
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
}

build_image2() {
    clean_cache_if_needed
    attempt=1  

    local project=$1  
    local variant=$2      # "cpu" or "gpu"
    local def_file=$3     # "cpuApptainer.def" or "gpuApptainer.def"
    local output_sif="/tmp/${project,,}_${variant}.sif"
    local project_dir="${project_base_dir}/${project}"  
    local error_logfile="apptainer_${project,,}_${variant}_error.log"

    if [ ! -d "${project_dir}" ]; then  
        echo "${RED}}错误: 项目目录不存在: ${project_dir}${NC}"  
        return 1  
    fi  
    cd "${project_dir}" || { echo "${RED}错误: 无法进入项目目录: ${project_dir}${NC}"; return 1; }  
    
    echo "正在构建 ${project,,}-${variant} 镜像..."  
    while [ $attempt -le $max_attempts ]; do  
        if [ "$use_cache" = false ]; then
            { time apptainer build --no-https --disable-cache "$output_sif" "$def_file" > output.log; } 2> time_output.log
        else
            { time apptainer build --no-https "$output_sif" "$def_file" > output.log; } 2> time_output.log
        fi
        build_status=$?  
        build_time=$(grep '^real' time_output.log | awk '{print $2}')  

        if [ $build_status -eq 0 ]; then  
            if [ -f "$output_sif" ]; then
                image_size=$(stat -c%s "$output_sif")
                # image_size_mb=$(echo "scale=2; $image_size/1024/1024" | bc)
                echo "${project,,}-${variant}, ${build_time}, ${image_size}" | tee -a "../$log_file"
                echo "${GREEN}${project,,}_${variant}.sif 构建完成${NC}"
            else
                echo "SIF file not found for ${project,,}-${variant}"
            fi
            rm time_output.log
            rm output.log
            break
        else  
            echo "${RED}构建 ${project,,}_${variant}.sif 失败，尝试次数: $attempt${NC}" 
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
} 

buildImage2() {
    local project=$1
    if [ "$cpu_only" = true ]; then  
        build_image2 "${project}" "cpu" "cpuApptainer.def"  
    fi  
    if [ "$gpu_only" = true ]; then  
        build_image2 "${project}" "gpu" "gpuApptainer.def"  
    fi 
    if ["$cpu_only" = false && "$gpu_only" = false ]; then
        build_image2 "${project}" "cpu" "cpuApptainer.def"  
        build_image2 "${project}" "gpu" "gpuApptainer.def"
    fi
}

buildImage() {
    local project=$1
    build_image "${project}" "Apptainer.def"
}

build_CLIP() {  
    buildImage "CLIP" "Apptainer.def"
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
    rm $log_file > /dev/null 2>&1
    rm -rf $error_dir > /dev/null 2>&1
    mkdir -p $error_dir
}

clean_apptainer() {
    rm -rf /tmp/*
    apptainer cache clean -f > /dev/null 2>&1
    sleep 1
}

if [ ${#project_args[@]} -eq 0 ]; then  
    usage  
fi 

if [[ " ${project_args[*]} " == *" all "* ]]; then
    clean_logfile
    echo "开始构建所有项目..."  
    build_CLIP  
    # build_Deep_Live_Cam  
    build_LoRA  
    build_SAM2  
    build_Stable-Baselines3  
    build_stablediffusion  
    build_TTS
    build_Transformers  
    build_Whisper  
    build_YOLO11  
    # build_YOLOv5  
    # build_YOLOv8  
    # build_mmpretrain  
    echo "${GREEN}所有项目构建完成。${NC}"  
    exit 0  
fi  

for arg in "${project_args[@]}"; do 
    case "$arg" in  
        CLIP)  
            build_CLIP  
            ;;  
        # Deep_Live_Cam)  
        #     build_Deep_Live_Cam  
        #     ;;  
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
        # YOLOv5)  
        #     build_YOLOv5  
        #     ;;  
        # YOLOv8)  
        #     build_YOLOv8  
        #     ;;  
        # mmpretrain)  
        #     build_mmpretrain  
        #     ;;  
        stablediffusion)  
            build_stablediffusion  
            ;;
        cleanlog)
            clean_logfile
            ;;
        cleanbuild)
            clean_apptainer
            ;;
        *)  
            echo "${RED}错误: 未知的项目 '$arg'${NC}"  
            echo "可用的项目列表: CLIP, LoRA, SAM2, Stable-Baselines3, Transformers, Whisper, YOLO11, TTS, stablediffusion"  
            usage  
            ;;  
    esac  
done  

