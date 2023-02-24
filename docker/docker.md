



version: 4.11.1

------

## 1. install

```shell
# docker
curl -sSL https://get.daocloud.io/docker | sh
# curl -fsSL https://get.docker.com | bash -s docker --mirror aliyun
sudo systemctl enable docker

# docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
sudo chmod 755 /usr/bin/docker-compose
# sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
# sudo chmod +x /usr/bin/docker-compose
# sudo ln -s /usr/bin/docker-compose /usr/local/bin/docker-compose

# 添加当前用户到 docker 用户组
sudo gpasswd -a $USER docker

# 更新 docker 用户组
newgrp docker

# daemon.json
sudo vim /etc/docker/daemon.json

···
{
  "debug": true,
  "experimental": false,
  "data-root": "/opt/docker/",
  "builder": {
    "gc": {
      "defaultKeepStorage": "64GB",
      "enabled": true
    }
  },
  "exec-opts": [
    "native.cgroupdriver=systemd"
  ],
  "repository-mirrors": [
    "http://docker.mirrors.ustc.edu.cn"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-file": "8",
    "max-size": "128m"
  }
}
···
```

------

## 2. dockerfile

- ##### FROM

  ```dockerfile
  FROM <image>:<tag>
  ```

- ##### USER

  ```dockerfile
  USER root
  ```

- ##### WORKDIR

  ```dockerfile
  # 为 Dockerfile 中的任何 ADD、COP`、RUN、CMD、ENTRYPOINT 指令指定工作目录。
  # 多个 WORKDIR，它相对于之前 WORKDIR 的相对路径
  WORKDIR <dir>
  ```

- ##### ADD | COPY

  ```dockerfile
  # 相同点: 文件/目录复制。对于目录而言，只复制目录内容，而不复制目录本身(只负责目录下文件)。
  # 不同点:
  #  COPY: multistage 场景(把前一阶段构建的产物拷贝到当前镜像中)。
  #  ADD: 除了 multistage 之外的 copy 所有功能，并且可以拷贝 uri 文件、解压缩文件并添加至镜像中。
  ADD <src> <dest>
  COPY <src> <dest>
  ```

- ##### ENV

  ```dockerfile
  # 指定环境变量，并在容器运行时保持
  ENV <key> <val>
  ```

- ##### VOLUME

  ```dockerfile
  VOLUME ["data"]
  ```

- ##### EXPOSE

  ```dockerfile
  EXPOSE <port> [<port> ...]
  ```

- ##### RUN | CMD | ENTRYPOINT

  ```dockerfile
  # 镜像构建时执行的命令，允许有多个。例如 apt-get install ...
  # 使用 `/bin/sh -c` 执行
  RUN <command>
  # 使用 `exec` 执行，指定其他终端，如: /bin/bash
  RUN ["executable", "param1", "param2"]
  # RUN ["/bin/bash", "-c", "pwd"]
  
  # 镜像启动时执行的命令，多个 CMD 只执行最后一个。`docker run` 命令会覆盖 CMD 参数。
  # 使用 `/bin/sh` 执行
  CMD <command>
  # 使用 `exec` 执行。推荐使用。
  CMD ["executable", "param1", "param2"]
  # 提供给 ENTRYPOINT 的默认参数
  CMD ["param1", "param2"]
  
  # 容器启动时第一执行的命令及其参数。在 RUN 之前执行。
  # 使用 `/bin/sh -c` 执行
  ENTRYPOINT <command>
  # 使用 `exec` 执行，指定其他终端，如: /bin/bash
  ENTRYPOINT ["executable", "param1", "param2"]
  ```

------

## 3. docker-compose

- ##### networks

  ```yml
  # 默认网络【自建】。[network: xxxx]
  # 自动创建，不论是否为外部网络，都将自动删除
  networks:
    default:
      name: xxxx
      
  # 默认网络【外部】。[network: xxxx]
  # 手动创建，不自动删除
  networks:
    default:
      external:
        name: xxxx
      
  # 指定网络【自建】。[network: docker-compose_xxxx]
  networks:
    xxxx:
      driver: bridge
  ```
  
- ##### environment

  ```yml
  # 时区
  environment:
    TZ: Asia/Shanghai
  ```

- ##### tty

  ```yml
  # 终端显示颜色
  tty: true
  ```

- ##### privileged

  ```yml
  # 容器内 root 用户拥有超级权限
  privileged: true
  ```

------

## 4.  repository

```shell
# 镜像拉取
docker pull repository

# 配置私有仓库地址
vim /etc/docker/daemon.json
···
{
  "insecure-registries": ["192.168.1.10:5000"]
}
···

# 保存重启
systemctl restart docker

# 创建容器
docker run -d -p 5000:5000 --name repository docker.io/repository
```

## 5. proxy

```shell
# docker pull | build
cat > /etc/docker/config.json << EOF
{
  "credsStore": "desktop",
  "stackOrchestrator": "swarm",
  "proxy": {
    "default": {
      "httpProxy": "http://127.0.0.1:33210",
      "httpsProxy": "http://127.0.0.1:33210"
    }
  }
}
EOF

# container
docker run --env HTTP_PROXY="http://127.0.0.1:33210" -env HTTPS_PROXY="http://127.0.0.1:33210" ...
```

## 6. command

```shell
# 磁盘使用率
docker system df

# 缓存清理
docker system prune --all

# latest 镜像版本
docker image inspect (image):latest | grep -i version
```
