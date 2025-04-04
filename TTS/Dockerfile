ARG BASE=nvidia/cuda:11.8.0-base-ubuntu22.04
FROM ${BASE}

# Modify /etc/apt/sources.list to use PkgCache
RUN total_lines=$(wc -l < /etc/apt/sources.list) && lines_to_keep=$((total_lines - 6)) && head -n $lines_to_keep /etc/apt/sources.list > /etc/apt/sources.list.new
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://192.168.143.41:9081/repository/ubuntu/|g' /etc/apt/sources.list.new
RUN mv /etc/apt/sources.list.new /etc/apt/sources.list

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y --no-install-recommends gcc g++ make python3 python3-dev python3-pip python3-venv python3-wheel espeak-ng libsndfile1-dev && rm -rf /var/lib/apt/lists/*

# Modify ~/.pip/pip.conf to use PkgCache
# RUN mkdir ~/.pip/; test -f ~/.pip/pip.conf && mv ~/.pip/pip.conf ~/.pip/pip.conf.bak; curl -s -o ~/.pip/pip.conf -m 3 https://raw.githubusercontent.com/brandnewworld/staging/refs/heads/main/pip.conf
RUN mkdir -p /root/.pip/ && \
    if [ -f /root/.pip/pip.conf ]; then mv /root/.pip/pip.conf /root/.pip/pip.conf.bak; fi  
COPY ./resource/pip.conf /root/.pip/pip.conf  

RUN pip3 install -v llvmlite --ignore-installed

# Install Dependencies:
RUN pip3 install -v torch==2.1.1+cu118 torchaudio==2.1.1+cu118 --extra-index-url http://192.168.143.41:9081/repository/python/simple/
RUN rm -rf /root/.cache/pip

# Copy TTS repository contents:
WORKDIR /root/TTS
COPY ./TTS/ /root/TTS/
RUN rm /root/TTS/requirements.txt
COPY ./resource/requirements.txt /root/TTS/requirements.txt

RUN make install

CMD ["tts", "--help"]
