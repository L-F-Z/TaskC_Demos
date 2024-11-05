FROM pytorch/pytorch:2.3.1-cuda12.1-cudnn8-runtime

# SAM 2 environment variables
ENV APP_ROOT=/app/sam2

ENV DEBIAN_FRONTEND=noninteractive
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN total_lines=$(wc -l < /etc/apt/sources.list) && lines_to_keep=$((total_lines - 6)) && head -n $lines_to_keep /etc/apt/sources.list > /etc/apt/sources.list.new
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://192.168.143.41:9081/repository/ubuntu/|g' /etc/apt/sources.list.new
RUN mv /etc/apt/sources.list.new /etc/apt/sources.list

# Install system requirements
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libavutil-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    pkg-config \
    build-essential \
    libffi-dev

RUN mkdir -p ${APP_ROOT}
COPY ./sam2/ ${APP_ROOT}/

# Modify ~/.pip/pip.conf to use PkgCache
# RUN mkdir ~/.pip/; test -f ~/.pip/pip.conf && mv ~/.pip/pip.conf ~/.pip/pip.conf.bak; curl -s -o ~/.pip/pip.conf -m 3 https://raw.githubusercontent.com/brandnewworld/staging/refs/heads/main/pip.conf
RUN mkdir -p /root/.pip/ && \
    if [ -f /root/.pip/pip.conf ]; then mv /root/.pip/pip.conf /root/.pip/pip.conf.bak; fi  
COPY ./resource/pip.conf /root/.pip/pip.conf  

RUN cd ${APP_ROOT} && \
    pip install --upgrade pip setuptools && \
    pip install -e ".[interactive-demo]" && \
    pip install opencv-python 

# https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite/issues/69#issuecomment-1826764707
RUN rm /opt/conda/bin/ffmpeg && ln -s /bin/ffmpeg /opt/conda/bin/ffmpeg

# Download SAM 2.1 checkpoints
ADD http://192.168.143.41:9081/repository/storage/sam2.1_hiera_tiny.pt ${APP_ROOT}/checkpoints/sam2.1_hiera_tiny.pt
ADD http://192.168.143.41:9081/repository/storage/sam2.1_hiera_small.pt ${APP_ROOT}/checkpoints/sam2.1_hiera_small.pt
ADD http://192.168.143.41:9081/repository/storage/sam2.1_hiera_base_plus.pt ${APP_ROOT}/checkpoints/sam2.1_hiera_base_plus.pt
ADD http://192.168.143.41:9081/repository/storage/sam2.1_hiera_large.pt ${APP_ROOT}/checkpoints/sam2.1_hiera_large.pt


STOPSIGNAL SIGTERM
CMD ["/bin/bash"]