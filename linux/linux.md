## 修改密码

```shell
sudo passwd root
```

------

## 修改主机名

```shell
sudo hostnamectl set-hostname athena
```

------

## 用户

```shell
# 添加用户
sudo useradd -G root,docker -s /bin/zsh -d /home/user -m user

# 删除用户
sudo userdel -r user
```

------

## 用户组

```shell
# 添加用户组
sudo groupadd usergroup

# 删除用户组
sudo groupdel usergroup

# 当前用户所属组
groups

# 添加用户至 root 组
sudo gpasswd -a $USER root

# 从 root 组删除用户
sudo gpasswd -d $USER root

# 更新 root 用户组
newgrp usergroup
```

------

## 添加权限

```shell
sudo vim /etc/sudoers

# 添加 sudo 权限
username ALL=(ALL:ALL) ALL

# 普通用户 sudo 免密
username ALL=(ALL) NOPASSWD:ALL
```

------

## 设置时区

```shell
sudo sh -c "apt install ntp -y && ntpd time.windows.com && timedatectl set-timezone 'Asia/Shanghai'"
```

```shell
# 方案一
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 方案二
export TZ="Asia/Shanghai"
```

------

## 静态 IP

```shell
# 查看网卡信息
ipconfig | ip addr

cp /etc/network/interfaces /etc/network/interfaces.bak
sudo vim /etc/network/interfaces

···
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address   192.168.1.x
netmask   255.255.255.0
gateway   192.168.1.1
# broadcast 172.20.10.15
···

# 重启网络
sudo systemctl restart networking

```

------

## 开启 ROOT 登陆

```shell
vim /etc/ssh/sshd_config

···
PermitRootLogin yes
···

# 
sh -c 'echo "PermitRootLogin yes" >> /etc/ssh/sshd_config'

# 取消倒计时
sed -i -s "s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/g" /etc/default/grub

update-grub2 && reboot
```

------


## 防火墙

```shell
apt install firewalld -y

# 开启服务
systemctl start firewalld

# 关闭服务
systemctl stop firewalld

# 查看状态
systemctl status firewalld

# 开机启动
systemctl enable firewalld

# 开机禁用
systemctl disable firewalld

# 开放端口
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=8080-9090/tcp --permanent

# 关闭端口
firewall-cmd --zone=public --remove-port=8080/tcp --permanent

# 查看端口列表
firewall-cmd --zone=public --list-ports
```

------

## openssl

![ssl](./.image/openssl.png)



```shell
# 完整版
# 模拟 HTTPS 厂商生产 HTTPS 证书过程，HTTPS 证书厂商一般都会有一个根证书（3、4、5），实际申请中，该操作用户不可见。通常用户只需将服务器公钥与服务器证书申请文件交给 HTTPS 厂商即可，之后 HTTPS 厂商会邮件回复一个服务器公钥证书，拿到这个服务器公钥证书与自生成的服务器私钥就可搭建 HTTPS 服务

# 1. 生成服务器私钥
openssl genrsa -out server.key 2048

# 2. 生成服务器证书申请文件
openssl req -new -key server.key -out server.csr

# 3. 生成 CA 机构私钥
openssl genrsa -out ca.key 2048

# 4. 生成 CA 机构证书请求文件
openssl req -new -key ca.key -out ca.csr

# 5. 生成 CA 机构根证书（自签名证书）
openssl x509 req -signkey ca.key -in ca.csr -out ca.crt

# 6. 生成服务器证书（公钥证书）
openssl x509 -req -CA ca.crt -CAkey ca.key -CAcreateserial -in server.csr -out server.crt
```

```shell
# 精简版
# 本地 HTTPS 测试，既是用户角色也是 HTTPS 厂商角色

# 1. 生成服务器私钥
openssl genrsa -out server.key 2048

# 2. 生成服务器证书申请文件
openssl req -nodes -noout -new -key server.key -out server.csr

# 3. 生成服务器证书
openssl x509 -req -signkey server.key -in server.csr -out server.crt -days 3650
```

