# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

RUN total_lines=$(wc -l < /etc/apt/sources.list.d/debian.sources) && \
    lines_to_keep=$((total_lines - 6)) && \
    head -n $lines_to_keep /etc/apt/sources.list.d/debian.sources > /etc/apt/sources.list.d/debian.sources.new; sed -i 's|http://deb.debian.org/debian|http://192.168.2.25:9081/repository/debian/|g' /etc/apt/sources.list.d/debian.sources.new; mv /etc/apt/sources.list.d/debian.sources.new /etc/apt/sources.list.d/debian.sources

# Install git and other dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy the cloned transformers repository into the container
COPY ./transformers /app/transformers

RUN mkdir ~/.pip/; test -f ~/.pip/pip.conf && \
    mv ~/.pip/pip.conf ~/.pip/pip.conf.bak; curl -s -o ~/.pip/pip.conf -m 3 http://192.168.2.25:4000/root/staging/raw/branch/main/pip.conf

# Install the Transformers library in editable mode and other dependencies
RUN pip install --no-cache-dir -e /app/transformers \
    torch torchvision timm


CMD [ "/bin/bash" ]