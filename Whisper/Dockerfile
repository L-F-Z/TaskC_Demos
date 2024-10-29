FROM python:3.10-slim

# Set working directory
WORKDIR /app

COPY ./whisper /app/whisper

RUN total_lines=$(wc -l < /etc/apt/sources.list.d/debian.sources) && lines_to_keep=$((total_lines - 6)) && head -n $lines_to_keep /etc/apt/sources.list.d/debian.sources > /etc/apt/sources.list.d/debian.sources.new; sed -i 's|http://deb.debian.org/debian|http://192.168.2.25:9081/repository/debian/|g' /etc/apt/sources.list.d/debian.sources.new; mv /etc/apt/sources.list.d/debian.sources.new /etc/apt/sources.list.d/debian.sources
# 添加 APT 配置以忽略 Valid-Until  
# RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99ignore-valid-until  

RUN apt-get update 
RUN apt-get install -y ffmpeg

# RUN mkdir ~/.pip/; test -f ~/.pip/pip.conf && mv ~/.pip/pip.conf ~/.pip/pip.conf.bak; curl -s -o ~/.pip/pip.conf -m 3 http://192.168.2.25:4000/root/staging/raw/branch/main/pip.conf
RUN mkdir -p /root/.pip/ && \
    if [ -f /root/.pip/pip.conf ]; then mv /root/.pip/pip.conf /root/.pip/pip.conf.bak; fi  
COPY ./resource/pip.conf /root/.pip/pip.conf  

RUN cd /app/whisper && \
    pip install --no-cache-dir .
# RUN pip install -r /app/whisper/requirements.txt

RUN whisper --model_dir /usr/local --model medium audio >> /dev/null 2>&1; exit 0

WORKDIR /app
