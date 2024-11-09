FROM python:3.10-slim

# Set working directory
WORKDIR /app

COPY ./whisper /app/whisper

RUN apt-get update 
RUN apt-get install -y ffmpeg

RUN cd /app/whisper && \
    pip install --no-cache-dir torch===2.3.1+cu121 --extra-index-url https://download.pytorch.org/whl/cu121 && \
    pip install --no-cache-dir .

# RUN pip install -r /app/whisper/requirements.txt

# RUN whisper --model_dir /usr/local --modsel medium audio >> /dev/null 2>&1; exit 0

WORKDIR /app

CMD [ "/bin/bash" ]
