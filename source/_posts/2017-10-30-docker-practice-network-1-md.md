---
title: docker容器的网络
date: 2017-10-30 21:44:15
tags:
---

## 准备工作

- 安装docker

## 使用默认的网络启动一个容器

Docker通过 **network drivers**支持容器的网络环境。默认情况下，Docker支持`bridge` 和 `overlay`两种网络驱动。也可以支持自定义的网络驱动。

每一个Docker Engine都会自动支持三种默认的网络，可以使用`docker network ls`列出所有的网络驱动：

```
$ docker network ls

NETWORK ID          NAME                DRIVER
18a2866682b8        none                null
c288470c46f6        host                host
7b369448dccb        bridge              bridge
```

`bridge`是一个特殊的网络驱动，如果不做特别指定，所有的容器都会在`bridge`下启动。尝试一下如下的命令：

```
$ docker run -itd --name=networktest ubuntu
74695c9cea6d9810718fddadc01a727a5dd3ce6a69d09752239736c030599741
```

![](http://wx3.sinaimg.cn/mw690/6a8f9c5bly1fl1qddzvppj208c0a7q3h.jpg)

通过`docker network inspect bridge`命令可以查看一下容器的网络信息

```
$ docker network inspect bridge
[
    {
        "Name": "bridge",
        "Id": "f7ab26d71dbd6f557852c7156ae0574bbf62c42f539b50c8ebde0f728a253b6f",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.17.0.1/16",
                    "Gateway": "172.17.0.1"
                }
            ]
        },
        "Internal": false,
        "Containers": {
            "3386a527aa08b37ea9232cbcace2d2458d49f44bb05a6b775fba7ddd40d8f92c": {
                "Name": "networktest",
                "EndpointID": "647c12443e91faf0fd508b6edfe59c30b642abb60dfab890b4bdccee38750bc1",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.bridge.default_bridge": "true",
            "com.docker.network.bridge.enable_icc": "true",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
            "com.docker.network.bridge.name": "docker0",
            "com.docker.network.driver.mtu": "9001"
        },
        "Labels": {}
    }
]
```

从一个网络中移除一个容器，如下

```
$ docker network disconnect bridge networktest
```

以上的命令将networktest容器从bridge网络中移除。使用网络可以方便的将容器隔离。

## 创建自定义网桥

Docker Engine支持`bridge`和`overlay`模式的网络，`bridge`模式只能在单机上使用，`overlay`支持多机使用。接下来，使用`bridge`创建自定义的网络，

```
$ docker network create -d bridge my_bridge
```

`-d`参数指定网络的模式，如果不加`-d`参数，默认也使用`bridge`模式。检查一下是否创建成功，

```
$ docker network ls

NETWORK ID          NAME                DRIVER
7b369448dccb        bridge              bridge
615d565d498c        my_bridge           bridge
18a2866682b8        none                null
c288470c46f6        host                host
```

使用`inspect`命令检查新建网络的信息，

```
$ docker network inspect my_bridge

[
    {
        "Name": "my_bridge",
        "Id": "5a8afc6364bccb199540e133e63adb76a557906dd9ff82b94183fc48c40857ac",
        "Scope": "local",
        "Driver": "bridge",
        "IPAM": {
            "Driver": "default",
            "Config": [
                {
                    "Subnet": "10.0.0.0/24",
                    "Gateway": "10.0.0.1"
                }
            ]
        },
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]
```

## 隔离的网络让应用更加安全

接下来，用一个简单的web应用展示如何安全的使用容器的网络。

第一步，在自定义的网络上创建数据库容器，

```
$ docker run -d --net=my_bridge --name db training/postgres
```

`--net`参数指定使用的网络，检查是否创建成功，

```
$ docker inspect --format='{{json .NetworkSettings.Networks}}'  db


{"my_bridge":{"NetworkID":"7d86d31b1478e7cca9ebed7e73aa0fdeec46c5ca29497431d3007d2d9e15ed99",
"EndpointID":"508b170d56b2ac9e4ef86694b0a76a22dd3df1983404f7321da5649645bf7043","Gateway":"10.0.0.1","IPAddress":"10.0.0.254","IPPrefixLen":24,"IPv6Gateway":"","GlobalIPv6Address":"","GlobalIPv6PrefixLen":0,"MacAddress":"02:42:ac:11:00:02"}}
```

第二步，在默认的网络下创建web应用，

```
$ docker run -d --name web training/webapp python app.py
```

检查网络信息，

```
$ docker inspect --format='{{json .NetworkSettings.Networks}}'  web


{"bridge":{"NetworkID":"7ea29fc1412292a2d7bba362f9253545fecdfa8ce9a6e37dd10ba8bee7129812",
"EndpointID":"508b170d56b2ac9e4ef86694b0a76a22dd3df1983404f7321da5649645bf7043","Gateway":"172.17.0.1","IPAddress":"10.0.0.2","IPPrefixLen":24,"IPv6Gateway":"","GlobalIPv6Address":"","GlobalIPv6PrefixLen":0,"MacAddress":"02:42:ac:11:00:02"}}
```

查看web的地址，

```
$ docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web


172.17.0.2
```

当前的网络拓扑图如下，

![](http://wx1.sinaimg.cn/mw690/6a8f9c5bly1fl1qvgdp25j20k00cggm6.jpg)

第三步，查看网络的连通性，

```
$ docker exec -it db bash

root@a205f0dd33b2:/# ping 172.17.0.2
ping 172.17.0.2
PING 172.17.0.2 (172.17.0.2) 56(84) bytes of data.
^C
--- 172.17.0.2 ping statistics ---
44 packets transmitted, 0 received, 100% packet loss, time 43185ms
```

会发现在db上，无法连通到web上。

第四步，将web连接到my_bridge上，

```
$ docker network connect my_bridge web
```

当前的网络拓扑，

![](http://wx1.sinaimg.cn/mw690/6a8f9c5bly1fl1r09aaoij20jy0cgjs7.jpg)

第五步，再一次验证网络的连通性，

```
$ docker exec -it db bash

root@a205f0dd33b2:/# ping web
PING web (10.0.0.2) 56(84) bytes of data.
64 bytes from web (10.0.0.2): icmp_seq=1 ttl=64 time=0.095 ms
64 bytes from web (10.0.0.2): icmp_seq=2 ttl=64 time=0.060 ms
64 bytes from web (10.0.0.2): icmp_seq=3 ttl=64 time=0.066 ms
^C
--- web ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2000ms
rtt min/avg/max/mdev = 0.060/0.073/0.095/0.018 ms
```

会发现db和web已经能够正常的连通。其它不在my_bridge上的容器不能连接到该网络环境中

## 总结

通过自定义网络环境，可以将安全性要求较高的服务，放入单独的自定义的网络环境中，以此保证服务的安全行。