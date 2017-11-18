---
title: Docker入门系列（二）：构建第一个docker应用
date: 2017-10-12 11:18:05
tags:
---

## 准备工作
- 安装docker，版本最低1.13
- 了解前一部分的内容[目标和安排](http://ruccsbingo.github.io/2017/10/11/2017-10-11-docker-tutorial-1-orientation-and-setup/)
- 验证docker环境可用
    > docker run hello-world

## 介绍
现在，可以使用docker的方式构建一个应用。首先，我们从最基础、最底层的部分开始。在这篇文章中，将介绍容器的使用。在下一篇文章中，我们将介绍service。最后，会介绍整个容器栈的顶层，service在容器中如何交互。
Stack
Services
Container (<-- you are)
## 你的新开发环境
在过去，你想开发python应用，你首先需要在本机上安装python运行环境。经常会遇到你本机的运行环境和服务器的运行环境并不一致。环境不一致，会带来各种奇奇怪怪的问题，影响开发效率。
使用docker，你只需要获取一份可移植的python运行镜像，并不需要安装。然后，将code、运行环境、程序库文件、系统配置都安装到镜像中，确保程序可以run anywhere。
## 使用Dockerfile定义容器
Dockerfile是容器最重要的组成部分，它定义了容器的总体框架。在容器内部，访问系统资源，比如网络接口、磁盘驱动，都是虚拟化的，和系统的其他部分都是隔离的。因此，你不得不向外部世界映射出口，明确哪些文件需要复制到容器内部。做完这些，你的应用程序的表现行为将和Dockerfile中定义的行为完全一致。
### Dockerfile
```
# Use an official Python runtime as a parent image
FROM python:2.7-slim

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
ADD . /app

# Install any needed packages specified in requirements.txt
RUN pip install -r requirements.txt

# Make port 80 available to the world outside this container
EXPOSE 80

# Define environment variable
ENV NAME World

# Run app.py when the container launches
CMD ["python", "app.py"]
```
### 准备应用程序
创建**requirements.txt**和**app.py**。和**Dockerfile**放在同一个目录。
*requirements.txt*
```
Flask
Redis
```
*app.py*
```
from flask import Flask
from redis import Redis, RedisError
import os
import socket

# Connect to Redis
redis = Redis(host="redis", db=0, socket_connect_timeout=2, socket_timeout=2)

app = Flask(__name__)

@app.route("/")
def hello():
    try:
        visits = redis.incr("counter")
    except RedisError:
        visits = "<i>cannot connect to Redis, counter disabled</i>"

    html = "<h3>Hello {name}!</h3>" \
           "<b>Hostname:</b> {hostname}<br/>" \
           "<b>Visits:</b> {visits}"
    return html.format(name=os.getenv("NAME", "world"), hostname=socket.gethostname(), visits=visits)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)
```
## 构建应用程序
进入Dockerfile存放的目录，执行build命令
> docker build -t friendlyhello .

构建成功之后，执行images命令验证效果。
> $ docker images
> REPOSITORY            TAG                 IMAGE ID
friendlyhello         latest              326387cea398

## 运行应用程序
将应用程序的80端口映射到宿主机的4000端口，使用如下命令映射并启动。
> docker run -p 4000:80 friendlyhello

在浏览器中输入*http://localhost:4000*验证。
![](https://i.imgur.com/kETeUrY.png)
恭喜你，运行成功。
当前的容器运行在terminal中，可以使用ctrl+c终止容器的运行。
也可以让容器运行在后台，使用如下命令启动
> docker run -d -p 4000:80 friendlyhello

-d参数指示容器在后台运行，可以使用如下命令查看所有运行的容器。
> $ docker container ls
CONTAINER ID        IMAGE               COMMAND             CREATED
1fa4ab2cf395        friendlyhello       "python app.py"     28 seconds ago

CONTAINER ID是容器的身份标识，可以使用stop命令配合CONTAINER ID停止在后台运行的容器。
> docker container stop 1fa4ab2cf395



