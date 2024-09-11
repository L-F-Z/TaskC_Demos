# TaskC_Demos
Demo projects to demonstrate the usage of TaskC

```
|- [test case name]
    |- [case repo]
    |- test
        |- xxx.py
    |- cpuDockerfile
    |- cpuDockerfile.web
    |- gpuDockerfile
    |- gpuDockerfile.web
    |- build.sh
    |- apptainer.def
```
+ [test case name]： 项目名称
+ [case repo]： 项目仓库代码，注意git checkout到指定版本，先将commit的版本号记录在build.sh中
+ test：测试目录，里面存测试代码和文件，在docker run 时挂载该文件夹，并将运行结果保存到该文件夹中（命名为res*的格式）
+ cpuDockerfile：本地CPU版本的docker构建文件
+ cpuDockerfile.web：原版CPU版本的docker构建文件
+ gpuDockerfile：本地GPU版本的docker构建文件
+ gpuDockerfile.web：原版GPU版本的docker构建文件
+ build.sh：记录commit的版本号，CPU版本和GPU版本的构建的命令和测试构建的命令
+ cpuApptianer.def：apptainer CPU版本构建的定义文件
+ gpuApptianer.def：apptainer GPU版本构建的定义文件
