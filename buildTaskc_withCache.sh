#!/bin/bash  

# define colors  
RED=$'\033[0;31m'  
GREEN=$'\033[0;32m'  
YELLOW=$'\033[1;33m'  
BLUE=$'\033[0;34m'  
NC=$'\033[0m'
                
usage() {  
    echo "用法: bash $0 [proj1 proj2 ... | all]"  
    echo "  proj: 构建指定的项目，例如 ${BLUE}bash buildDocker_noCache.sh CLIP${NC}"  
    echo "  all : 构建所有项目，例如 ${BLUE}bash buildDocker_noCache.sh all${NC}"  
    echo "  支持同时构建多个项目，例如 ${BLUE}bash buildDocker_noCache.sh CLIP YOLOv5${NC}"
    echo "  cleanlog: 清空日志和报错信息文件"
    echo "  cleanbuild: 清空所有docker镜像、容器和缓存"
    exit 1  
}  

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  
project_base_dir="${script_dir}"  

mkdir -p $project_base_dir/error_logs
log_file="logTaskc_withCache.log"  

max_attempts=3

build_image() {
    attempt=1  

    local project=$1
    local version=$2
    local buildfile="${project}.blueprint"
    local project_dir="${project_base_dir}/${project}" 

    if [ ! -d "$project_dir" ]; then  
        echo "${RED}错误: 项目目录不存在: $project_dir${NC}"  
        return 1  
    fi  
    cd "$project_dir" || { echo "${RED}错误: 无法进入项目目录: $project_dir${NC}"; return 1; }  

    echo "正在构建 ${project,,} ${version} Taskc Image..." 
    while [ $attempt -le $max_attempts ]; do
        if [ "$version" == "cpu" ]; then
            { time taskc asm --ignore-gpu "$buildfile" > output.log; } 2> time_output.log
        else
            { time taskc asm "$buildfile" > output.log; } 2> time_output.log
        fi
        build_status=$? 
        build_time=$(grep '^real' time_output.log | awk '{print $2}')  

        if [ $build_status -eq 0 ]; then  
            image_size=$(du -sb /var/lib/taskc/Image/${project}-latest | awk '{print $1}')
            # image_size_mb=$(echo "scale=2; $image_size/1024/1024" | bc)
            echo "${project,,}-${version}, ${build_time}, ${image_size}" | tee -a "../$log_file"
            echo "${GREEN}${project,,} Taskc Image 构建完成${NC}"
            rm time_output.log
            rm output.log
            break
        else
            echo "${RED}构建 ${project,,} Taskc Image 失败，尝试次数: $attempt${NC}"  
            echo -e "错误信息：\n$(<time_output.log)\n\n$(<output.log)\n" >> "$project_base_dir/error_logs/taskc_${project,,}_error.log"
            if [ $attempt -lt $max_attempts ]; then  
                clean_taskc
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
    attempt=1  

    local project=$1  
    local buildfile="${project}.blueprint"
    local project_dir="${project_base_dir}/${project}" 

    if [ ! -d "$project_dir" ]; then  
        echo "${RED}错误: 项目目录不存在: $project_dir${NC}"  
        return 1  
    fi  
    cd "$project_dir" || { echo "${RED}错误: 无法进入项目目录: $project_dir${NC}"; return 1; }  

    echo "正在构建 ${project,,} ${version} 镜像..." 
    while [ $attempt -le $max_attempts ]; do
        { time taskc asm "$buildfile" >output.log; } 2> time_output.log
        build_status=$? 
        build_time=$(grep '^real' time_output.log | awk '{print $2}')  

        if [ $build_status -eq 0 ]; then  
            image_size=$(du -sb /var/lib/taskc/Image/${project}-latest | awk '{print $1}')
            # image_size_mb=$(echo "scale=2; $image_size/1024/1024" | bc)
            echo "${project,,}, ${build_time}, ${image_size}" | tee -a "../$log_file"
            echo "${GREEN}${project,,} Taskc Image 构建完成${NC}"
            rm time_output.log
            rm output.log
            break
        else
            echo "${RED}构建 ${project,,} Taskc Image 失败，尝试次数: $attempt${NC}"  
            echo -e "错误信息：\n$(<time_output.log)\n\n$(<output.log)\n" >> "$project_base_dir/error_logs/taskc_${project,,}_error.log"
            if [ $attempt -lt $max_attempts ]; then  
                clean_taskc
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

build_CLIP() {  
    build_image "CLIP" "cpu"
    build_image "CLIP" "gpu"
}  

# build_Deep_Live_Cam() {  
#     build_image "Deep_Live_Cam" "cpu" "cpuDockerfile"  
#     build_image "Deep_Live_Cam" "gpu" "gpuDockerfile"  
# }  

build_LoRA() {  
    build_image "LoRA" "cpu" 
    build_image "LoRA" "gpu"
}  

build_SAM2() {  
    build_image "SAM2" "cpu"
    build_image "SAM2" "gpu"
}  

build_Stable-Baselines3() { 
    build_image "Stable-Baselines3" "cpu"
    build_image "Stable-Baselines3" "gpu"
}

build_stablediffusion() {  
    build_image "stablediffusion" "cpu"
    build_image "stablediffusion" "gpu"
}  

build_TTS() {  
    build_image "TTS" "cpu"
    build_image "TTS" "gpu"
}  

build_Transformers() {  
    build_image "Transformers" "cpu"
    build_image "Transformers" "gpu"
}  

build_Whisper() {  
    build_image "Whisper" "cpu"
    build_image "Whisper" "gpu"
}  

build_YOLO11() {  
    build_image "YOLO11" "cpu"
    build_image "YOLO11" "gpu"
}  

# build_YOLOv5() {  
#     build_image "YOLOv5" "cpu" "cpuDockerfile"  
#     build_image "YOLOv5" "gpu" "gpuDockerfile"  
# }  

# build_YOLOv8() {  
#     build_image "YOLOv8" "cpu" "cpuDockerfile"  
#     build_image "YOLOv8" "gpu" "gpuDockerfile"  
# }  

# build_mmpretrain() {  
#     build_image "mmpretrain" "cpu" "cpuDockerfile"  
#     build_image "mmpretrain" "gpu" "gpuDockerfile"  
# }  

clean_logfile () {
    > "$log_file"
    rm -rf $project_base_dir/error_logs
    mkdir -p $project_base_dir/error_logs
}

clean_taskc() {
    taskc purge > /dev/null 2>&1
}

if [ $# -eq 0 ]; then  
    usage  
fi  

if [[ " $* " == *" all "* ]]; then  
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

for arg in "$@"; do  
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
            ;;  
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