```shell
# 生成本地服务器证书
openssl req -nodes -new -x509 -newkey rsa:2048 -keyout server.key -out server.crt
```

------


## dircolors

```shell
dircolors >> ~/.zshrc

vim ~/.zshrc

···
# 修改 ow=34;42 ==> ow=34
# 30: 黑色前景
# 34: 蓝色前景
# 42: 绿色背景
···

source ~/.zshrc
```

------

## vim

```shell
vim ～/.vimrc

···
syntax on
filetype on

set go=
set nocompatible
set term=builtin_ansi

set encoding=utf-8 
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,gbk,gb2312,cp936,big5,gb18030,shift-jis,euc-jp,euc-kr,latin1

set nobomb                   " 不自动设置字节序标记
set nobackup                 " 禁用备份
set noswapfile               " 禁用 swp 文件
set clipboard=unnamed        " 共享剪贴板
set fileformats=unix,dos     " 换行符
set ruler                    " 打开状态栏标尺
set cursorline               " 突出显示当前行
set syntax=on                " 语法高亮
set confirm                  " 在处理未保存或只读文件的时候，弹出确认
set ignorecase               " 搜索忽略大小写
set cmdheight=2              " 命令行高度
set background=dark          " 黑色背景
set autoread                 " 自动加载文件改动
set noautoindent             " 关闭自动缩进
set pastetoggle=<F12>        " 开关
set expandtab                " 替换 Tab
set tabstop=2                " Tab键的宽度

set showmatch                " 高亮显示匹配的括号
set matchtime=1              " 匹配括号高亮的时间

set t_Co=256                 " 颜色

colorscheme pablo

" 默认以双字节处理那些特殊字符
if v:lang =~? '^\(zh\)\|\(ja\)\|\(ko\)'
	set ambiwidth=double
endif

" 清空整页
map zz ggdG
" 开始新行
map <cr> o<esc>
" 注释该行
map / 0i# <esc>j0
" 取消注释
map \ 0xx <esc>j0
···
```

------

## ssh

```shell
apt-get install openssh-server ufw -y
ufw enable
ufw allow ssh

# ssh 密钥生成
ssh-keygen -t rsa -b 2048 -C "zhiming.sun"

# ssh 免密
ssh-copy-id -i $HOME/.ssh/id_rsa.pub user@ip

# 多密钥管理
cat > $HOME/.ssh/config << EOF
Host 192.168.0.1
  User root
  Hostname 192.168.0.1
  ServerAliveCountMax 3
  ServerAliveInterval 3600
  IdentityFile ~/.ssh/is_rsa  
  PreferredAuthentications publickey
EOF
```

```shell
# 多用户管理

## ip 匹配
cat > $HOME/.ssh/config << EOF
Host 192.168.0.1
  # Port 22
  # User root
  # Hostname 192.168.0.1
  ServerAliveCountMax 3
  ServerAliveInterval 3600
  IdentityFile ~/.ssh/is_rsa
  PreferredAuthentications publickey
EOF

## 正则匹配
cat > $HOME/.ssh/config << EOF
Host 192.168.0.*
  ServerAliveCountMax 3
  ServerAliveInterval 3600
  IdentityFile ~/.ssh/is_rsa
  PreferredAuthentications publickey
EOF
```



------

## apt

- ##### apt

  ```shell
  sudo apt update
  sudo apt upgrade -y
  sudo apt install sudo vim git zsh wget curl make htop lsof tree expect net-tools -y
  ```

- ##### debain

  ```shell
  # 备份
  sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
  
  ···
  # cqu
  http://mirrors.cqu.edu.cn
  
  # ustc
  http://mirrors.ustc.edu.cn
  
  # aliyun
  http://mirrors.aliyun.com
  
  # tsinghua
  http://mirrors.tuna.tsinghua.edu.cn
  ···
  
  ··· Debian 11
  deb http://mirrors.aliyun.com/debian/ bullseye main
  # deb-src http://mirrors.aliyun.com/debian/ bullseye main
  deb http://mirrors.aliyun.com/debian/ bullseye-updates main
  # deb-src http://mirrors.aliyun.com/debian/ bullseye-updates main
  deb http://mirrors.aliyun.com/debian/ bullseye-backports main 
  # deb-src http://mirrors.aliyun.com/debian/ bullseye-backports main 
  deb http://mirrors.aliyun.com/debian-security bullseye-security main
  # deb-src http://mirrors.aliyun.com/debian-security bullseye-security main
  ···
  
  apt update -y
  ```

