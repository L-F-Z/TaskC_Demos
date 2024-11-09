FROM pytorch/pytorch:1.12.1-cuda11.3-cudnn8-devel

# Modify /etc/apt/sources.list to use PkgCache
RUN total_lines=$(wc -l < /etc/apt/sources.list) && lines_to_keep=$((total_lines - 6)) && head -n $lines_to_keep /etc/apt/sources.list > /etc/apt/sources.list.new
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://192.168.143.41:9081/repository/ubuntu/|g' /etc/apt/sources.list.new
RUN mv /etc/apt/sources.list.new /etc/apt/sources.list

RUN apt update && apt install --yes ffmpeg libsm6 libxext6 curl
# Create conda environment
# RUN git clone https://github.com/Stability-AI/stablediffusion.git

WORKDIR /workspace/stablediffusion/

# Overwrite the environment.yaml file
COPY ./stablediffusion .
# COPY ./resource/environment.yaml .
COPY ./resource/txt2img.py ./scripts/txt2img.py
COPY ./resource/v2-inference-v.yaml ./stablediffusion/configs/stable-diffusion/v2-inference-v.yaml
# ADD http://192.168.143.41:9081/repository/storage/v2-1_768-ema-pruned.ckpt .

RUN touch /root/.condarc
COPY ./resource/.condarc /root/.condarc

# RUN conda config --set ssl_verify false && \
RUN conda config --add channels defaults && \
    conda config --set show_channel_urls true && \
    conda config --set channel_priority false && \
    conda config --set remote_read_timeout_secs 1000
    # conda config --add default_channels http://192.168.143.41:9081/repository/conda/main && \
    # conda config --add default_channels http://192.168.143.41:9081/repository/conda/r && \
    # conda config --add default_channels http://192.168.143.41:9081/repository/conda/msys2 && \
    # conda config --add custom_channels.conda-forge http://192.168.143.41:9081/repository/conda-custom/ && \
    # conda config --add custom_channels.nvidia http://192.168.143.41:9081/repository/conda-custom/ && \
    # conda config --add custom_channels.pytorch http://192.168.143.41:9081/repository/conda-custom/

    # conda config --add default_channels https://mirrors.ustc.edu.cn/anaconda/pkgs/main && \
    # conda config --add default_channels https://mirrors.ustc.edu.cn/anaconda/pkgs/r && \
    # conda config --add default_channels https://mirrors.ustc.edu.cn/anaconda/pkgs/msys2
    # conda config --add custom_channels.conda-forge https://mirrors.ustc.edu.cn/anaconda/cloud && \
    # conda config --add custom_channels.pytorch https://mirrors.ustc.edu.cn/anaconda/cloud

# RUN conda update -n base -c defaults conda -y
RUN conda env create -f environment.yaml --verbose 
# RUN conda create -n ldm python=3.9 -y

# RUN conda install -v -c conda-forge -c nvidia -c pytorch -c defaults \
#     cudatoolkit=11.3 \
#     pytorch=1.12.1 \
#     torchvision=0.13.1 \
#     numpy=1.23.1 \
#     pip -y

# RUN mkdir -p /root/.pip/ && \
#     if [ -f /root/.pip/pip.conf ]; then mv /root/.pip/pip.conf /root/.pip/pip.conf.bak; fi  
# COPY ./resource/pip.conf /root/.pip/pip.conf

RUN pip config set global.timeout 1000
RUN pip config set global.trusted-host 192.168.143.41
RUN pip config set global.index http://192.168.143.41:9081/repository/pypi/pypi
RUN pip config set global.index-url http://192.168.143.41:9081/repository/pypi/simple


RUN pip install -v --no-cache albumentations==1.3.0 \
        opencv-python==4.6.0.66 \
        imageio==2.9.0 \
        imageio-ffmpeg==0.4.2 \
        pytorch-lightning==1.4.2 \
        omegaconf==2.1.1 \
        "test-tube>=0.7.5" \
        streamlit==1.12.1 \
        einops==0.3.0 \
        transformers==4.19.2 \
        webdataset==0.2.5 \
        kornia==0.6 \
        open_clip_torch==2.0.2 \
        "invisible-watermark>=0.1.5" \
        streamlit-drawable-canvas==0.8.0 \
        torchmetrics==0.6.0 

RUN pip install --no-cache -v -e .

# Make RUN commands use the new environment:
SHELL ["conda", "run", "-n", "ldm", "/bin/bash", "-c"]

# Install xformers for memory efficient flash attention
# RUN conda install xformers -c xformers/label/dev

RUN conda init bash
RUN echo "conda activate ldm" >> $HOME/.bashrc

CMD ["conda", "run", "-n", "ldm", "python", "scripts/txt2img.py", "--prompt", "a professional photograph of an astronaut riding a horse", "--ckpt", "v2-1_768-ema-pruned.ckpt", "--config", "configs/stable-diffusion/v2-inference-v.yaml", "--H", "768", "--W", "768", "--device", "cuda", "--outdir", "test/txt2img-samples"]