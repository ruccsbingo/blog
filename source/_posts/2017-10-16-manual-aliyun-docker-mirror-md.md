---
title: Mac上配置阿里云的docker镜像
date: 2017-10-15 16:43:18
tags:
category: docker
---

## 需求

由于众所周知的原因，在国内使用docker hub的体验让人奔溃，网速太慢，代理不稳定。好在可以使用国内镜像，接下来，记录一下，使用阿里云镜像的步骤。

### 安装／升级你的Docker客户端

- 对于10.10.3以下的用户 推荐使用

   

  ```
  Docker Toolbox
  ```

  - Toolbox的介绍和帮助：[mirrors.aliyun.com/help/docker-toolbox](http://mirrors.aliyun.com/help/docker-toolbox)
  - Mac系统的安装文件目录：<http://mirrors.aliyun.com/docker-toolbox/mac/docker-toolbox/>

- 对于10.10.3以上的用户 推荐使用 

  ```
  Docker for Mac
  ```

  - Mac系统的安装文件目录：<http://mirrors.aliyun.com/docker-toolbox/mac/docker-for-mac/>

### 如何使用Docker加速器

1. 创建一台安装有Docker环境的Linux虚拟机，指定机器名称为default，同时配置Docker加速器地址。

   ```
   docker-machine create --engine-registry-mirror=https://ykf2xy9h.mirror.aliyuncs.com -d virtualbox default

   ```

2. 查看机器的环境配置，并配置到本地，并通过Docker客户端访问Docker服务。

   ```
   docker-machine env default
   eval "$(docker-machine env default)"
   docker info
   ```

3. 执行`hello-world`,验证是否配置成功

   ```
   $ docker run hello-world

   Hello from Docker!
   This message shows that your installation appears to be working correctly.

   To generate this message, Docker took the following steps:
    1. The Docker client contacted the Docker daemon.
    2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    3. The Docker daemon created a new container from that image which runs the
       executable that produces the output you are currently reading.
    4. The Docker daemon streamed that output to the Docker client, which sent it
       to your terminal.

   To try something more ambitious, you can run an Ubuntu container with:
    $ docker run -it ubuntu bash

   Share images, automate workflows, and more with a free Docker ID:
    https://cloud.docker.com/

   For more examples and ideas, visit:
    https://docs.docker.com/engine/userguide/
   ```

恭喜你，可以愉快使用docker镜像了。