------

## nfs

- ##### master

  ```shell
  apt install nfs-kernel-server -y
  
  # 设置挂载目录
  mkdir -p /data/nfs
  chmod a+w /data/nfs
  cat >> /etc/exports << EOF
  /data/nfs 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
  EOF
  
  # ro: 以只读方式挂载
  # rw: 赋予读写权限
  # sync: 同步检查
  # async: 忽略同步检查以提高速度
  # subtree_check: 验证文件路径
  # no_subtree_check: 不验证文件路径
  # no_root_squash: (危险项) 客户端 root 拥有服务端 root 权限
  
  # 启动服务
  sudo sh -c 'systemctl enable rpcbind && systemctl start rpcbind'
  sudo sh -c 'systemctl enable nfs-kernel-server && systemctl start nfs-kernel-server'
  
  # 查看
  showmount -e
  ```
  
- ##### node

  ```shell
  apt install nfs-common -y
  
  # 创建 nfs 共享目录
  sudo mkdir -p /data/nfs
  
  # 连接 nfs 服务器
  cat >> /etc/fstab << EOF
  # nfs-server
  192.168.1.10:/data/nfs /data/nfs nfs4 defaults,user,exec 0 0
  EOF
  
  #
  sudo mount -a
  
  # 启动服务
  sudo sh -c 'systemctl enable rpcbind && systemctl start rpcbind'
  
  # 查看
  df -h
  ```
  
  

------

## swap

```shell
# 临时禁用
sudo swapoff -a

# 临时启用
sudo swapon -a

# 永久禁用
sudo vim /etc/fstab
···
# /mnt/swap swap swap defaults 0 0
···
reboot

# 或
sed -ri 's/.*swap.*/# &/' /etc/fstab

# 查看分区状态
free -m
```

------

## shell

- ##### string

  - ###### trim

    ```shell
    filename=abc.tar.gz
    
    # ${filename%.*}  ==> 从最后一次出现 '.' 开始，截取左边所有字符
    # ${filename%%.*} ==> 从首次出现 '.' 开始，截取左边所有字符
    
    # ${filename#*.}  ==> 从首次出现 '.' 开始，截取右边所有字符
    # ${filename##*.} ==> 从最后一次出现 '.' 开始，截取右边所有字符
    
    # ${filename//./ } ==> 将 '.' 替换为 ' '
    
    # abc.tar
    echo "${filename%.*}"
    
    # abc
    echo "${filename%%.*}"
    
    # tar.gz
    echo "${filename#*.}"
    
    # gz
    echo "${filename##*.}"
    
    # abc tar gz
    echo ${filename//./ }
    ```

  - ###### replace

    ```shell
    # 替换相同数量的字符
    echo 'hello world' | tr ' ' '\n'
    
    # 只替换首次
    echo ${string/substring/replacement}
    
    # 全部替换
    echo ${string//substring/replacement}
    ```

  - ###### sort

    ```shell
    # 按 ASCII 正序
    echo "a c b" | tr ' ' '\n' | sort
    
    # 按 ASCII 倒叙
    echo "a c b" | tr ' ' '\n' | sort -r
    ```
    
  - ###### uniq

    ```shell
    # uniq 只能去除相邻字符串的重复，所以需要先使用 `sort` 进行排序
    
    demo="""
    a
    b
    a
    b
    """
    
    cat $demo | sort | uniq
    ```

