# TaskC_Demos
Demo projects to demonstrate the usage of TaskC
need to run `chmod +x Taskc.sh`

```
|- [test case name]
    |- [case repo]
    |- [test case name].blueprint
    |- cpuDockerfile
    |- gpuDockerfile
    |- cpuApptainer.def
    |- gpuApptainer.def
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
```
+ [test case name]： 项目名称
+ [case repo]： 项目仓库代码，注意git checkout到指定版本，先将commit的版本号记录在build.sh中
+ test：测试目录，里面存测试代码和文件，在docker run 时挂载该文件夹，并将运行结果保存到该文件夹中（命名为res*的格式）
+ [test case name].blueprint：任务闭包构建文件
+ cpuDockerfile：本地源-CPU版本的docker构建文件
+ gpuDockerfile：本地源-GPU版本的docker构建文件
+ cpuApptainer.def：本地源 apptainer CPU版本构建的定义文件
+ gpuApptainer.def：本地源 apptainer GPU版本构建的定义文件


