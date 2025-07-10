# TaskC_Demos
Demo projects to demonstrate the usage of TaskC
need to run `chmod +x Taskc.sh`

```
|- [case name]
    |- [case repo]
    |- [case name].blueprint
    |- [case name]-full(-cpu/gpu).blueprint
    |- (cpu/gpu)Dockerfile
    |- (cpu/gpu)Apptainer.def
    |- test
        |- x.py
        |- xx.jpg
        |- xxx.txt
        |- xxxx.mp3
        |- xxxxx.mp4
        |- (res*)
    |- resource
        |- pip.conf
        |- .condarc
        |- build.sh
        |- dockerfile.old 
            |- cpuDockerfile.old
            |- gpuDockerfile.old
        |- xxx.xxx
|- scripts
    |- [tool].sh
```
+ [case name]： 项目名称
+ [case repo]： 项目仓库代码源链接和指定版本
+ test：测试目录，里面存测试代码和文件，在docker run 时挂载该文件夹，并将运行结果保存到该文件夹中（命名为res*的格式）
+ [case name].blueprint：任务闭包构建文件（可支持运行的简版）
+ [case name]-full.blueprint：任务闭包对标Dockerfile内容的构建文件
+ cpuDockerfile：本地源 CPU环境的docker构建文件
+ gpuDockerfile：本地源 GPU环境的docker构建文件
+ cpuApptainer.def：本地源 apptainer CPU环境构建的定义文件
+ gpuApptainer.def：本地源 apptainer GPU环境构建的定义文件

## 脚本说明
`./scripts/`目录下是相关工具自动构建镜像/容器的脚本，使用时将其复制到项目文件下。
以`Docker.sh`为例：
```
用法: bash Docker.sh [proj1 proj2 ... | all]
  proj: 构建指定的项目，例如 bash Docker.sh CLIP
  all : 构建所有项目，例如 bash Docker.sh all
  支持同时构建多个项目，例如 bash Docker.sh CLIP YOLOv5
Flags:
  --no-cache   每次构建时清除缓存，例如 bash --no-cache Docker.sh CLIP
  --cpu        仅构建 CPU 版本的镜像，例如 bash Docker.sh --cpu CLIP
  --gpu        仅构建 GPU 版本的镜像，例如 bash Docker.sh --gpu CLIP
Available Commands:
  cleanlog: 清空日志和报错信息文件
  cleanbuild: 清空所有docker镜像、容器和缓存
```
*monitor.sh，Pull.sh和Push.sh是在测试中为了自行搭建的仓库传输定制的，不具有通用性!
*Taskc-cpu.sh 是为了测试Taskc在CPU机器上构建各个版本能力的脚本。