- ##### sed

  ```shell
  # old 全字符匹配(首个)
  sed -i -s 's/old/new/' file.text
  
  # 正则匹配
  sed -i -s 's/.*old.*/new/g' file.text
  
  # g  全局替换
  # -i 用修改结果直接替换源文件内容
  # -s 字符串替换 's/old/new/g'
  ```

  ```shell
  # 在每一行后面追加一行 "New Line"
  sed -i 'a New Line' file.txt
  # 注: 追加内容时, 'a New Line' 不管 'a' 后面的 ' ' 多少, 'New Line' 都会从下一行第一个字符开始。
  #     若要在行开头添加 ' ', 使用 'a\ New Line'.
  
  # 在匹配行后面追加一行 "New Line"
  sed -i '/^nginx/a New Line' file.txt
  
  # 在匹配行前面追加一行 "New Line"
  sed -i '/^nginx/i New Line' file.txt
  
  # 在第 10 行追加 new.txt 文件内容
  sed -i '20r new.txt' file.txt
   
  # a 在匹配行后面追加一行
  # i 在匹配行前面插入一行
  # r 在匹配行后面追加文件内容
  ```

- ##### if

  ```shell
  # 判断对象是否为空
  if [ ! "$a" ]; then
    echo "a is null"
  else
    echo "a is not null"
  fi
  ```

  ```shell
  if [ -f "$filename" ]; then
    echo
  fi
  
  # -e 对象是否存在
  # -d 对象是否存在, 并且为目录
  # -f 对象是否存在, 并且为常规文件
  # -L 对象是否存在, 并且为符号链接
  # -h 对象是否存在, 并且为软链接
  # -s 对象是否存在, 并且长度不为0
  # -r 对象是否存在, 并且可读
  # -w 对象是否存在, 并且可写
  # -x 对象是否存在, 并且可执行
  # -O 对象是否存在, 并且属于当前用户
  # -G 对象是否存在, 并且属于当前用户组
  ```

- ##### read in line

  ```shell
  cat $filename | while read line; do
    echo $line
  done
  ```

- ##### read in folder

  ```shell
  
  ```

------

## nohup

```shell
# 后台启动
nohup ./script.sh > /opt/log/output.log 2>&1 &

# PID
ps aux | grep "./script.sh"
```

------

## resolv

```shell
# 查看 resolv.conf 创建者

# 查看软链接
ls -l /etc/resolv.conf

# 或查看 resolv.conf 注释
cat /etc/resolv.conf
```

- ##### systemd-resolved

  ```shell
  sudo sh -c '''
  systemctl disable --now systemd-resolved.service
  rm -rf /etc/resolv.conf
  echo "nameserver 192.168.1.1" > /etc/resolv.conf
  '''
  ```
  
- ##### NetworkManager

  ```shell
  # 清理 NetworkManager.conf
  grep -ir "\[main\]" /etc/NetworkManager
  ...
  - [main]
  ...
  
  # 修改配置
  sudo sh -c """cat > /etc/NetworkManager/conf.d/no-dns.conf << EOF
  [main]
  dns=none
  EOF
  
  systemctl restart NetworkManager.service
  
  rm -rf /etc/resolv.conf
  echo "nameserver 192.168.1.1" > /etc/resolv.conf
  """
  ```

------

## fdisk

```shell
# 查看已有分区
sudo fdisk -l

# 操作磁盘
sudo fdisk /dev/sda

# m: command help
# d: 删除磁盘分区
# n: 添加磁盘分区
# w: 保存并退出

# 格式化分区
sudo mkfs -t ext4 /dev/sda3

# 分区挂载
cat >> /etc/fstab << EOF
/dev/sda3 /mnt/sda3 ext4 defaults 0 0
EOF

reboot
```

------

## corndns

```shell
# 禁用 systemd-resolve
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

# docker
docker pull coredns/coredns:1.10.0
```

```shell
# sudo mkdir /etc/coredns
cat > /etc/coredns/start.sh << EOF
docker run -d -p 53:53/udp -v /etc/coredns/Corefile:/Corefile --name coredns --restart always  coredns/coredns:1.10.0
EOF
```

```shell
.:53 {
  hosts {
    192.168.1.1 coredns.com

    ttl 5
    fallthrough
  }

  # 未匹配的域名转发到上游 DNS 服务器
  forward . 192.168.1.1

  errors
  log stdout
  
  cache 60
  reload 3s
}
```



