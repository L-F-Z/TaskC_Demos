FROM python:3.9-slim-buster

WORKDIR /app
RUN sed -i '4s/^/#/' /etc/apt/sources.list && \
    sed -i 's|http://deb.debian.org/debian|http://192.168.2.25:9081/repository/debian/|g' /etc/apt/sources.list

RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libegl1-mesa \ 
    libxrandr2 \
    libxss1 \
    libxcursor1 \
    libxcomposite1 \
    libasound2 \
    libxi6 \
    libxtst6 \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir ~/.pip/; test -f ~/.pip/pip.conf && mv ~/.pip/pip.conf ~/.pip/pip.conf.bak; curl -s -o ~/.pip/pip.conf -m 3 https://raw.githubusercontent.com/brandnewworld/staging/refs/heads/main/pip.conf

RUN pip install --no-cache-dir \
    torch \
    torchvision \
    torchaudio \
    ftfy \
    regex \
    tqdm

WORKDIR /app/CLIP  
COPY ./CLIP /app/CLIP  

RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir .  

# COPY . /app
# CMD ["python", "example.py"]
CMD ["/bin/bash"]