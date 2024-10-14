FROM pytorch/pytorch:1.12.1-cuda11.3-cudnn8-devel

# Modify /etc/apt/sources.list to use PkgCache
RUN total_lines=$(wc -l < /etc/apt/sources.list) && lines_to_keep=$((total_lines - 6)) && head -n $lines_to_keep /etc/apt/sources.list > /etc/apt/sources.list.new
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://192.168.2.25:9081/repository/ubuntu/|g' /etc/apt/sources.list.new
RUN mv /etc/apt/sources.list.new /etc/apt/sources.list

RUN apt update && apt install --yes ffmpeg libsm6 libxext6
# Create conda environment
# RUN git clone https://github.com/Stability-AI/stablediffusion.git

WORKDIR /workspace/stablediffusion/

# Overwrite the environment.yaml file
COPY ./stablediffusion .
COPY environment.yaml .
ADD http://192.168.2.25:9081/repository/storage/v2-1_768-ema-pruned.ckpt .

RUN mkdir ~/.conda/ && touch ~/.conda/.condarc
RUN cat <<'EOF' > ~/.conda/.condarc
default_channels:
    - http://192.168.2.25:9081/repository/conda/main
    - http://192.168.2.25:9081/repository/conda/r
    - http://192.168.2.25:9081/repository/conda/msys2
custom_channels:
    conda-forge: http://192.168.2.25:9081/repository/conda2/
    nvidia: http://192.168.2.25:9081/repository/conda2/
    pytorch: http://192.168.2.25:9081/repository/conda2/
EOF

# RUN conda config --set ssl_verify false && \
RUN conda config --add channels defaults && \
    conda config --set show_channel_urls true
    # conda config --add default_channels https://mirrors.ustc.edu.cn/anaconda/pkgs/main && \
    # conda config --add default_channels https://mirrors.ustc.edu.cn/anaconda/pkgs/r && \
    # conda config --add default_channels https://mirrors.ustc.edu.cn/anaconda/pkgs/msys2
    # conda config --add custom_channels.conda-forge https://mirrors.ustc.edu.cn/anaconda/cloud && \
    # conda config --add custom_channels.pytorch https://mirrors.ustc.edu.cn/anaconda/cloud

# RUN conda update -n base -c defaults conda -y
RUN conda env create -f environment.yaml

# Make RUN commands use the new environment:
SHELL ["conda", "run", "-n", "ldm", "/bin/bash", "-c"]

# Install xformers for memory efficient flash attention
# RUN conda install xformers -c xformers/label/dev

RUN conda init bash
RUN echo "conda activate ldm" >> $HOME/.bashrc

ENTRYPOINT ["conda", "run", "-n", "ldm", "python", "scripts/txt2img.py"]
CMD ["--prompt", "a professional photograph of an astronaut riding a horse", "--ckpt", "v2-1_768-ema-pruned.ckpt", "--config", "configs/stable-diffusion/v2-inference-v.yaml", "--H", "768", "--W", "768", "--device", "cuda", "--outdir", "test/txt2img-samples"]