------

## sysctl [内核优化]

```shell
cat > /etc/sysctl.conf << EOF
# maximum number of open files/file descriptors
fs.file-max = 4194304

# use as little swap space as possible
vm.swappiness = 0

# prioritize application RAM against disk/swap cache
vm.vfs_cache_pressure = 50

# minimum free memory
vm.min_free_kbytes = 1000000

# follow mellanox best practices https://community.mellanox.com/s/article/linux-sysctl-tuning
# the following changes are recommended for improving IPv4 traffic performance by Mellanox

# disable the TCP timestamps option for better CPU utilization
net.ipv4.tcp_timestamps = 0

# enable the TCP selective acks option for better throughput
net.ipv4.tcp_sack = 1

# increase the maximum length of processor input queues
net.core.netdev_max_backlog = 250000

# increase the TCP maximum and default buffer sizes using setsockopt()
net.core.rmem_max = 4194304
net.core.wmem_max = 4194304
net.core.rmem_default = 4194304
net.core.wmem_default = 4194304
net.core.optmem_max = 4194304

# increase memory thresholds to prevent packet dropping:
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 65536 4194304

# enable low latency mode for TCP:
net.ipv4.tcp_low_latency = 1

# the following variable is used to tell the kernel how much of the socket buffer
# space should be used for TCP window size, and how much to save for an application
# buffer. A value of 1 means the socket buffer will be divided evenly between.
# TCP windows size and application.
net.ipv4.tcp_adv_win_scale = 1

# maximum number of incoming connections
net.core.somaxconn = 65535

# maximum number of packets queued
net.core.netdev_max_backlog = 10000

# queue length of completely established sockets waiting for accept
net.ipv4.tcp_max_syn_backlog = 4096

# time to wait (seconds) for FIN packet
net.ipv4.tcp_fin_timeout = 15

# disable icmp send redirects
net.ipv4.conf.all.send_redirects = 0

# disable icmp accept redirect
net.ipv4.conf.all.accept_redirects = 0

# drop packets with LSR or SSR
net.ipv4.conf.all.accept_source_route = 0

# MTU discovery, only enable when ICMP blackhole detected
net.ipv4.tcp_mtu_probing = 1

EOF

sysctl -p

# transparent_hugepage = madvise
echo madvise | sudo tee /sys/kernel/mm/transparent_hugepage/enabled

```

------


## nvidia

```shell
# 安装依赖
apt-get install linux-source linux-headers-$(uname -r) -y

# 卸载旧驱动
sudo apt autoremove nvidia

sudo systemctl stop lightdm gdm kdm

# 禁用 nouveau
sudo vim /etc/modprobe.d/blacklist.conf

···
blacklist nouveau
blacklist lbm-nouveau
options nouveau modeset=0
alias nouveau off
alias lbm-nouveau off
···

echo options nouveau modeset=0 | sudo tee -a /etc/modprobe.d/nouveau-kms.conf

sudo update-initramfs -u
reboot

# 查看禁用是否生效
lsmod | grep nouveau

# 安装 nvidia 驱动 https://www.nvidia.cn/Download/Find.aspx?lang=cn
```

```shell
# 安装 PPA 源
sudo add-apt-repository ppa:oibaf/graphics-drivers

# 更新驱动
sudo apt-get update && sudo apt-get dist-upgrade -y

sudo root
```

--------

## docker

```shell
# docker
curl -sSL https://get.daocloud.io/docker | sh
# curl -fsSL https://get.docker.com | bash -s docker --mirror aliyun
sudo systemctl enable docker

# docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
# sudo curl -L https://get.daocloud.io/docker/compose/releases/download/1.29.2/docker-compose-`uname -s`-`uname -m` -o /usr/bin/docker-compose
sudo chmod 755 /usr/bin/docker-compose

# 添加当前用户到 docker 用户组
sudo gpasswd -a $USER docker

# 更新 docker 用户组
newgrp docker

# daemon.json
cat >> /etc/docker/daemon.json << EOF
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
EOF

```

