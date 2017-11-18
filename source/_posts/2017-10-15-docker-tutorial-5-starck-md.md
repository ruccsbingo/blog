---
title: Docker入门系列（五）:增加一个可持久化的访问计数
date: 2017-10-15 10:49:59
tags:

---

## 准备工作

- 安装docker，版本最低1.13
- 准备 [Docker Compose](https://docs.docker.com/compose/overview/)，[Docker for Mac](https://docs.docker.com/docker-for-mac/) 以及 [Docker for Windows](https://docs.docker.com/docker-for-windows/) 都已经预装了compose。linux系统需要自己安装，[官方安装教程](https://github.com/docker/compose/releases)。
- 了解[docker安装启动](http://ruccsbingo.github.io/2017/10/11/2017-10-11-docker-tutorial-1-orientation-and-setup/)
- 了解[构建第一个docker应用](http://ruccsbingo.github.io/2017/10/12/2017-10-12-docker-tutorial-2-first-docker-app-md/)
- 确保在上一节创建的**friendlyhello**已经发布到**registry**
- 确保**friendlyhello**可以被pull，并能正常使用
- 复制[第三节](http://ruccsbingo.github.io/2017/10/12/2017-10-12-docker-tutorial-3-scale-app/)的`docker-compose.yml`
- 确保[第四节](http://ruccsbingo.github.io/2017/10/13/2017-10-13-tutorial-4-cluster-md/)中设置的机器环境都正常运行
- 运行`docker-machine ssh myvm1 "docker node ls"`确保服务是`ready`状态

## 介绍

在[第四节](http://ruccsbingo.github.io/2017/10/13/2017-10-13-tutorial-4-cluster-md/)中，介绍了如何启动swarm，如何将服务部署到多台机器之上。在[这一节](http://ruccsbingo.github.io/2017/10/13/2017-10-13-tutorial-5-stack-md/)中,将着重介绍`stack`，所谓的`stack`就是一组相互关联的服务，它们能够共享一些依赖，能够并一起编排和扩容。在[第三节](http://ruccsbingo.github.io/2017/10/12/2017-10-12-docker-tutorial-3-scale-app/)中，介绍了一个单服务的`stack`，这个`stack`中只有一个服务，只运行在一台宿主机上。在[这一节](http://ruccsbingo.github.io/2017/10/13/2017-10-13-tutorial-5-stack-md/)中，将介绍多服务的stack，并运行在多台机器之上。

## 添加一个新的服务并部署

添加服务非常的简单，只需要编辑`docker-compose.yml`，添加相关的服务信息。比如，给swarm机器添加一个可视化的服务，展示swarm集群的机器和服务信息。

1. 编辑`docker-compose.yml`

```
version: "3"
services:
  web:
    # replace username/repo:tag with your name and image details
    image: ruccsbingo/get-started:part2
    deploy:
      replicas: 5
      resources:
        limits:
          cpus: "0.1"
          memory: 50M
      restart_policy:
        condition: on-failure
    ports:
      - "4000:80"
    networks:
      - webnet
  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints: [node.role == manager]
    networks:
      - webnet
networks:
  webnet:
```

在`docker-compose.yml`中增加了visualizer的相关配置项。

2. 配置shell，连接上myvm1的docker环境
3. 在swarm manager上执行`docker stack deploy`重新部署服务

```
$ docker stack deploy -c docker-compose.yml getstartedlab
Creating network getstartedlab_webnet
Creating service getstartedlab_web
Creating service getstartedlab_visualizer
```

4. 在浏览器中验证visualizer是否安装成功


![B5308526-E53E-411C-9D85-86272C1B38D9](http://wx1.sinaimg.cn/mw690/6a8f9c5bgy1fkj2a8cedwj20z8108q8w.jpg)


## 持久化数据

重复上面的过程，在给我们的`stack`中添加redis服务。

1. 编辑`docker-compose.yml`添加redis的依赖

```
version: "3"
services:
  web:
    # replace username/repo:tag with your name and image details
    image: ruccsbingo/get-started:part2
    deploy:
      replicas: 5
      resources:
        limits:
          cpus: "0.1"
          memory: 50M
      restart_policy:
        condition: on-failure
    ports:
      - "4000:80"
    networks:
      - webnet
  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints: [node.role == manager]
    networks:
      - webnet
  redis:
    image: redis
    ports:
      - "6379:6379"
    volumes:
      - /home/docker/data:/data
    deploy:
      placement:
        constraints: [node.role == manager]
    command: redis-server --appendonly yes
    networks:
      - webnet
networks:
  webnet:
```

Note:

 - image: redis，在Docker library中有redis的官方镜像，因此，此处可以使用简称

2. 在manager上创建data目录，用于持久化redis中的数据

```
docker-machine ssh myvm1 "mkdir ./data"
```

3. 确保当前shell环境连上manager，接下来的命令都需要在manager上执行
4. 在manager上执行`docker stack deploy`

```
$ docker stack deploy -c docker-compose.yml getstartedlab
```

5. 执行`docker service ls`验证服务启动情况

```
docker@myvm1:~$ docker service ls
ID                  NAME                       MODE                REPLICAS            IMAGE                             PORTS
nylj70biukz0        getstartedlab_redis        replicated          1/1                 redis:latest                      *:6379->6379/tcp
mval7ra97snr        getstartedlab_visualizer   replicated          1/1                 dockersamples/visualizer:stable   *:8080->8080/tcp
3qutabj1gipx        getstartedlab_web          replicated          5/5                 ruccsbingo/get-started:part2      *:4000->80/tcp
```

6. 在浏览器中验证redis中的计数情况

![](http://wx3.sinaimg.cn/mw690/6a8f9c5bgy1fkj2ysrl93j21kw0wddjg.jpg)

7. 查看visualizer，观察机器中的服务

![](http://wx3.sinaimg.cn/mw690/6a8f9c5bgy1fkj32ct9vmj20t8102afv.jpg)

恭喜你，一个完成的stack配置完成了。