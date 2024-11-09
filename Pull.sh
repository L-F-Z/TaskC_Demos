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

# log file name
if [ "$docker" = true ]; then
    log_file="logPull_docker.log"
    error_log="pull_docker.log"
fi
if [ "$buildah" = true ]; then
    log_file="logPull_buildah.log"
    error_log="pull_buildah.log"
fi
if [ "$apptainer" = true ]; then
    log_file="logPull_apptainer.log"
    error_log="pull_apptainer.log"
fi
if [ "$taskc_cpu" = true ]; then
    log_file="logPull_taskc_cpu.log"
    error_log="pull_taskc_cpu.log"
fi
if [ "$taskc_gpu" = true ]; then
    log_file="logPull_taskc_gpu.log"
    error_log="pull_taskc_gpu.log"
fi
if [ "$taskc_full_cpu" = true ]; then
    log_file="logPull_taskc_full_cpu.log"
    error_log="pull_taskc_full_cpu.log"
fi
if [ "$taskc_full_gpu" = true ]; then
    log_file="logPull_taskc_full_gpu.log"
    error_log="pull_taskc_full_gpu.log"
fi



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

    if [ "$taskc_cpu" = true ]; then
        pullTaskc "${imgName}" "cpu"
    fi

    if [ "$taskc_gpu" = true ]; then
        pullTaskc "${imgName}" "gpu"
    fi

    if [ "$taskc_full_cpu" = true ]; then
        pullTaskc "${imgName}" "cpu-full"
    fi

    if [ "$taskc_full_gpu" = true ]; then
        pullTaskc "${imgName}" "gpu-full"
    fi
}

pullDocker() {
    local imgName=$1
    time docker pull ${source}/${imgName}:latest > pulltmp.log
    pull_time=$(grep '^real' pulltmp.log | awk '{print $2}') 
    echo "${imgName}, ${pull_time}" >> ${log_file}
    rm pulltmp.log
}

pullBuildah() {
    local imgName=$1
    time buildah pull ${sourceA}/${imgName}:latest > pulltmp.log
    pull_time=$(grep '^real' pulltmp.log | awk '{print $2}') 
    echo "${imgName}, ${pull_time}" >> ${log_file}
    rm pulltmp.log
}

pullApptainer() {
    local imgName=$1
    time apptainer pull /tmp/${imgName}.sif ${sourceA}/${imgName}:latest > pulltmp.log
    pull_time=$(grep '^real' pulltmp.log | awk '{print $2}') 
    echo "${imgName}, ${pull_time}" >> ${log_file}
    rm pulltmp.log
}

pullTaskc() {
    local imgName=$1
    local version=$2
    # get from remote
    time curl http://192.168.143.41:9081/repository/storage/taskc/${imgName}-${version}.taskc -o /tmp/${imgName}-${version}.taskc > pulltmp.log
    pull_time=$(grep '^real' pulltmp.log | awk '{print $2}')
    rm pulltmp.log

    # load locally
    time taskc load /tmp/${imgName}-${version}.taskc --id ${imgName}-${version} > pulltmp.log
    load_time=$(grep '^real' pulltmp.log | awk '{print $2}')
    rm pulltmp.log

    all_time=$( echo "${pull_time}" + "${load_time}" | bc )
    echo "${imgName}, ${all_time}, ${pull_time}, ${load_time}" >> ${log_file}
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
    pull "yolo11" "gpu"
    pull "yolo11" "cpu"
}

pullWhisper() {
    pull "whisper" "any"
}

pullTransformers() {
    pull "transformers" "gpu"
    pull "transformers" "cpu"
}

pullTTS() {
    pull "tts" "any"
}

pullStableDiffusion() {
    pull "stablediffusion" "any"
}

pullStableBaselines3() {
    pull "stable-baselines3" "gpu"
    pull "stable-baselines3" "cpu"
}

pullSAM2() {
    pull "sam2" "any"
}

pullLoRA() {
    pull "lora" "gpu"
    pull "lora" "cpu"
}

pullCLIP() {
    pull "clip" "any"
}

pullAll() {
    pullYolo11
    pullWhisper
    pullTTS
    pullTransformers
    pullStableDiffusion
    pullStableBaselines3
    pullSAM2
    pullLoRA
    pullCLIP
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
        stableDiffusion)
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
