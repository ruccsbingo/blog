---
title: Docker入门系列（六）：最后的总结
date: 2017-10-15 18:08:14
tags:
---

经过一段时间的思考，终于下定决心好好的学习一下docker。找到官网的教程，前前后后花了一周的时间，按照教程一步一步的敲命令，完整的搭建了一个完整的swarm集群。

在做的过程中，遇到很多的问题，

- 第一个最让人头疼的问题，就是国内网络访问docker hub速度感人，经常出现各种各样的莫名其妙的问题，刚开始的时候，也不懂在哪里找error log。明明很简单的一个命令，就是没有预定的结果，后来发现，所有的奇怪问题，基本都和网络有关，一般都是想要下载的image没有下载下来。
- 第二个就需要仔细阅读官方教程，仔细理解docker各个组件的概念，区别docker client， docker deamon，swarm manager，worker。
- 第三个端口的问题，区别docker deamon的端口，和swarm manager的端口。
- 最后，要好好理解docker repository，了解docker pull的执行流程。

针对上面提到的第一个和第三个问题，都在文档中做了记载，已备后来者。

第一个问题的解决方案，[设置阿里云镜像](http://ruccsbingo.github.io/2017/10/15/2017-10-16-manual-aliyun-docker-mirror-md/)。

第三个问题，关于2377和2376的区别，在[docker入门系列（四）](http://ruccsbingo.github.io/2017/10/13/2017-10-13-docker-tutorial-4-cluster-md/)中有提到。。

**最后的总结**

看介绍文章，和一步一步实践，一行一行敲命令，还是有很大的区别。以前总是看一些技术性的介绍文章，觉得自己什么都懂了，什么概念都清楚了，开口闭口都是容器化，服务编排。等到一个任务交给你去做的时候，总是无从下手，这次动手实践，真真实实的感受到了，docker给编程，或者说是软件流程的革命性的变化，一件搭建编程环境，一键部署应用，几代工程师的梦想，看来越来越接近现实了。