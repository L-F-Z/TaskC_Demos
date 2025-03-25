#!/bin/bash
source="192.168.143.41:10082"
sourceA="oras://192.168.143.41:5000"

docker=false
apptainer=false
buildah=false
taskc=false

usage() {  
    echo "Usage: $0 [-d] [-a] [-b] [-t] [project1 project2 ...]" 1>&2  
    echo "  -d: Use docker to pull images"  
    echo "  -a: Use apptainer to pull images"  
    echo "  -b: Use buildah to pull images"  
    echo "  -tc: Use taskc to pull cpu images"
    echo "  -tg: Use taskc to pull gpu images"
    echo "  -tfc: Use taskc to pull full cpu images"
    echo "  -tfg: Use taskc to pull full gpu images"
    echo "  project1, project2, ...: Specify the projects to pull"  
    exit 1  
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  
project_base_dir="${script_dir}"

project_args=()  
for arg in "$@"; do  
    case "$arg" in  
        -d)  
            docker=true
            ;;  
        -a)  
            apptainer=true
            ;;  
        -b)  
            buildah=true
            ;;  
        --cpu)
            cpu_flag=true
            ;;
        --gpu)
            gpu_flag=true
            ;;
        -tc)
            taskc_cpu=true    
            ;;
        -tg)
            taskc_gpu=true
            ;;
        -tfc)
            taskc_full_cpu=true
            ;;
        -tfg)
            taskc_full_gpu=true
            ;;
        *)  
            project_args+=("$arg") # Collect additional arguments for projects  
            ;;  
    esac  
done 

error_dir="${project_base_dir}/error_logs"
mkdir -p ${error_dir}
log_file="logPull"
# log file name
if [ "$docker" = true ]; then
    log_file="${log_file}_docker"
    error_log="pull_docker.log"
fi
if [ "$buildah" = true ]; then
    log_file="${log_file}_buildah"
    error_log="pull_buildah.log"
fi
if [ "$apptainer" = true ]; then
    log_file="${log_file}_apptainer"
    error_log="pull_apptainer.log"
fi
if [ "$taskc_cpu" = true ]; then
    log_file="${log_file}_taskccpu"
    error_log="pull_taskc_cpu.log"
fi
if [ "$taskc_gpu" = true ]; then
    log_file="${log_file}_taskcgpu"
    error_log="pull_taskc_gpu.log"
fi
if [ "$taskc_full_cpu" = true ]; then
    log_file="${log_file}_taskcfullcpu"
    error_log="pull_taskc_full_cpu.log"
fi
if [ "$taskc_full_gpu" = true ]; then
    log_file="${log_file}_taskcfullgpu"
    error_log="pull_taskc_full_gpu.log"
fi
log_file="${log_file}.log"


pull() {
    local imgName=$1
    local version=$2

    if [ "$docker" = true ]; then
        if [ "$version" = "gpu" ]; then
            pullDocker "${imgName}-gpu"
        elif [ "$version" = "cpu" ]; then
            pullDocker "${imgName}-cpu"
        else
            pullDocker "${imgName}"
        fi
    fi

    if [ "$buildah" = true ]; then
        if [ "$version" = "gpu" ]; then
            pullBuildah "${imgName}-gpu"
        elif [ "$version" = "cpu" ]; then
            pullBuildah "${imgName}-cpu"
        else
            pullBuildah "${imgName}"
        fi
    fi

    if [ "$apptainer" = true ]; then
        if [ "$version" = "gpu" ]; then
            pullApptainer "${imgName}-gpu"
        elif [ "$version" = "cpu" ]; then
            pullApptainer "${imgName}-cpu"
        else
            pullApptainer "${imgName}"
        fi
    fi

    if [ "$taskc_cpu" = true ] && ( [ "$version" = "cpu" ] || [ "$version" = "any" ] ) ; then
        echo "${imgName} cpu"
        pullTaskc "${imgName}" "cpu"
    fi
    
    if [ "$taskc_gpu" = true ] && ( [ "$version" = "gpu" ] || [ "$version" = "any" ]) ; then
        echo "${imgName} gpu"
        pullTaskc "${imgName}" "gpu"
    fi

    if [ "$taskc_full_cpu" = true ] && ( [ "$version" = "cpu" ] || [ "$version" = "any" ]) ; then
        echo "${imgName} cpu full"
        pullTaskc "${imgName}" "cpu-full"
    fi
    
    if [ "$taskc_full_gpu" = true ] && ( [ "$version" = "gpu" ] || [ "$version" = "any" ]) ; then
        echo "${imgName} gpu-full"
        pullTaskc "${imgName}" "gpu-full"
    fi
}

convert_to_seconds() {
    local time_str="$1"
    
    # 使用正则表达式提取分钟和秒
    if [[ $time_str =~ ([0-9]+)m([0-9.]+)s ]]; then
        local minutes="${BASH_REMATCH[1]}"
        local seconds="${BASH_REMATCH[2]}"
        
        # 计算总秒数，使用 bc 进行浮点运算
        local total_seconds=$(echo "$minutes * 60 + $seconds" | bc)
        echo "$total_seconds"
    else
        echo "0"
    fi
}

format_time() {
    local total_secs="$1"
    
    # 计算分钟
    local minutes=$(echo "$total_secs / 60" | bc)
    
    # 计算剩余秒数，保留小数点后三位
    local seconds=$(echo "scale=3; $total_secs - ($minutes * 60)" | bc)
    
    echo "${minutes}m${seconds}s"
}

