---
title: Docker入门系列（三）:让你的应用变为可扩展的服务
date: 2017-10-12 18:39:33
tags:

---



## 准备工作

- 安装docker，版本最低1.13
- 准备 [Docker Compose](https://docs.docker.com/compose/overview/)，[Docker for Mac](https://docs.docker.com/docker-for-mac/) 以及 [Docker for Windows](https://docs.docker.com/docker-for-windows/) 都已经预装了compose。linux系统需要自己安装，[官方安装教程](https://github.com/docker/compose/releases)。
- 了解[docker安装启动](http://ruccsbingo.github.io/2017/10/11/2017-10-11-docker-tutorial-1-orientation-and-setup/)
- 了解[构建第一个docker应用](http://ruccsbingo.github.io/2017/10/12/2017-10-12-docker-tutorial-2-first-docker-app-md/)
- 确保在上一节创建的**friendlyhello**已经发布到**registry**，一会儿会使用到此镜像

## 介绍

在这一节中，我们将应用扩容，并支持负载均衡，这一节着重介绍**service**。

- Stack
- **Services** (<-you are)
- Container ([part 2](http://ruccsbingo.github.io/2017/10/11/2017-10-11-docker-tutorial-1-orientation-and-setup/))

## Services

在分布式环境中，**services**有很多不同的应用实例构成。想象一下，你拥有一个大型的视频分享网站，这个网站比如包含一个服务用来处理数据存储，另一个服务在后台做视频编解码，还有一个服务作为**API**接入层等等。

一个服务只运行一种镜像，但是它定义了镜像运行的方式，比如，使用什么端口，运行多少容器的副本，在Docker平台上，使用`docker-compose.yml` 可以非常方便的对服务进行定义、运行、扩容。

## 第一个docker-compose.yml

`docker-compose.yml`是yaml格式的，它定义了Docker容器在生产环境的运行方式。

**docker-compose.yml**

```
version: "3"
services:
  web:
    # replace username/repo:tag with your name and image details
    image: username/repo:tag
    deploy:
      replicas: 5
      resources:
        limits:
          cpus: "0.1"
          memory: 50M
      restart_policy:
        condition: on-failure
    ports:
      - "80:80"
    networks:
      - webnet
networks:
  webnet:
```

这个`docker-compose.yml` 定义了如下行为：

- 从registry上Pull在第二节上传的[镜像](http://ruccsbingo.github.io/2017/10/12/2017-10-12-docker-tutorial-2-first-docker-app-md/)
- 运行5个实例作为一个取名为web的service，限制每一个实例最多使用10%的cpu，50MB内存
- 容器失败后立即重启
- 将web的80端口映射到宿主机的80端口上
- 通过`webnet`在容器间共享80端口，达到负载均衡的目的（在内部, 容器将映射80端口到一个临时端口上)
- 对 `webnet` 的网络进行默认设置

## 启动负载均衡的应用

启动**swarm manager**

> docker swarm init

启动service，并命名为`getstartedlab`

> docker stack deploy -c docker-compose.yml getstartedlab

运行以上的命令后，在一个宿主机上启动5个容器实例。

查看service的Id

> docker service ls
>
> ID                  NAME                MODE                REPLICAS            IMAGE                          PORTS
>
> pxfbw2lyo4bo        getstartedlab_web   replicated          5/5                 ruccsbingo/get-started:part2   *:80->80/tcp

Docker swarms启动5个tasks来运行containers，可以使用ps命令查看这些tasks。

> docker service ps 
>
> ID                  NAME                      IMAGE                          NODE                DESIRED STATE       CURRENT STATE                ERROR               PORTS
>
> ly162fal310t        getstartedlab_web.1       ruccsbingo/get-started:part2   moby                Running             Running 27 seconds ago                           
>
> ghrcp7fzjaub         \_ getstartedlab_web.1   ruccsbingo/get-started:part2   moby                Shutdown            Shutdown 30 seconds ago                          
>
> t1jh0d1jsbj8        getstartedlab_web.2       ruccsbingo/get-started:part2   moby                Running             Running about a minute ago                       
>
> qdl4t4izqsza        getstartedlab_web.3       ruccsbingo/get-started:part2   moby                Ready               Ready 10 seconds ago                             
>
> nttsh0krytde         \_ getstartedlab_web.3   ruccsbingo/get-started:part2   moby                Shutdown            Running 10 seconds ago                           
>
> wc9xqpqehwvx        getstartedlab_web.4       ruccsbingo/get-started:part2   moby                Running             Running 10 seconds ago                           
>
> m8xjlizio550         \_ getstartedlab_web.4   ruccsbingo/get-started:part2   moby                Shutdown            Shutdown 13 seconds ago                          
>
> t37arxf436d5        getstartedlab_web.5       ruccsbingo/get-started:part2   moby                Running             Running about a minute ago                       

使用如下命令列出containers

> docker container ls -q

使用curl验证

> <h3>Hello World!</h3><b>Hostname:</b> a8ee4747d8d7<br/><b>Visits:</b> <i>cannot connect to Redis, counter disabled</i>**%**  

## 服务扩容

更改`docker-compose.yml`文件中`replicas`的数量，重启整个服务。

> docker stack deploy -c docker-compose.yml getstartedlab

Docker将会做**in-place**替换，不用先停服务，或者**kill**容器。

##  停止service和swarm

停止service的命令

> docker stack rm getstartedlab

停止swarm manager

> docker swarm leave --force

到目前为止，你已经学会了如何使用swarm进行服务的上线，扩容，下线操作。在一下节中，会介绍在集群上执行上线，扩容，下线操作。

