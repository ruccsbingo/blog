---
title: 学习DOCKERFILE（三）：编写dockerfile的一些建议
date: 2017-10-29 13:42:32
tags:
---

## 准备工作

- 了解如何[创建一个基础镜像](http://ruccsbingo.github.io/2017/10/22/2017-10-22-dockerfile-tutorial-1-first-dockerfile-md/)
- 了解[多阶段构建](http://ruccsbingo.github.io/2017/10/25/2017-10-25-dockerfile-tutorial-2-multi-stage-builds-md/)

## 常用的原则

- 原则一：容器的生命周期越短越好

所谓的生命周期越短越好，是要强调，通过`dockerfile`定义的镜像，可以使用最少的步骤和配置，很方便的停止、销毁、构建、部署，达到无状态的模式。

- 原则二：使用`.dockerignore`文件

`docker build`指令运行的上下文环境有两种，其一，`docker build`运行的当前目录以及所有的子目录；其二，`-f`命令指定的目录及所有的子目录。当运行`docker build`命令时，上下文环境中的所有文件及其目录都会被送到`docker deamon`中，被认为是编译的上下文环境。上下文中的文件越多越大，编译所需要的时间，以及最终编译出来的image就会越大。也会直接的导致，pull、push以及run这个image的时间会越长。下面的这条信息告知了docker build上下文环境的大小，

```
Sending build context to Docker daemon  187.8MB
```

一些编译环境的文件也不能被删除，为了优化这个问题，docker提供了`.dockerginore`文件，它如同`.gitignore`文件一样，支持排除模式。

```
# comment
*/temp*
*/*/temp*
temp?
```

| Rule        | Behavior                                 |
| ----------- | ---------------------------------------- |
| `# comment` | 忽略                                       |
| `*/temp*`   | 根目录的二级子目录中，以temp开头的文件或者文件夹，都会被忽略。例如，`/somedir/temporary.txt` 将会被忽略。 |
| `*/*/temp*` | 根目录的三级子目录中，以temp开头的文件或者文件夹，都会被忽略。例如，`/somedir/subdir／temporary.txt` 将会被忽略。 |
| `temp?`     | 根目录下的以 `/tempa` 开头的文件或者文件夹，都会被忽略。        |

- 原则三：使用`muitl-stage`多阶段构建

使用`muitl-stage`多阶段构建，可以有效的减少了image的大小，增加了dockerfile，部署的简洁性和可维护性。

- 原则四：避免安装不必要的包

为了减少复杂性、依赖、文件大小以及构建时间，最好避免安装不必要的包。例如，数据库的image中没有必要安装文件编辑工具。

- 原则五：每个容器应该只做一件事情

将一个大的应用解耦分拆到不同的容器中，使其更好的水平扩展、重用。例如，一个web应用栈可以分为三个独立的容器，一个容器用做web界面，一个用做数据库存储，一个用于in-memory的缓存。

你可能听说过“一个容器就是一个进程”，这句话虽有夸张的成分，但是很好的解释了，使用容器的范式。尽量让容器功能单一，如果容器之间存在依赖，可以使用docker container networks相互通信。

- 原则六：容器的文件层越少越好，减少到不能再少

docker 17.05以及1.10以前，减少文件层非常的重要。比较高版本的docker优化了这些问题；

docker 1.10 以及高版本，只有`RUN`, `COPY`以及 `ADD`指令 会增加文件层，其它指令会创建临时的中间镜像，不会增加最终的image的大小。

Docker 17.05 以及高版本，增加了multi-stage特性，允许只拷贝想要的文件到最终的镜像。

- 原则七：将多参数的命令行排序

只要有可能，将多参数的命令行安装字母顺序排序，保证格式清楚，可阅读性高。例如：

```
RUN apt-get update && apt-get install -y \
  bzr \
  cvs \
  git \
  mercurial \
  subversion
```

- 原则八：使用缓存

image的构建过程，就是一步一步按照指定的顺序执行dockerfile中的命令。每执行一条命令，docker会先在cache中查找，是否有以及存在可复用的缓存，如果没有，则会创建新的image。如果不想使用缓存功能，可以在运行`docker build`命令是指定`--no-cache=true`参数。

缓存的查找规则如下，

1. 使用一个已经存在在缓存中的镜像最为父镜像，紧接着的一条命令，将会和此父镜像衍生的子镜像做对比，如果命令不同，则cache失效。
2. 在大多数情况下，只需要简单的比较dockerfile文件是否相同。在特殊的情况下，需要更复杂的对比。
3. 对于`ADD`和`COPY`命令来说，需要对比文件的内容，并会给每一个文件计算一个hash值，最近修改时间，以及访问次数，不参与hash值的计算。查找的过程，就是对比hash值是否相同，如果不同，则cache失效。
4. 除去 `ADD`和`COPY`命令，其它的命令只会对比命令字符串本身。


## 常用的指令

### FROM

尽可能使用官方仓库最为自己的基础镜像，推荐使用[Debian image](https://hub.docker.com/_/debian/)。

### LABEL

仅可能给自己的镜像加上标签，方面管理，添加版权信息等。如下提供了一个标准的例子：

```
# Set one or more individual labels
LABEL com.example.version="0.0.1-beta"
LABEL vendor="ACME Incorporated"
LABEL com.example.release-date="2015-02-12"
LABEL com.example.version.is-production=""
```

在dockr 1.10版本之前，推荐所有的标签写入一行，以便减少镜像的文件层。新版本无需特殊的考虑，以前版本的例子：

```
# Set multiple labels on one line
LABEL com.example.version="0.0.1-beta" com.example.release-date="2015-02-12"
```

或者

```
# Set multiple labels at once, using line-continuation characters to break long lines
LABEL vendor=ACME\ Incorporated \
      com.example.is-beta= \
      com.example.is-production="" \
      com.example.version="0.0.1-beta" \
      com.example.release-date="2015-02-12"
```

### RUN

尽可能将命令写入一行，对于多行命令，使用`/`连接成一行。例如，

```
RUN apt-get update && apt-get install -y \
    aufs-tools \
    automake \
    build-essential \
    curl \
    dpkg-sig \
    libcap-dev \
    libsqlite3-dev \
    mercurial \
    reprepro \
    ruby1.9.1 \
    ruby1.9.1-dev \
    s3cmd=1.1.* \
 && rm -rf /var/lib/apt/lists/*
```

### CMD

`CMD`命令用来启动容器中的应用程序，并且可以传人一些参数。一般的使用格式`CMD [“executable”, “param1”, “param2”…]`，对于service类型的应用，比如apache和rails，使用方式 `CMD ["apache2","-DFOREGROUND"]`。

对于其他类型的应用， `CMD`应该启动一个常用的交互shell，就像bash，python以及perl。例如`CMD ["perl", "-de0"]`, `CMD ["python"]`, 或者 `CMD [“php”, “-a”]`。这样就能保证，当你运行`docker run -it python`就能进入一个可用的shell环境。除非你对 [`ENTRYPOINT`](https://docs.docker.com/engine/reference/builder/#entrypoint)命令非常的熟悉，最好不要用如下的格式`CMD [“param”, “param”]`配合 [`ENTRYPOINT`](https://docs.docker.com/engine/reference/builder/#entrypoint)使用。

### EXPOSE

`EXPOSE`命令指定了容器中应用程序监听的端口号，最好使用应用程序常用的端口号，比如 Apache web server一般使用`EXPOSE 80`，MongoDB使用`EXPOSE 27017`。

对于外部访问来说，可以使用`docker run -p 8080:80`映射到宿主机上的端口，对于容器的互连，docker也提供了环境变量的方式，比如`MYSQL_PORT_3306_TCP`。

### ENV

为了使新的软件更容易运行，可以使用`ENV`命令设置容器的环境变量，比如，`ENV PATH /usr/local/nginx/bin:$PATH` 将nginx设置到环境变量中， `CMD [“nginx”]` 可以直接运行。

也可以设置环境变量，给应用程序使用，如下：

```
ENV PG_MAJOR 9.3
ENV PG_VERSION 9.3.4
RUN curl -SL http://example.com/postgres-$PG_VERSION.tar.xz | tar -xJC /usr/src/postgress && …
ENV PATH /usr/local/postgres-$PG_MAJOR/bin:$PATH
```

### ADD／COPY

尽管`ADD`和`COPY`命令功能基本相同，仍然推荐优先使用`COPY`命令。`COPY`命令只支持基本的拷贝功能，`ADD`有一些隐式的特性，支持打包文件的解压，指定网络路径等等。

如果你需要拷贝一些文件到容器中，最好单独的拷贝，不要一次性全拷贝，比如下面的例子：

```
COPY requirements.txt /tmp/
RUN pip install --requirement /tmp/requirements.txt
COPY . /tmp/
```

如果`COPY . /tmp/`放在`run`之前，会大大的增加cache失效的可能性。

从镜像大小的角度考虑，尽量避免使用`ADD`命令获取远程的资源，可以使用`curl`或者`wget`代替。看看下面的例子：

```
ADD http://example.com/big.tar.xz /usr/src/things/
RUN tar -xJf /usr/src/things/big.tar.xz -C /usr/src/things
RUN make -C /usr/src/things all
```

替换为：

```
RUN mkdir -p /usr/src/things \
    && curl -SL http://example.com/big.tar.xz \
    | tar -xJC /usr/src/things \
    && make -C /usr/src/things all
```

### ENTRYPOINT

### VOLUME

 `VOLUME` 指令用来将需要持久化的数据容器暴露到容器外，比如数据库的数据文件，配置文件或者其它的用户创建的文件或者目录。强烈推荐使用 `VOLUME` 命令保存有状态的数据。

### USER

如果一个服务并不需要一些root权限，可以使用`USER`命令切换到非root用户。比如接下来的命令：`RUN groupadd -r postgres && useradd --no-log-init -r -g postgres postgres`。

应该避免使用`sudo`命令，`sudo`命令会带来TTY以及信号方面的问题。如果确实需要`sudo`的功能，推荐使用“gosu”。

最后一点，为了避免文件层以及复杂性，避免来回切换账号。

### WORKDIR

为了明确和清晰，尽量为工作目录指定绝对路径，不要使用相对路径。

### ONBUILD

`ONBUILD`命令会在当前的 `Dockerfile`构建完成之后执行。所有的子镜像都会执行父镜像的`ONBUILD`，然后才会构建自己的 `Dockerfile`。