pullDocker() {
    local imgName=$1
    { time docker pull ${source}/${imgName}:latest > tmp.log; } 2> pulltmp.log
    pull_time=$(grep '^real' pulltmp.log | awk '{print $2}') 
    echo "${imgName}, ${pull_time}" >> ${log_file}
    # rm pulltmp.log
    # rm tmp.log
    # bash Docker.sh cleanbuild
    # sleep 1
}

pullBuildah() {
    local imgName=$1
    { time buildah pull ${source}/${imgName}:latest > tmp.log; } 2> pulltmp.log
    pull_time=$(grep '^real' pulltmp.log | awk '{print $2}') 
    echo "${imgName}, ${pull_time}" >> ${log_file}
    # rm pulltmp.log
    # bash Buildah.sh cleanbuild
    # sleep 1
}

pullApptainer() {
    local imgName=$1
    { time apptainer pull /tmp/${imgName}.sif ${sourceA}/${imgName}:t4 > tmp.log; } 2> pulltmp.log
    pull_time=$(grep '^real' pulltmp.log | awk '{print $2}') 
    echo "${imgName}, ${pull_time}" >> ${log_file}
    rm pulltmp.log
}

pullTaskc() {
    local imgName=$1
    local version=$2

    # get from remote
    { time curl http://192.168.143.41:9081/repository/storage/taskczip/${imgName}-${version}.taskc -o /tmp/${imgName}-${version}.taskc > tmp.log ; } 2> pulltmp.log
    pull_time=$(grep '^real' pulltmp.log | awk '{print $2}')
    # rm pulltmp.log
    echo -e "信息：\n$(<pulltmp.log)\n" >> "${error_dir}/${error_log}"


    # load locally
    { time taskc load /tmp/${imgName}-${version}.taskc --id ${imgName}-${version} > tmp.log ; } 2> pulltmp.log
    load_time=$(grep '^real' pulltmp.log | awk '{print $2}')
    # rm pulltmp.log
    echo -e "信息：\n$(<pulltmp.log)\n----------------------------------------------------------------\n" >> "${error_dir}/${error_log}"

    load_seconds=$(convert_to_seconds "$load_time")
    pull_seconds=$(convert_to_seconds "$pull_time")
    all_seconds=$(echo "$load_seconds + $pull_seconds" | bc)
    all_time=$(format_time "$all_seconds")

    echo "${imgName}-${version}, ${all_time}, ${pull_time}, ${load_time}" >> ${log_file}
    bash Taskc.sh cleanbuild
}

clean_logfile() {
    if [ -f $log_file ]; then
        rm $log_file
    fi
    if [ -f pulltmp.log ]; then
        rm pulltmp.log
    fi
    rm ${error_dir}/pull_*
}



pullYolo11() {
    if [ "$cpu_flag" = true ]; then
        pull "yolo11" "cpu"
    elif [ "$gpu_flag" = true ]; then
        pull "yolo11" "gpu"
    else
        pull "yolo11" "cpu"
        pull "yolo11" "gpu"
    fi
}

pullWhisper() {
    pull "whisper" "any"
}

pullTransformers() {
    if [ "$cpu_flag" = true ]; then
        pull "transformers" "cpu"
    elif [ "$gpu_flag" = true ]; then
        pull "transformers" "gpu"
    else
        pull "transformers" "cpu"
        pull "transformers" "gpu"
    fi
}

pullTTS() {
    pull "tts" "any"
}

pullStableDiffusion() {
    pull "stablediffusion" "any"
}

pullStableBaselines3() {
    if [ "$cpu_flag" = true ]; then
        pull "stable-baselines3" "cpu"
    elif [ "$gpu_flag" = true ]; then
        pull "stable-baselines3" "gpu"
    else
        pull "stable-baselines3" "cpu"
        pull "stable-baselines3" "gpu"
    fi
}

pullSAM2() {
    pull "sam2" "any"
}

pullLoRA() {
    if [ "$cpu_flag" = true ]; then
        pull "lora" "cpu"
    elif [ "$gpu_flag" = true ]; then
        pull "lora" "gpu"
    else
        pull "lora" "cpu"
        pull "lora" "gpu"
    fi
}

pullCLIP() {
    pull "clip" "any"
}

pullAll() {
    pullCLIP
    pullLoRA
    pullSAM2
    pullStableBaselines3
    pullStableDiffusion
    pullTransformers
    pullTTS
    pullWhisper
    pullYolo11
}

if [[ " ${project_args[*]} " == *" pullall "* ]]; then
    clean_logfile
    echo "Pulling all images..."
    pullAll
    echo "${GREEN}Pull done${NC}"
    exit 0
fi

for arg in "${project_args[@]}"; do 
    case "$arg" in  
        YOLO11)
            pullYolo11
            ;;
        Whisper)
            pullWhisper
            ;;
        TTS)
            pullTTS
            ;;
        Transformers)
            pullTransformers
            ;;
        stablediffusion)
            pullStableDiffusion
            ;;
        Stable-Baselines3)
            pullStableBaselines3
            ;;
        SAM2)
            pullSAM2
            ;;
        LoRA)
            pullLoRA
            ;;
        CLIP)
            pullCLIP
            ;;
        *)
            echo "${RED}Error: unknown project $arg${NC}"  
            ;;  
    esac
done
