---
title: Docker入门系列（四）:让你的服务跨越多台机器
date: 2017-10-13 17:04:12
tags:
---

## 准备工作

- 安装docker，版本最低1.13
- 准备 [Docker Compose](https://docs.docker.com/compose/overview/)，[Docker for Mac](https://docs.docker.com/docker-for-mac/) 以及 [Docker for Windows](https://docs.docker.com/docker-for-windows/) 都已经预装了compose。linux系统需要自己安装，[官方安装教程](https://github.com/docker/compose/releases)。
- 了解[docker安装启动](http://ruccsbingo.github.io/2017/10/11/2017-10-11-docker-tutorial-1-orientation-and-setup/)
- 了解[构建第一个docker应用](http://ruccsbingo.github.io/2017/10/12/2017-10-12-docker-tutorial-2-first-docker-app-md/)
- 确保在上一节创建的**friendlyhello**已经发布到**registry**
- 确保**friendlyhello**可以被pull，并能正常使用
- 复制第三部分的`docker-compose.yml`

## 介绍

在[第三节](http://ruccsbingo.github.io/2017/10/12/2017-10-12-docker-tutorial-3-scale-app/)中，我们使用了[第二节](http://ruccsbingo.github.io/2017/10/12/2017-10-12-docker-tutorial-2-first-docker-app-md/)写的应用，并定义了它在线上的运行方式，然后启动了5个实例。

在这一节中，我们将这个应用部署到多机集群中，正式步入swarm模式，多机、多容器的应用。

## 理解 Swarm clusters

**Swarm**是什么？**Swarm**就是一组运行docker的机器，并联合成为一个集群。当启动**Swarm**集群之后，docker命令会通过**Swarm manager**执行在整个集群之上。**Swarm**集群的机器可以是物理机，也可以是虚拟机，当加入**Swarm**集群之后，被称为**nodes**。

Swarm managers有两种不同的方式运行container：第一种*emptiest node*，尽量使用少的机器部署容器；第二种*global*，确保每一台机器上都会运行一个容器的实例。可以在`docker-compose.yml`中指定运行的模式。

Swarm managers是集群的核心控制节点，它负责执行命令，授权新机器加入集群。Worker节点只负责提供资源。

到目前为止，你已经学会在单机使用docker容器。docker可以很方便的切换为 **swarm mode**，切换的命令是`docker swarm init`，一旦切换为 **swarm mode**后，当前的机器角色就变为Swarm managers。

## 设置你的swarm集群

### 创建cluster

在本机上使用VM创建集群，我使用的Mac操作系统，接下来演示在Mac上创建swarm集群。

首先，需要安装虚拟机，在Mac上需要下载 [Oracle VirtualBox](https://www.virtualbox.org/wiki/Downloads)。

使用`docker-machine`创建多个虚拟机

> docker-machine create --driver virtualbox myvm1
> docker-machine create --driver virtualbox myvm2

使用`docker-machine ls`列出所有的虚拟机

> $ docker-machine ls
>
> NAME    ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
>
> myvm1   -        virtualbox   Running   tcp://192.168.99.100:2376           v17.09.0-ce   
>
> myvm2   -        virtualbox   Running   tcp://192.168.99.101:2376           v17.09.0-ce   

接下来，开始初始化swarm，将myvm1设置为manager，并向集群中加入节点。

```
$ docker-machine ssh myvm1 "docker swarm init --advertise-addr 192.168.99.100:2376"
Swarm initialized: current node (gxhg37symzvlve65jgg9ya984) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-07zo0vcw3uch6r47b3b8rpcqcqz00sa9679s3jil660cimyb72-8t8nfbynnphl2zw8str5efm47 192.168.99.100:2376

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

添加worker节点

``` 
$ docker-machine ssh myvm2 "docker swarm join --token SWMTKN-1-07zo0vcw3uch6r47b3b8rpcqcqz00sa9679

s3jil660cimyb72-8t8nfbynnphl2zw8str5efm47 192.168.99.100:2377"`
```

**2377 vs 2376**

注意`docker swarm init`和`docker swarm join`运行的端口号是`2377`，或者不指定端口，使用默认端口。`docker-machine ls`返回的端口是`2376`，这个端口是`docker deamon`的端口。

在`swarm manager`上执行`docker node ls`检查集群运行情况

```
$ docker-machine ssh myvm1 "docker node ls"
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS
gxhg37symzvlve65jgg9ya984 *   myvm1               Ready               Active              Leader
qcbxu2hop7nf13ktzxfg36ein     myvm2               Ready               Active           
```

如果看到以上输出信息，恭喜你，你已经启动成功。

使用`docker swarm leave`推出swarm集群

```
$ docker-machine ssh myvm2 "docker swarm leave"
Node left the swarm.
```

## 部署service到swarm cluster

当此最复杂的部分已经学习完，接下来重复在[第三节](http://ruccsbingo.github.io/2017/10/12/2017-10-12-docker-tutorial-3-scale-app/)的操纵，把service部署到集群中。记住，只有swarm manager也就是myvm1可以执行docker命令。每一次连上swarm manager都需要执行`docker-machine ssh`比较麻烦，我们一个使用另外一种替代方案。使用`docker-machine env <machine>`配置当前shell连接到在虚拟机上的`Docker daemon`。

```
$ docker-machine env myvm1
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.99.100:2376"
export DOCKER_CERT_PATH="/Users/zhangbing/.docker/machine/machines/myvm1"
export DOCKER_MACHINE_NAME="myvm1"
# Run this command to configure your shell: 
# eval $(docker-machine env myvm1)
```

执行`eval $(docker-machine env myvm1)`配置当前的shell连接myvm1

```
eval $(docker-machine env myvm1)
```

执行`docker-machine ls`验证myvm1生效。

```
$ docker-machine ls
NAME    ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
myvm1   *        virtualbox   Running   tcp://192.168.99.100:2376           v17.09.0-ce   
myvm2   -        virtualbox   Running   tcp://192.168.99.101:2376           v17.09.0-ce   
```

可以看到myvm1是active。

接下来，通过swarm manager将服务部署到集群上，

```
$ docker stack deploy -c docker-compose.yml getstartedlab
Creating network getstartedlab_webnet
Creating service getstartedlab_web
```

检查服务的启动情况

```
$ docker stack ps getstartedlab
ID                  NAME                  IMAGE               NODE                DESIRED STATE       CURRENT STATE              ERROR               PORTS
j18ii2ij6daf        getstartedlab_web.1   username/repo:tag   myvm2               Running             Preparing 30 seconds ago                       
oss51cyvy2n0        getstartedlab_web.2   username/repo:tag   myvm2               Running             Preparing 30 seconds ago                       
rfvqjkhwxtif        getstartedlab_web.3   username/repo:tag   myvm1               Running             Preparing 30 seconds ago                       
y0xapfhxopum        getstartedlab_web.4   username/repo:tag   myvm2               Running             Preparing 30 seconds ago                       
8a4q8rq4jcxs        getstartedlab_web.5   username/repo:tag   myvm1               Running             Preparing 30 seconds ago     
```

## 清理工作

停止service的命令

> docker stack rm getstartedlab

停止swarm manager

> docker swarm leave --force

Ok,你已经在生产环境上操作swarm进行服务的上线，扩容，下线的整个过程。

清理宿主机的shell环境

```
eval $(docker-machine env -u)
```