## containerd

```shell
apt install -y -qq apt-transport-https ca-certificates gnupg

# 添加 GPG 密钥
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | apt-key add -

# 添加 docker 软件源
cat > /etc/apt/sources.list.d/docker.list << EOF
deb [arch=$(dpkg --print-architecture)] https://mirrors.aliyun.com/docker-ce/linux/debian $(lsb_release -cs) stable
EOF

# apt install containerd
apt update -y && apt install -y containerd.io

# 开机启动
systemctl daemon-reload
systemctl start containerd && systemctl enable containerd
```

------

## oh-my-zsh

```shell
# sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sh -c "$(curl -fsSL https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh)"

sed -i -s "s/robbyrussell/ys/g" $HOME/.zshrc && source $HOME/.zshrc

# .zshrc
···
if [ -d $HOME/.profile.d ]; then
  for i in `ls $HOME/.profile.d | grep .sh`; do
    if [ -r $HOME/.profile.d/$i ]; then
      . $HOME/.profile.d/$i
    fi
  done
  unset i
fi

# alias
alias l="ls -lh"
alias la="ls -Alh"
alias his="history -i"

alias cs='cd $GOPATH/src'

# export
set completion-ignore-case on
export TERM=xterm-256color
export TIME_STYLE="+%Y-%m-%d %H:%M:%S"
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/go/bin:/opt/go/bin
···
```

------

## golang

```shell
wget -c https://dl.google.com/go/go1.18.9.linux-amd64.tar.gz -O - | sudo tar -xz -C /usr/local

···
export GO111MODULE="on"
export GOPATH="/opt/go"
export GOPROXY="https://goproxy.io,direct"
···

sudo mkdir -p /opt/go/bin /opt/go/pkg /opt/go/src
sudo chown $USER /opt/go/*
```

------

## nodejs

```shell
wget -c https://nodejs.org/dist/v16.5.0/node-v16.5.0-linux-x64.tar.xz
sudo tar -x -C /usr/local/ -f node-v16.5.0-linux-x64.tar.xz
rm -rf node-v16.5.0-linux-x64.tar.xz

mv /usr/local/node-v16.5.0-linux-x64 /usr/local/node
sudo ln -s /usr/local/node/bin/npm /usr/local/bin/
sudo ln -s /usr/local/node/bin/node /usr/local/bin/

# pnpm
sudo npm install -g pnpm
sudo ln -s /usr/local/node/bin/pnpm /usr/local/bin/
```

------

## python

```shell
# 依赖
sudo apt install -y wget build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev libbz2-dev

# Python3
ver=3.10.7
wget -c https://www.python.org/ftp/python/$ver/Python-$ver.tgz && tar -xvf Python-$ver.tgz
cd Python-$ver
./configure --enable-optimizations --prefix=/usr/local/python3
sudo make -j 2
sudo make altinstall

# 软链接
sudo ln -s /usr/local/python3/bin/python3.10 /usr/local/bin/python3
sudo ln -s /usr/local/python3/bin/pip3.10 /usr/local/bin/pip3

# Pip 加速
mkdir $HOME/.pip && cat > $HOME/.pip/pip.config << EOF
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
[install]
trusted-host = mirrors.aliyun.com
EOF

# 第三方依赖
black ····· 代码格式化工具
request ··· HTTP 封装
pymysql ··· 操作 MySQL

```

--------

## rust

```shell
# 安装
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 换源
vim .cargo/config.toml

···
[net]
  git-fetch-with-cli = true

[source.crates-io]
  repository = "https://github.com/rust-lang/crates.io-index"
  replace-with = 'tuna'

[source.tuna]
  repository = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
···

# 清除缓存
rm ~/.cargo/.package-cache

# 更新
rustup update

# 卸载
rustup self uninstall
```

------

## Error

