---
title:    Docker入门系列（一）：目标和安排
date:     2017-10-11 14:32
tags:
---
这个系列的教程来源于docker的官方文档，此文档的目的在于一步一步学习docker的使用方法。
这一系列的教程有如下几篇文档：
1. docker安装启动
2. 构建第一个docker应用
3. 让你的应用变为可扩展的服务
4. 让你的服务跨越多台机器
5. 增加一个可持久化的访问计数
6. 将swarm部署到生产环境

Docker的价值在于，如何构建，传输以及运行你的应用程序。这是作为使用者最需要关注的方向。

## 准备工作
在正式开始之前，最好先了解[Docker是什么](https://www.docker.com/what-docker)，[我们为什么需要Docker](https://www.docker.com/use-cases)。
最好准备以下计算机基础知识：
- IP地址和端口
- 虚拟机
- 系统配置文件
- 代码依赖以及构建
- 系统资源，比如cpu使用率，内存大小等
## 容器的简单阐述
镜像（**image**）是一个轻量的、独立的、可执行的软件包。这个软件包包含了程序代码、运行环境、库文件、环境变量、以及配置文件等程序执行所需要的所有部分。
容器（**container**）是镜像的一个运行实例。在默认情况下，容器和宿主机是完全隔离的，也可以配置访问宿主机的文件系统和网络端口。
容器在本地运行应用程序基于宿主机的内核（**kernel**）。和虚拟机相比，容器拥有更好的性能。容器能够直接访问机器资源，容器运行在独立的进程中，并不会比可执行程序消耗更多的内存。
容器 VS 虚拟机
虚拟机![](https://i.imgur.com/G8SGx08.png)
虚拟机运行在访客系统之上，这是一种资源竞争型的架构，会造成磁盘状态和应用在OS设置、系统安装依赖、系统安全层面相互干扰，还会有其他的**easy-to-lose, hard-to-replicate**的问题。 
容器![](https://i.imgur.com/gtcMmXk.png)
容器可以共享内核，容器内部需要的配置，都会安装在容器的内部，各个容器之间是相互隔离的。因此，容器包含它运行所需要的所有环境，能真正的实现**runs anywhere**。
## 安装docker
>[install](https://docs.docker.com/engine/installation/)
>

安装成功之后，运行**hello-world**
> $ docker run hello-world
> 
>Hello from Docker!
This message shows that your installation appears to be working correctly.
>
>To generate this message, Docker took the following steps:
...(snipped)...

检查docker版本
> $ docker --version
> Docker version 17.06.2-ce, build cec0b72
> 
看到如下输出信息，说明已经安装成功，可以享受docker之旅了。

## 总结
服务伸缩的最小单元是独立的、可移植的意义重大，它意味着CI/CD能够更新一个分布式应用的任何一部分，系统依赖不在是问题，并且资源使用率也大大提升。服务编排将紧紧围绕可执行程序，而非VM主机。
这将是一个巨大的进步，首先让我们学会如何快速行走吧。

