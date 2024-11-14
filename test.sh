#!/bin/bash

# ./Taskc.sh cleanbuild
# ./Taskc.sh --no-cache --gpu CLIP
./Docker.sh cleanbuild
./Docker.sh --no-cache stablediffusion
sleep 1

# bash Taskc.sh cleanbuild
# systemd-run --scope --property=CPUAffinity=0 1   -p CPUQuota=200%   -p MemoryMax=4G bash Taskc.sh --no-cache --gpu CLIP
# sleep 3

# bash Taskc.sh cleanbuild
# systemd-run --scope --property=CPUAffinity=0 1 2 3 -p CPUQuota=400%   -p MemoryMax=8G bash Taskc.sh --no-cache --gpu CLIP
# sleep 3

# bash Taskc.sh cleanbuild
# systemd-run --scope --property=CPUAffinity=0 1 2 3  -p CPUQuota=400%   -p MemoryMax=16G bash Taskc.sh --no-cache --gpu CLIP
# sleep 3

# bash Taskc.sh cleanbuild
# systemd-run --scope --property=CPUAffinity=0 1 2 3 4 5 6 7  -p CPUQuota=800%   -p MemoryMax=16G bash Taskc.sh --no-cache --gpu CLIP
# sleep 3

# bash Taskc.sh cleanbuild
# systemd-run --scope --property=CPUAffinity=0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15  -p CPUQuota=1600%   -p MemoryMax=32G bash Taskc.sh --no-cache --gpu CLIP