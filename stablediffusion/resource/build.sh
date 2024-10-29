commit cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf (HEAD -> main, origin/main, origin/HEAD)

docker build -f cpuDockerfile -t stablediffusion:cpu .
docker run -it --rm -v ./test:/workspace/stablediffusion/test stablediffusion:cpu

docker build -f gpuDockerfile -t stablediffusion:gpu .
docker run -it --rm --gpus all -v ./test:/workspace/stablediffusion/test stablediffusion:gpu

// weight file, need predownload to current directory before build 
//wget https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.ckpt

apptainer build --no-https /tmp/sd_cpu.sif ./cpuApptainer.def
apptainer build --no-https /tmp/sd_gpu.sif ./gpuApptainer.def