```shell
# W: Possible missing firmware /lib/firmware/rtl_nic/...

···
#!/usr/bin/env zsh

firmware=(
rtl8402-1.fw
rtl8411-1.fw
rtl8411-2.fw
rtl8105e-1.fw
rtl8106e-1.fw
rtl8106e-2.fw
rtl8107e-1.fw
rtl8107e-2.fw
rtl8168d-2.fw
rtl8168d-1.fw
rtl8168e-1.fw
rtl8168e-2.fw
rtl8168e-3.fw
rtl8168f-1.fw
rtl8168f-2.fw
rtl8168g-2.fw
rtl8168g-3.fw
rtl8168h-1.fw
rtl8168h-2.fw
)

for i in $firmware; do
  sudo wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/tree/rtl_nic/$i -o /lib/firmware/rtl_nic/$i
done
···
```

------

## 100. Scripts

### > alias

```shell

```

--------

### > remote

```shell
cat >> $HOME/.zshrc << EOF
alias r="$HOME/.scripts/remote.sh"
EOF

source $HOME/.zshrc
```

```shell
#!/usr/bin/env bash

set -e

list=(
# IP User Passwd Remark Board(跳板机 "user@remote")
"192.168.1.13 root  1234 kube-node-3"

"192.168.1.10  root  1234 kube-master"
"192.168.1.11  root  1234 kube-node-1"
"192.168.1.12  root  1234 kube-node-2"
)

length=${#list[@]}

display() {
  local limit=0
  for (( i = 1; i <= $length; i++ )); do
    item=(${list[i-1]})
    ip=${item[0]}
    user=${item[1]}

    if [[ $limit -lt $[${#ip}+${#user}] ]]; then
      limit=$[${#ip}+${#user}+1]
    fi
  done

  for (( i = 1; i <= $length; i++ )); do
    item=(${list[i-1]})
    ip=${item[0]}
    user=${item[1]}
    remark=${item[3]}

    echo -e "$i. \033[32m$ip\033[0m\033[34m <$user>\033[0m \c "
    for (( j = 0; j < $[$limit-${#ip}-${#user}]; j++ )); do
      echo -n "·"
    done
    if [[ -z $remark ]]; then
      echo " $user@$ip"
    else
      echo " $remark"
    fi
  done
}

connect() {
  read -sp ">: " input

  if [[ ! "$input" =~ ^[0-9]+$ ]]; then
    echo -e "\033[31mexit\033[0m"
    exit
  fi
  if [[ "$input" -gt $length ]]; then
    echo -e "\033[31minvalid input. must be 1 - $length\033[0m"
    exit
  fi

  item=(${list[$input-1]})
  ip=${item[0]}
  user=${item[1]}
  passwd=${item[2]}
  remark=${item[3]}
  board=${item[4]}

  echo -e "\033[31m$user@$ip\033[0m"

  # sshpass
  # sshpass -p $passwd ssh $user@$ip

  # ssh-copy-id
  if [[ -n "$identity" ]]; then
    if [[ "${board}" ]]; then
      ssh -t ${board} "ssh-copy-id -i $identity $user@$ip"
    else
      ssh-copy-id -i $identity $user@$ip
    fi
  fi

  # 需要跳板机远程登陆
  if [[ "$board" ]]; then
    ssh -t $board "ssh $user@$ip"
  else
    ssh $user@$ip
  fi
}

bubbling() {
  # 去空格，方便排序
  for (( i = 0; i < ${#list[@]}; i++ )); do
    list[i]=$(echo ${list[i]} | sed -s 's/ /|/g')
  done

  list=($(echo ${list[@]} | tr ' ' '\n' | sort))

  # 添加空格
  for (( i = 0; i < ${#list[@]}; i++ )); do
    list[i]=$(echo ${list[i]} | sed -s 's/|/ /g')
  done
}

main() {
  display
  connect
}

# help
if [[ "$1" = "-h" ]]; then
  echo "Options:"
  echo "  -v    update this script"
  echo "  -l    show ssh list"
  echo "  -i    identity_file"
  exit
fi

# vim script
if [[ "$1" = "-v" ]]; then
  vim $0
  exit
fi

# show list
if [[ "$1" = "-l" ]]; then
  
  exit
fi

# ssh-copy-id
identity=""
if [[ "$1" = "-i" ]]; then
  identity=$2

  if [[ ! -f "$identity" ]]; then
    echo -e "\033[31m$identity: No such file or directory\033[0m"
    exit
  fi
fi

main

```

