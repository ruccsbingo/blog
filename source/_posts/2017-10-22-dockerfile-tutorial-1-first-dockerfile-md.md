---
title: 学习dockerfile（一）：创建一个基础镜像
date: 2017-10-22 12:03:11
tags:
---

前两周看完了docker tutorial官方系列教程，了解了docker是什么，docker的使用场景，为什么要使用docker以及如何使用docker。接下来的一周，需要深入一点，修炼一些docker的基本功，比如，如何写好dockerfile。
这一系列的教程有如下几篇文档：

1. 创建一个基础镜像
2. 多阶段构建
3. 管理镜像
4. 编写Dockerfile最佳实践

绝大多数的Dockerfile都会基于已有的基础镜像进行构建，如果你需要完全控制镜像的内容，从空白的镜像创建，需要使用`FROM scratch`，或者不使用`FROM`指令。

## 使用FROM scratch创建镜像

`scratch`镜像是Docker保留的最小镜像。使用`scratch`开始创建，`scratch`的下一条命令，将会是镜像的第一层。

- 创建一个linux环境

```
$ docker run --rm -it -v $PWD:/build ubuntu:16.04
container# apt-get update && apt-get install build-essential
container# cd /build
container# gcc -o hello -static -nostartfiles hello.c

```

- 创建一个hello-world镜像

```
FROM scratch
ADD hello /
CMD ["/hello"]
```

## 总结

这篇文章介绍了如何使用docker创建一个简单的linux的编译环境，编译一个简单的hello-world二进制文件，并将这个二进制文件加入到空白的镜像中执行。



