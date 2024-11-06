#!/bin/bash
source="192.168.143.41:10082"
sourceA="oras://192.168.143.41:5000"

docker=false
apptainer=false
buildah=false
taskc=false

usage() {  
    echo "Usage: $0 [-d] [-a] [-b] [-t] [project1 project2 ...]" 1>&2  
    echo "  -d: Use docker to push images"  
    echo "  -a: Use apptainer to push images"  
    echo "  -b: Use buildah to push images"  
    echo "  -tc: Use taskc to push cpu images"
    echo "  -tg: Use taskc to push gpu images"
    echo "  -tfc: Use taskc to push full cpu images"
    echo "  -tfg: Use taskc to push full gpu images"
    echo "  project1, project2, ...: Specify the projects to push"  
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
    log_file="logPush_docker.log"
    error_log="push_docker.log"
fi
if [ "$buildah" = true ]; then
    log_file="logPush_buildah.log"
    error_log="push_buildah.log"
fi
if [ "$apptainer" = true ]; then
    log_file="logPush_apptainer.log"
    error_log="push_apptainer.log"
fi
if [ "$taskc_cpu" = true ]; then
    log_file="logPush_taskc_cpu.log"
    error_log="push_taskc_cpu.log"
fi
if [ "$taskc_gpu" = true ]; then
    log_file="logPush_taskc_gpu.log"
    error_log="push_taskc_gpu.log"
fi
if [ "$taskc_full_cpu" = true ]; then
    log_file="logPush_taskc_full_cpu.log"
    error_log="push_taskc_full_cpu.log"
fi
if [ "$taskc_full_gpu" = true ]; then
    log_file="logPush_taskc_full_gpu.log"
    error_log="push_taskc_full_gpu.log"
fi

tagAll() {
    tag "yolo11-gpu"
    tag "yolo11-cpu"
    tag "whisper"
    tag "tts"
    tag "transformers-gpu"
    tag "transformers-cpu"
    tag "stablediffusion"
    tag "stable-baselines3-gpu"
    tag "stable-baselines3-cpu"
    tag "sam2"
    tag "lora-gpu"
    tag "lora-cpu"
    tag "clip"
}

tag() {
    local imgName=$1
    
    if [ "$docker" = true ]; then
        docker tag ${imgName}:latest ${source}/${imgName}:latest
    fi
    if [ "$buildah" = true ]; then
        buildah tag ${imgName}:latest ${source}/${imgName}:latest
    fi
}



push() {
    local imgName=$1
    local version=$2
    
    if [ "$docker" = true ]; then
        if [ "$version" = "gpu" ]; then
            pushDocker "${imgName}-gpu"
        fi
        if [ "$version" = "cpu" ]; then
            pushDocker "${imgName}-cpu"
        fi
        if [ "$version" = "any" ]; then
            pushDocker "${imgName}"
        fi
    fi

    if [ "$buildah" = true ]; then
        if [ "$version" = "gpu" ]; then
            pushBuildah "${imgName}-gpu"
        fi
        if [ "$version" = "cpu" ]; then
            pushBuildah "${imgName}-cpu"
        fi
        if [ "$version" = "any" ]; then
            pushBuildah "${imgName}"
        fi
    fi

    if [ "$apptainer" = true ]; then
        if [ "$version" = "gpu" ]; then
            pushApptainer "${imgName}-gpu"
        fi
        if [ "$version" = "cpu" ]; then
            pushApptainer "${imgName}-cpu"
        fi
        if [ "$version" = "any" ]; then
            pushApptainer "${imgName}"
        fi
    fi

    if [ "$taskc_cpu" = true ]; then
        pushTaskc "${imgName}" "cpu"
    fi

    if [ "$taskc_gpu" = true ]; then
        pushTaskc "${imgName}" "gpu"
    fi

    if [ "$taskc_full_cpu" = true ]; then
        if [ "$version" = "any" ]; then
            pushTaskc "${imgName}" "cpu-full"
        fi
        if [ "$version" = "cpu" ]; then
            pushTaskc "${imgName}" "cpu-full"
        fi
    fi

    if [ "$taskc_full_gpu" = true ]; then
        if [ "$version" = "any" ]; then
            pushTaskc "${imgName}" "gpu-full"
        fi
        if [ "$version" = "gpu" ]; then
            pushTaskc "${imgName}" "gpu-full"
        fi
    fi
    
}

pushDocker() {
    local imgName=$1
    time docker push ${source}/${imgName}:latest > pushtmp.log
    push_time=$(grep '^real' pushtmp.log | awk '{print $2}')   
    echo "${imgName}, ${push_time}" >> $log_file
    rm pushtmp.log
}

pushBuildah() {
    local imgName=$1
    time buildah push ${source}/${imgName}:latest > pushtmp.log
    push_time=$(grep '^real' pushtmp.log | awk '{print $2}')
    echo "${imgName}, ${push_time}" >> $log_file
    rm pushtmp.log
}

pushApptainer() {
    local imgName=$1
    time apptainer push /tmp/${imgName}.sif ${sourceA}/${imgName}:latest > pushtmp.log
    push_time=$(grep '^real' pushtmp.log | awk '{print $2}')
    echo "${imgName}, ${push_time}" >> $log_file
    rm pushtmp.log
}

pushTaskc() {
    local imgName=$1
    local version=$2

    # tar locally
    time taskc save ${imgName}-${version} /tmp/ > pushtmp.log
    save_time=$(grep '^real' pushtmp.log | awk '{print $2}')
    rm pushtmp.log

    # push to remote
    time curl -v -u admin:12345678 --upload-file /tmp/${imgName}-${version}.taskc http://192.168.143.41:9081/repository/storage/taskc/${imgName}-${version}.taskc
    push_time=$(grep '^real' pushtmp.log | awk '{print $2}')
    rm pushtmp.log

    all_time=$(echo "${save_time}" + "${push_time}" | bc)
    echo "${imgName}, ${all_time}, ${save_time}, ${push_time}" >> $log_file
    
}

clean_logfile() {
    if [ -f $log_file ]; then
        rm $log_file
    fi
    if [ -f pushtmp.log ]; then
        rm pushtmp.log
    fi
    rm ${error_dir}/push_*
}



pushYOLO11() {
    echo "Pushing yolo11 gpu images..."
    push "yolo11" "gpu"
    echo "Pushing yolo11 cpu images..."
    push "yolo11" "cpu"
}

pushWhisper() {
    echo "Pushing whisper images..."
    push "whisper" "any"
}

pushTTS() {
    echo "Pushing tts images..."
    push "tts" "any"
}

pushTransformers() {
    echo "Pushing transformers gpu images..."
    push "transformers" "gpu"
    echo "Pushing transformers cpu images..."
    push "transformers" "cpu"
}

pushStablediffusion() {
    echo "Pushing stablediffusion images..."
    push "stablediffusion" "any"
}

pushStableBaselines3() {
    echo "Pushing stable-baselines3 gpu images..."
    push "stable-baselines3" "gpu"
    echo "Pushing stable-baselines3 cpu images..."
    push "stable-baselines3" "cpu"
}

pushSAM2() {
    echo "Pushing sam2 images..."
    push "sam2" "any"
}

pushLoRA() {
    echo "Pushing lora gpu images..."
    push "lora" "gpu"
    echo "Pushing lora cpu images..."
    push "lora" "cpu"
}

pushCLIP() {
    echo "Pushing clip images..."
    push "clip" "any"
}

pushAll() {
    pushYOLO11
    pushWhisper
    pushTTS
    pushTransformers
    pushStablediffusion
    pushStableBaselines3
    pushSAM2
    pushLoRA
    pushCLIP
}

if [[ " ${project_args[*]} " == *" pushall "* ]]; then
    clean_logfile
    echo "Pushing all images..."  
    pushAll
    echo "${GREEN}Push done${NC}"  
    exit 0  
fi  

if [[ " ${project_args[*]} " == *" tagall "* ]]; then
    clean_logfile
    echo "开始 tag 所有项目..."  
    tagAll
    echo "${GREEN}tag 结束${NC}"  
    exit 0  
fi  

for arg in "${project_args[@]}"; do 
    case "$arg" in  
        YOLO11)  
            pushYOLO11
            ;;  
        Whisper)  
            pushWhisper
            ;;  
        TTS)
            pushTTS
            ;;
        Transformers)  
            pushTransformers
            ;;  
        stablediffusion)  
            pushStablediffusion
            ;;  
        Stable-Baselines3)  
            pushStableBaselines3
            ;;  
        SAM2)  
            pushSAM2
            ;;  
        LoRA)  
            pushLoRA
            ;;  
        CLIP)  
            pushCLIP
            ;;  
        *)  
            echo "${RED}错误: 未知项目: $arg${NC}"  
            ;;  
    esac
done