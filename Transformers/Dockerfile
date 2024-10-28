# Use an official Python runtime as a parent image
FROM nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04

# Set the working directory in the container
WORKDIR /app

RUN total_lines=$(wc -l < /etc/apt/sources.list) && lines_to_keep=$((total_lines - 6)) && head -n $lines_to_keep /etc/apt/sources.list > /etc/apt/sources.list.new
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://192.168.2.25:9081/repository/ubuntu/|g' /etc/apt/sources.list.new
RUN mv /etc/apt/sources.list.new /etc/apt/sources.list
   
# Install git and other dependencies
RUN apt-get update && apt-get install -y \
    curl \
    pip \
    && rm -rf /var/lib/apt/lists/*

# Copy the cloned transformers repository into the container
COPY ./transformers /app/transformers
COPY ./detectron2 /app/detectron2

RUN mkdir ~/.pip/; test -f ~/.pip/pip.conf && \
    mv ~/.pip/pip.conf ~/.pip/pip.conf.bak; curl -s -o ~/.pip/pip.conf -m 3 http://192.168.2.25:4000/root/staging/raw/branch/main/pip.conf

# # Install the Transformers library in editable mode and other dependencies
# RUN pip install --no-cache-dir -e /app/transformers \
#     torch torchvision timm
RUN pip install --no-cache-dir -e /app/transformers \
    torch==2.4.0 \
    torchvision \
    torchaudio \
    pytesseract \
    "itsdangerous<2.1.0"

# git clone https://github.com/facebookresearch/detectron2.git
RUN cd /app/detectron2 && pip install -e .
RUN cd /app/transformers && python3 setup.py develop

CMD [ "/bin/bash" ]