--------

### > docker-cleaner

```shell
cat >> $HOME/.zshrc << EOF
alias d="$HOME/.scripts/docker-cleaner.sh"
EOF

source $HOME/.zshrc
```

```shell
#!/usr/bin/env bash

# 需要删除的目标镜像名称或 ID
target=$1

# 镜像版本, 不指定时, 删除 $target 匹配到的所有镜像
version=$2

repo="docker.clean"

# 镜像名称
image_name=
# 镜像版本
image_tag=
# 镜像 ID
image_id=
# 总数
total=

docker-clean() {
  local items=

  for (( i = 0; i < $total; i++ )); do
    local name=${image_name[i]}
    local tag=${image_tag[i]}
    local id=${image_id[i]}

    # 删除容器(镜像名匹配)
    items=$(docker ps -a | grep "$name:$tag" | awk '{print $1}')
    if [[ -n $items ]]; then
      docker rm -f $items >/dev/null 2>&1
    fi
    # 删除容器(镜像ID匹配)
    items=$(docker ps -a | grep "$id" | awk '{print $1}')
    if [[ -n $(docker ps -a | grep "$id") ]]; then
      docker rm -f $items >/dev/null 2>&1
    fi

    # 删除镜像
    if [[ -n $(docker images -a | grep "$name" | grep "$tag") ]]; then
      docker rmi -f $name:$tag >/dev/null 2>&1
    fi
  done

  # 删除 <none> 镜像
  items=$(docker images | grep "<none>" | awk '{print $3}')
  if [[ -n $items ]]; then
    docker rmi -f $items >/dev/null 2>&1
  fi
}

main() {
  docker images -a | grep "$target" | grep "$version" > $repo

  image_name=($(cat $repo | awk '{print $1}'))
  image_tag=($(cat $repo | awk '{print $2}'))
  image_id=($(cat $repo | awk '{print $3}'))
  total=${#image_name[@]}

  # 删除确认
  cat $repo
  read -sp "请确认 (Y/N): " input

  if [[ $input =~ ^[yY]+$ ]]; then
    echo -e "\033[32mY\033[0m"
  else
    echo -e "\033[31mEXIT\033[0m"
    exit
  fi

  docker-clean
  rm -rf $repo
}

main

```

--------

### > auto-restart

```shell
crontab -e

# 每分钟执行
* * * * * /root/.scripts/auto-restart.sh
```

```shell
#!/usr/bin/env bash

set -e

# $HOME
homedir=/root

# 服务列表
services=(
"rpcbind.service"
"kubelet.service"
)

# 日志文件
logfile=$homedir/.auto-restart.log

cleanup() {
  if [[ ! -f "$logfile" ]]; then
    return
  fi

  local lastmonth=$(date -d "1 month ago" "+%Y-%m")
  if [[ -f "$logfile.$lastmonth" ]]; then
    return
  fi

  local month=$(date "+%Y-%m")
  if [[ -n $(cat $logfile | grep "$month") ]]; then
    return
  fi

  if [[ -n $(ls -a $homedir | grep ".auto-restart.log.") ]]; then
    rm -rf $homedir/.auto-restart.log.*
  fi

  mv $logfile $logfile.$lastmonth
}

# log cleanup
cleanup

# service health check
for srv in "${services[@]}"; do
  if [[ -z $(systemctl status $srv | grep -o 'active (running)') ]]; then
    curr=$(date "+%Y-%m-%d %H:%M:%S") && echo "$curr ==> systemctl restart $srv"  >> $logfile
    systemctl restart $srv

    if [[ -z $(systemctl status $srv | grep -o 'active (running)') ]]; then
      curr=$(date "+%Y-%m-%d %H:%M:%S") && echo "$curr ==> systemctl restart $srv failed" >> $logfile
    fi
  fi
done

```
