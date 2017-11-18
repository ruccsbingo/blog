---
title: 学习dockerfile（二）：多阶段构建
date: 2017-10-25 22:33:01
tags:
---

## 准备工作

- 安装docker，multi-stage功能的最低版本17.05。
- 了解[创建一个基础镜像](http://ruccsbingo.github.io/2017/10/22/2017-10-22-dockerfile-tutorial-1-first-dockerfile-md/)

## 介绍

multi-stage功能有什么功效？接下来将通过一个go程序例子进行讲解。开发go应用程序需要如下几个必备条件；

- 一台用于开发的机器（linux、window）
- go开发环境，设置goroot、gopath，gobin等环境变量
- 额外的lib库
- 运行binary环境

如果不使用multi-stage，为了尽量保证image比较小，可能会使用如下的方式构建docker image。

- 第一步，创建用于编译环境的`Dockerfile.build`

```
FROM golang:1.7.3
WORKDIR /go/src/github.com/alexellis/href-counter/
RUN go get -d -v golang.org/x/net/html  
COPY app.go .
RUN go get -d -v golang.org/x/net/html \
  && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .
```

- 第二步，创建用于运行环境的`Dockerfile`

```
FROM alpine:latest  
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY app .
CMD ["./app"] 
```

- 第三步，创建运行脚步`build.sh`

```
#!/bin/sh
echo Building alexellis2/href-counter:build

docker build --build-arg https_proxy=$https_proxy --build-arg http_proxy=$http_proxy \  
    -t alexellis2/href-counter:build . -f Dockerfile.build

docker create --name extract alexellis2/href-counter:build  
docker cp extract:/go/src/github.com/alexellis/href-counter/app ./app  
docker rm -f extract

echo Building alexellis2/href-counter:latest

docker build --no-cache -t alexellis2/href-counter:latest .
rm ./app
```

以上的构建过程，运行`build.sh`，会先构建编译环境用于构建可运行的应用程序，然后，将可执行应用程序app拷贝到local，用于构建最终的运行环境，最后，清理local的app临时文件。

整个构建过程，需要编写额外的`build.sh`脚步，执行冗长的命令，最后还需要做一些清理工作。不管是用于编译的image还是用于运行的image都会占用本地的磁盘空间。

那么，有没有更好的方式？答案就是`multi-stage`。

## 使用multi-stage构建

### 编写`dockerfile`

```
FROM golang:1.7.3
WORKDIR /go/src/github.com/alexellis/href-counter/
RUN go get -d -v golang.org/x/net/html  
COPY app.go .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

FROM alpine:latest  
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=0 /go/src/github.com/alexellis/href-counter/app .
CMD ["./app"]  
```

在`dockerfile`中，使用两次`FROM`命令，每一个`FROM`可以使用不同的基础`image`，它们处于不同的构建阶段。可以从一个`stage`拷贝文件到另外一个`stage`，使用`COPY`命令，`--from`指定从哪个stage拷贝，不需要的文件可以完全忽略。

构建命令如下，

```
docker build -t alexellis2/href-counter:latest .
```

### 给stage命名

默认情况下，每一个stage是没有命名的，只能通过序号进行引用，第一个`FROM`的序号是0，后面的依次类推。也可以通过给stage命名，更方便的引用各个stage，并增加可维护性，避免重新排列`FROM`命令造成混乱。接下来通过修改上面的例子展示了stage命名的用法；

```
FROM golang:1.7.3 as builder
WORKDIR /go/src/github.com/alexellis/href-counter/
RUN go get -d -v golang.org/x/net/html  
COPY app.go    .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

FROM alpine:latest  
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /go/src/github.com/alexellis/href-counter/app .
CMD ["./app"]  
```

## 总结

multi-stage模式有效的减少了image的大小，增加了dockerfile，部署的简洁性和可维护性。