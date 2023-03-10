

[v1.23](https://gitee.com/moxi159753/LearningNotes/tree/master/K8S)

------

## 1. 安装

### 1. 环境准备

- ##### firewalld

  ```shell
  # 关闭防火墙
  sudo sh -c "systemctl stop firewalld && systemctl disable firewalld"
  sudo apt remove firewalld --purge -y
  ```

- ##### swap

  ```shell
  # 临时
  swapoff -a
  # 永久
  sed -ri 's/.*swap.*/#&/' /etc/fstab
  ```

- ##### hostname

  ```shell
  # 修改 hostname
  hostnamectl set-hostname xxxx
  
  # 添加 hosts
  cat >> /etc/hosts << EOF
  192.168.1.10 kube-master
  192.168.1.11 kube-node-1
  192.168.1.12 kube-node-2
  192.168.1.13 kube-node-3
  EOF
  ```

- ##### selinux

  ```shell
  # 临时关闭
  setenforce 0
  
  # 永久关闭
  sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config 
  ```

- ##### ipvs

  ```shell
  # 开启内核模块(ipvs)
  cat > /etc/modules-load.d/k8s.conf << EOF
  overlay
  br_netfilter
  ip_vs
  ip_vs_sh
  ip_vs_rr
  ip_vs_wrr
  nf_conntrack
  EOF
  
  # 调整内核参数
  cat > /etc/sysctl.d/k8s.conf << EOF
  net.ipv4.ip_forward = 1
  net.bridge.bridge-nf-call-iptables = 1
  net.bridge.bridge-nf-call-ip6tables = 1
  vm.swappiness = 0
  vm.panic_on_oom = 0
  fs.inotify.max_user_instances = 8192
  fs.inotify.max_user_watches = 1048576
  fs.file-max = 52706963
  fs.nr_open = 52706963
  net.ipv6.conf.all.disable_ipv6 = 1
  net.netfilter.nf_conntrack_max = 2310720
  EOF
  
  sysctl --system
  ```

- ##### timezone

  ```shell
  # 时间同步
  ## netdate 系统时间
  sudo sh -c "apt install ntp -y && ntpd time.windows.com && timedatectl set-timezone 'Asia/Shanghai'"
  ## hwclock 硬件时间
  sudo hwclock -w
  ```

### 2. 组件安装

- ##### debian 11

  ```shell
  # 下载 apt 依赖包
  sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl
  
  # 下载 Kubernetes 签名密钥
  curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
  
  # 添加 apt Kubernetes 源
  cat > /etc/apt/sources.list.d/kubernetes.list << EOF
  deb http://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
  EOF
  # sudo sh -c "echo 'deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main' > /etc/apt/sources.list.d/kubernetes.list"
  
  # 安装 Kubernetes
  sudo apt update && sudo apt reinstall kubeadm=1.24.00-00 kubelet=1.24.00-00 kubectl=1.24.00-00 -y
  
  # 开机启动
  sudo sh -c "systemctl enable kubelet.service && systemctl start kubelet.service"
  
  # oh-my-zsh plugins
  ...
  autoload -Uz compinit
  compinit
  
  plugins=(git kubectl)
  source <(kubectl completion zsh)
  ...
  
  ```
  
- ##### centos

  ```shell
  
  ```
  
- ##### rpm

  ```shell
  # http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/Packages/
  
  # kubeadm-1.23.16-0.x86_64.rpm
  # kubelet-1.23.16-0.x86_64.rpm
  # kubectl-1.23.16-0.x86_64.rpm
  # cri-tools-1.26.0-0.x86_64.rpm
  # kubernetes-cni-1.2.0-0.x86_64.rpm
  
  # 安装 rpm 包
  rpm -ivh *.rpm --nodeps --force
  
  # 安装依赖
  sudo apt install -y socat conntrack
  
  # 开机启动
  sudo sh -c "systemctl enable kubelet.service && systemctl start kubelet.service"
  ```


### 3. 服务启动

- #### master

  ```shell
  # 基础镜像
  kubeadm config images list
  
  # kubeadm init (k8s.gcr.io)
  # kubeadm init --apiserver-advertise-address 192.168.1.10 --kubernetes-version v1.23.9 --service-cidr=10.96.0.0/12  --pod-network-cidr=192.168.0.0/16
  
  # kubeadm init (aliyuncs)
  ip=192.168.1.10
  version=1.23.9
  repository=repository.aliyuncs.com/google_containers
  sudo kubeadm init --apiserver-advertise-address $ip --image-repository $repository --kubernetes-version $version --service-cidr=10.96.0.0/12  --pod-network-cidr=192.168.0.0/16
  
  # 创建 master 账户
  rm -rf $HOME/.kube && mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  
  # 安装网络插件
  kubectl apply -f cni-calico.yaml
  
  # 修改 "--bind-address"
  ## kube-scheduler
  sudo sh -c "sed -s -i 's/--bind-address=127.0.0.1/--bind-address=0.0.0.0/g' /etc/kubernetes/manifests/kube-scheduler.yaml"
  ## kube-controller-manager
  sudo sh -c "sed -s -i 's/--bind-address=127.0.0.1/--bind-address=0.0.0.0/g' /etc/kubernetes/manifests/kube-controller-manager.yaml"
  
  # token
  kubeadm token create --print-join-command
  # token(不过期)
  kubeadm token create --print-join-command --ttl 0
  
  # [node] kubeadm join ...
  
  # 验证
  kubectl get nodes
  ```
  
- #### node

  ```shell
  # kubeadm join ...
  ```

### 4. 网络插件

- ##### calico

  ```shell
  # kubectl apply -f https://docs.projectcalico.org/v3.23/manifests/calico.yaml
  
  # 手动拉取镜像
  docker pull docker.io/calico/cni:v3.23.2
  docker pull docker.io/calico/node:v3.23.2
  docker pull docker.io/calico/kube-controllers:v3.23.2
  
  # 修改 calico 网卡发现机制
  sed -s -i 's/- name: CLUSTER_TYPE/- name: IP_AUTODETECTION_METHOD\n              value: "interface=ens.*"\n            - name: CLUSTER_TYPE"/g' calico.yaml
  
  # 部署 CNI 网络插件
  kubectl apply -f cni-calico.yaml
  
  # 查看状态
  kubectl get pods -n kube-system
  
  # 卸载
  kubectl delete -f cni-calico.yaml
  ## master/node
  sudo sh -c 'modprobe -r ipip && rm -rf /var/lib/cni /etc/cni/net.d/* && systemctl restart kubelet.service'
  ```

- ##### flannel

  ```shell
  # kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  
  # 手动拉取镜像
  docker pull flannelcni/flannel:v0.18.1
  docker pull flannelcni/flannel-cni-plugin:v1.1.0
  
  # 部署 CNI 网络插件
  kubectl apply -f kube-flannel.yaml
  
  # 查看状态
  kubectl get pods -n kube-system
  ```

### 5. 错误信息

```shell
# 节点重置

## master
sudo sh -c "kubeadm reset && rm -rf $HOME/.kube /etc/cni/net.d/ /var/lib/cni/calico"

## node
sudo sh -c "kubeadm reset && rm -rf /etc/cni/net.d/ /var/lib/cni/calico"
```

#### 5.1 [ERROR CRI]

```shell
rm -rf /etc/containerd/config.toml && systemctl restart containerd
```

#### 5.2 [ERROR Swap]

```shell
# 未关闭虚拟内存
# 临时关闭
swapoff -a
# 永久关闭
sed -ri 's/.*swap.*/#&/' /etc/fstab
```

#### 5.3 [ERROR NumCPU]

```shell
# 错误的 CPU 核心数。最少为 2.
```

#### 5.4 [ERROR Port-10250]

```shell
# 端口被占用
kubeadm reset -f && rm -rf $HOME/.kube
```

#### 5.5 timed out

```shell
# 下载基础镜像
docker pull k8s.gcr.io/...

# 重启 docker
systemctl restart docker

# 重启 kubelet
systemctl stop kubelet
```

#### 5.6 connection refused

```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

#### 5.7 kubelet is not running

```shell

```

#### 5.8 BIRD is not ready

```shell
# 调整 calico 网络插件的网卡发现机制
```

```shell
sed -s -i 's/- name: CLUSTER_TYPE/- name: IP_AUTODETECTION_METHOD\n              value: "interface=ens.*"\n            - name: CLUSTER_TYPE"/g' calico.yaml
```

```shell
kubectl edit daemonsets -n kube-system calico-node

...
          env:
            - name: IP_AUTODETECTION_METHOD
              value: "interface=ens.*"
            - name: CLUSTER_TYPE"
              value: "k8s,bgp"
...
```

#### 5.9 coredns ContainerCreating

```shell
# 查看 cni 版本是否与 kubernetes 版本兼容

# coredns 未就绪与 cni 插件有必然联系
kubectl describe pods -n kube-system  calico-

# 删除节点上 cni 安装信息
sudo rm -rf /etc/cni/net.d/* /var/lib/cni/calico

# 重启 kubelet
sudo systemctl restart kubelet
```

#### 5.10 disk-pressure:NoSchedule

```shell
# 磁盘空间不足
```

- ###### docker

  ```shell
  # 查看 docker 状态，定位存储配置文件位置
  sudo systemctl status -l docker
  ...
  ● docker.service - Docker Application Container Engine
     Loaded: loaded (/etc/systemd/system/docker.service; enabled; vendor preset: disabled)
     Active: active (running) since Fri 2022-12-16 10:52:48 CST; 2 months 7 days ago
       Docs: https://docs.docker.com
  ...
  
  # 修改数据存储目录
  sudo vim /etc/systemd/system/docker.service
  ...
  ExecStart=/usr/bin/dockerd --graph /mnt/docker
  ...
  
  # 重启 docker
  sudo systemctl restart docker
  ```

- ###### kubelet

  ```shell
  # 查看 kubelet 状态
  sudo systemctl status -l kubelet
  ...
  ● kubelet.service - kubelet: The Kubernetes Node Agent
     Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; vendor preset: disabled)
    Drop-In: /usr/lib/systemd/system/kubelet.service.d
             └─10-kubeadm.conf
     Active: active (running) since Wed 2023-02-22 10:15:58 CST; 30min ago
       Docs: https://kubernetes.io/docs/
  ...
  
  # 查看 kubelet 服务配置
  cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf | grep EnvironmentFile
  ...
  # kubeadm init 和 kubeadm join 运行时生成的文件
  EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
  # 管理自定义参数的配置文件
  EnvironmentFile=-/etc/sysconfig/kubelet
  ...
  
  # 修改配置文件
  sudo vim /etc/sysconfig/kubelet
  ...
  KUBELET_EXTRA_ARGS=
  
  # --root-dir=/mnt/kubelet                => kubelet 数据存储目录
  # --eviction-hard=nodefs.available<5%    => 在 kubelet 相关存储不足 5% 时，开始驱逐 Pod
  # --eviction-hard=nodefs.available<10Gi  => 在 kubelet 相关存储不足 10G 时，开始驱逐 Pod
  # --eviction-hard=imagefs.available<5%   => 在容器运行时，相关存储不足 5% 时，开始驱逐 Pod
  ...
  
  # 重启 daemon-reload 与 kubelet
  sudo sh -c "systemctl daemon-reload && systemctl restart kubelet"
  ```

- ###### log

  ```shell
  # 清理相关日志
  # /var/log
  ```

#### 5.11 namespace Terminating

- ##### 强制删除

  ```shell
  name=target
  kubectl delete ns $name --force --grace-period 0
  ```

- ##### 接口删除

  ```shell
  namespace=target
  kubectl get ns $namespace -o json > $name.json
  
  # 删除 spec 与 status
  vim $namespace.json
  ...
  
  # 启动代理(需使用 nohup 后台运行，或者开启另一个 session)
  kubectl proxy
  
  # 调用接口删除 namespace
  curl -k -H "Content-Type: application/json" -X PUT --data-binary @$namespace.json http://localhost:8001/api/v1/namespaces/$namespace/finalize
  
  # 关闭代理
  # kill -9 $(ps -ux | grep "kubectl proxy" | awk '{if (NR ==1){print $2}}')
  # 或 close session
  ```

--------

## 2. 组件说明

- ##### ApiServer

  ```yaml
  # 所有服务统一入口
  ```

- ##### Scheduler

  ```yaml
  # 任务调度/分配
  ```

- ##### ControllerManager

  ```yaml
  # 维持期望副本数目
  ```

- ##### ETCD(v3)

  ```yaml
  # 键值对数据库，集群数据存储
  ```

- ##### Kubelet

  ```yaml
  # 控制容器引擎(docker、container)，实现容器的生命周期管理
  ```

- ##### Kube-Proxy

  ```yaml
  # 写入规则至 IPVS、IPTABLES，实现服务映射访问
  ```

--------

## 3. 插件说明

- ##### CoreDNS

  ```yaml
  # 可以为集群中的 service 创建一个 <域名:IP> 的对应关系体系
  ```

- ##### Dashboard

  ```yaml
  # 给 Kubernetes 集群提供 B/S 结构访问体系
  ```

- ##### IngressController

  ```yaml
  # 官方实现四层网络代理，IngressController 可以实现七层网络代理(实现域名访问)
  ```

- ##### Federation

  ```yaml
  # 提供可以跨集群、多 Kubernetes 统一管理功能
  ```

- ##### Prometheus

  ```yaml
  # Kubernetes 集群监控平台
  ```

- ##### ELK

  ```yaml
  # Kubernetes 集群日志分析平台
  ```

--------

## 4. 资源清单

```yaml
# kind: 资源类型
kind: Deployment
# apiVersion: api 版本
apiVersion: apps/v1
# metadata: 元数据
metadata:
  # name: Pod 名称
  name: nginx
  # namespace: 命名空间。不同命名空间在逻辑上相互隔离。
  #   default: 默认
  #   kube-system: kubernetes 系统组件使用
  #   kube-public:  公共资源使用(并不常用)。
  namespace: app
  # labels: 标签。与 spec.selector.matchLabels 和 spec.template.metadata.labels 保持一致
  #   key: value
  labels:
    app: nginx
    version: v1.0.0
# spec: 资源规格
spec:
  # replicas: 预定副本数量
  replicas: 3
  # restartPolicy: 重启策略
  #   Always: 默认策略。当容器终止退出后，总是重启容器。
  #   Never: 当容器终止退出，从不重启容器。
  #   OnFailure: 当容器异常退出（退出状态码非 0）时，才重启容器。
  restartPolicy: Always
  # selector: 标签选择器。与 metadata.labels 和 spec.template.metadata.labels 保持一致
  selector:
    matchLabels:
      app: nginx
      version: v1.0.0
  # template: Pod 模板
  template:
    # metadata: Pod 元数据
    metadata:
      # labels: 标签。与 metadata.labels 和 spec.selector.matchLabels 保持一致
      labels:
        app: nginx
        version: v1.0.0
    # spec: Pod 规格
    spec:
      # nodeSelector: Node 选择器
      #   key: value
      nodeSelector:
        app: "true"
      # containers: 容器配置
      containers:
      - name: nginx
        image: nginx:latest
        # imagePullPolicy: 镜像拉取策略
        #   IfNotPresent: 默认值。镜像在宿主机上不存在时才拉取。
        #   Always: 每次创建 Pod 都会重新拉取一次镜像。
        #   Never: Pod 永远不会主动拉取镜像。
        imagePullPolicy: IfNotPresent
        # ports: 端口
        ports:
        - name: http
          # hostPort: 80
          #   hostPort 与 hostNetwork 异同点
          #   相同点:
          #     本质上都是暴露 Pod 所在节点 IP 给终端用户。此外宿主机端口占用也导致不能在同一节点上部署多个程序使用同一端口，
          #     因此一般情况下不建议使用 hostPort 方式。
          #   不同点：
          #     hostNetwork: Pod 实际上使用的是所在节点的网络地址空间，即 Pod IP 是宿主机 IP，而非 CNI 分配的 Pod IP，端口是宿主机网络监听端口
          #     hostPort: Pod IP 并非宿主机 IP，而是 CNI 分配的 Pod IP，和普通的 Pod 使用一样的 IP 分配方式，端口并非宿主机网络监听端口，
          #       只是使用了 DNAT 机制将 hostPort 指定端口映射到了容器的端口之上(可通过 iptables 查看)。外部访问此 Pod时，
          #       仍然使用宿主机和 hostPort 方式
          #     另，hostNetwork 在 Pod 中是全局的，当前 Pod 上所有端口都会使用宿主机的网络地址空间；hostPort 可指定 port 使用宿主机端口映射
          containerPort: 80
        # volumeMounts: 数据卷挂载
        volumeMounts:
        # name: volumes.name
        - name: localtime
          # 容器内路径
          mountPath: /etc/localtime
        - name: config
          mountPath: /etc/nginx/conf.d/
        - name: logs
          mountPath: /var/log/nginx/
        # resources: 资源限制
        resources:
          # limits: 最大资源限制
          limits:
            cpu: 500m
            memory: 512Mi
          # requests: 最小资源限制
          ## requests 设置过大时，k8s 会预留资源，导致资源不能被其他 Pod 有效利用
          requests:
            cpu: 100m
            memory: 128Mi
        # Probe: 探针
        #
        # 支持三种检查方式
        #   exec: 执行 exec 命令，返回状态码是 0 为成功
        #   httpGet: 发送 HTTP 请求，返回 200-400 范围状态码为成功
        #   tcpSocket: 发起 TCP Socket 建立成功
        #
        # 探针类型
        #   startProbe:
        #   readinessProbe: 就绪检查。如果检查失败，会把 Pod 从 service endpoints 中剔除
        #   livenessProbe: 如果检查失败，将杀死容器，根据 Pod 的 restartPolicy 来操作
        readinessProbe:
          exec:
            command:
            - cat
            - /tmp/healthy
          # initialDelaySeconds: Pod 启动后，延迟多少秒开始探测
          initialDelaySeconds: 3
          # periodSeconds: 探针的探测周期
          periodSeconds: 3
        livenessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 3
          periodSeconds: 3
      # volumes: 数据卷
      volumes:
      # hostPath
      - name: localtime
        hostPath:
          path: /etc/localtime
          # type: hostPath 属性
          #   "": 默认配置。不进行检查
          #   File: 预先存在的文件
          #   Directory: 预先存在的路径
          #   FileOrCreate: 文件不存在则创建(0644)。所有权属 kubelet
          #   DirectoryOrCreate: 文件夹不存在则创建(0755)。所有权属 kubelet
          type: ""
      # configMap
      - name: config
        configMap:
          name: nginx.conf
      # persistentVolumeClaim
      - name: logs
        persistentVolumeClaim:
          claimName: nginx-pvc
      # persistentVolumeClaim
      - name: logs2
        persistentVolumeClaim:

```

### 1. ConfigMap

```yaml
# 存储不加密数据。多用于配置文件
# kubectl create configmap nginx.conf --from-file nginx.conf -o yaml --dry-run=client > nginx-configmap.yaml
```

```yaml
kind: ConfigMap
apiVersion: apps/v1
metadata:
  name: nginx.conf
  namespace: app
data:
  # filename: | filedata
  nginx.conf: |
    server {
      ...
    }
```

### 2. Deployment

```yaml
# 无状态应用
```

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nginx
  namespace: app
  labels:
    app: nginx
    version: v1.0.0
spec:
  replicas: 1
  restartPolicy: Always
  selector:
    matchLabels:
      app: nginx
      version: v1.0.0
  template:
    metadata:
      labels:
        app: nginx
        version: v1.0.0
    spec:
      nodeSelector:
        app: "true"
      containers:
        - name: nginx
          image: nginx:latest
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              # containerPort: Pod 定义的，容器暴露出的端口
              containerPort: 80
          volumeMounts:
            - name: localtime
              mountPath: /etc/localtime
            - name: config
              mountPath: /etc/nginx/conf.d/
          resources:
            limits:
              cpu: 500m
              memory: 512Mi
            requests:
              cpu: 100m
              memory: 128Mi
          livenessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 3
            periodSeconds: 3
      volumes:
        - name: localtime
          hostPath:
            path: /etc/localtime
        - name: config
          configMap:
            name: nginx.conf
```

### 3. Service

```yaml
# 防止 Pod 失去连接、负载均衡
```

```yaml
kind: Service
apiVersion: v1
metadata:
  name: backend
  namespace: app
  labels:
    app: backend
    version: v1.0.0
spec:
  # type: 资源类型
  #   NodePort: 外部访问使用
  #   ClusterIP: 集群内部使用
  #   LoadBalancer: 外部访问使用、公有云
  type: NodePort
  selector:
    app: backend
    version: v1.0
  ports:
  - name: http
  	# port: 集群内部访问端口
    port: 8080
    # nodePort: 集群外部访问端口
    nodePort: 8080
    # targetPort: Pod 容器内暴露端口
    targetPort: 18080
    protocol: TCP
```

```shell
# dns 解析

# 一层
# servicename
auth-srv

# 二层
# servicename.namespace
auth-srv.default

# 五层
# servicename.namespace.svc.cluster.local
# cluster.local: 指定的集群域名
auth-srv.default.svc.cloud.pre
```

### 4. Ingress

```yaml
# 向外暴露应用
# Ingress 和 Pod 关系
# 1. Pod 和 Ingress 是通过 Service 关联的
# 2. Ingress 作为统一入口，由 Service 关联一组 Pod
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - host: demo.k8s.com
    http:
      paths:
      - backend:
          service:
            name: nginx
            port:
              number: 8080
        path: /
        pathType: Prefix
```

### 5. DaemonSet

```yaml
# 守护进程。每个 node 运行一个此 Pod
```

```yaml
kind: DaemonSet
apiVersion: apps/v1
metadata:
  name: nginx
  namespace: app
  labels:
    app: nginx
    version: v1.0.0
spec:
  replicas: 1
  restartPolicy: Always
  selector:
    matchLabels:
      app: nginx
      version: v1.0.0
  template:
    metadata:
      labels:
        app: nginx
        version: v1.0.0
    spec:
      ...
```

### 6. StatefulSet

```yaml
# 有状态应用
```

```yaml
kind: StatefulSet
apiVersion: apps/v1
metadata:
  name: mysql
  namespace: app
  labels:
    app: mysql
    version: v8.0.28
spec:
  replicas: 1
  serviceName: mysql
  selector:
    matchLabels:
      app: mysql
      version: v8.0.28
  template:
    metadata:
      labels:
        app: mysql
        version: v8.0.28
    spec:
      nodeSelector:
        app: "true"
      containers:
      - name: mysql
        image: mysql:8.0.28
        imagePullPolicy: IfNotPresent
        ports:
        - name: tcp
          hostPort: 3306
          containerPort: 3306
        args:
        - --character-set-server=utf8mb4
        - --collation-server=utf8mb4_general_ci
        env:
        - name: TZ
          value: "Asia/Shanghai"
        - name: MYSQL_ROOT_PASSWORD
          value: "123456"
        volumeMounts:
        - name: localtime
          mountPath: /etc/localtime
        - name: data
          mountPath: /var/lib/mysql
        - name: config
          mountPath: "/etc/mysql/my.cnf"
          subPath: my.cnf
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 128Mi
      volumes:
      - name: localtime
        hostPath:
          path: /etc/localtime
      - name: data
        persistentVolumeClaim:
          claimName: mysql-pvc
      - name: config
        configMap:
          name: mysql-config
          items:
          - key: my.cnf
            path: my.cnf

```

### 7. StorageClass

- ##### local

  ```yaml
  kind: StorageClass
  apiVersion: storage.k8s.io/v1
  metadata:
    name: storage-local
    annotations:
    	"storageclass.kubernetes.io/is-default-class": "true"
  reclaimPolicy: Retain
  provisioner: kubernetes.io/no-provisioner
  volumeBindingMode: WaitForFirstConsumer
  ```
  
- ##### nfs

  ```yaml
  # https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner
  
  # 添加仓库源
  helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
  
  # 安装
  helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
      --set nfs.server=192.168.1.10 \
      --set nfs.path=/data/nfs
  ```

  ```yaml
  kind: StorageClass
  apiVersion: storage.k8s.io/v1
  metadata:
    name: storage-nfs
    namespace: app
    annotations:
    	"storageclass.kubernetes.io/is-default-class": "true"
  reclaimPolicy: Retain
  provisioner: example.com/external-nfs
  parameters:
    server: 192.168.1.10
    path: /data/nfs
  ```
  
- ##### juicefs

  ```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: juicefs-sc-secret
    namespace: kube-system
  type: Opaque
  stringData:
    name: "juicefs"
    metaurl: "redis://user:password.@192.168.1.10:6379/1"
    storage: "s3"
    bucket: "http://192.168.1.10:9000/juicefs"
    access-key: "minioadmin"
    secret-key: "minioadmin"
  
  ---
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: juicefs-sc
    annotations:
      "storageclass.kubernetes.io/is-default-class": "true"
  provisioner: csi.juicefs.com
  reclaimPolicy: Retain
  volumeBindingMode: WaitForFirstConsumer
  parameters:
    csi.storage.k8s.io/node-publish-secret-name: juicefs-sc-secret
    csi.storage.k8s.io/node-publish-secret-namespace: kube-system
    csi.storage.k8s.io/provisioner-secret-name: juicefs-sc-secret
    csi.storage.k8s.io/provisioner-secret-namespace: kube-system
  ```

### 8. PersistentVolume

- ##### PersistentVolume

  ```yaml
  kind: PersistentVolume
  apiVersion: v1
  metadata:
    name: mysql-pv
    namespace: app
  spec:
    # volumeMode: 存储卷模式
    volumeMode: Filesystem
    # storageClassName: 存储类别。pvc 通过相同的 storageClassName 进行绑定
    storageClassName: storage-local
    # persistentVolumeReclaimPolicy: 回收策略。即 pvc 释放卷时，pv 清理数据卷的方式。
    # pvc 释放卷是当用户删除一个 pvc 时，该 pvc 绑定的 pv 就会被释放。
    # Retain: 不自动清理，保留 volume
    # Recycle：删除数据。即 `rm -rf /volume/*`。仅 NFS、HostPath 支持
    # Delete：删除存储资源。比如删除 AWS EBS 卷。仅 AWS EBS, GCE PD, Azure Disk 和 Cinder 支持
    persistentVolumeReclaimPolicy: Retain
    # capacity存储能力
    capacity:
      storage: 1Ti
    # accessModes: 访问模式
    # ReadOnlyMany: 可读，可多个节点挂载
    # ReadWriteOnce: 可读可写，但只支持单个节点挂载
    # ReadWriteMany: 可读可写，支持多个节点挂载
    accessModes:
      - ReadWriteOnce
    # hostPath: 宿主机目录
    hostPath:
      # 节点路径
      path: /data/mysql
      type: ""
    # nodeAffinity: 节点亲和
    nodeAffinity:
      # required: 硬亲和性。约束条件必须满足
      required:
        nodeSelectorTerms:
          - matchExpressions:
              - operator: In
                key: kubernetes.io/hostname
                values:
                  - kube-node-1
  ```

- ##### PersistentVolumeClaim

  ```yaml
  kind: PersistentVolumeClaim
  apiVersion: v1
  metadata:
    name: nfs-pvc-mysql
    namespace: app
  spec:
    volumeMode: Filesystem
    storageClassName: storage-local
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 512Mi
  ```
  
- ##### StatefulSet

  ```yaml
  kind: StatefulSet
  apiVersion: apps/v1
  spec:
    template:
      spec:
        containers:
          - name: app
            ...
            volumeMounts:
              - name: data
                mountPath: /data
            ...
        volumes:
          - name: data
            persistentVolumeClaim:
              claimName: app-pvc
  ```

  ```yaml
  kind: StatefulSet
  apiVersion: apps/v1
  spec:
  template:
    spec:
      containers:
        - name: app
          ...
          volumeMounts:
            - name: data
              mountPath: /data
          ...
    volumeClaimTemplates:
      - kind: PersistentVolumeClaim
        apiVersion: v1
        metadata:
          name: data
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 100Gi
          storageClassName: local-storage
          volumeMode: Filesystem
  ```

### 9. HPA

```yaml
# Pod 横向自动扩容。根据 Pod 资源利用率，自动伸缩 Pod
```

```yaml
kind: HorizontalPodAutoscaler
apiVersion: autoscaling/v2
metadata:
  name: backend
  namespace: app
spec:
  minReplicas: 1
  maxReplicas: 10
  scaleTargetRef:
  	apiVersion: apps/v1
  	kind: Deployment
  	name: backend
  metrics:
    - type: Resource
      resource:
        name: memory
```

--------

### 10. Job/CronJob

- ##### Job

  ```yaml
  # 一次性任务
  ```

  ```yaml
  kind: Job
  apiVersion: batch/v1
  ```

- ##### CornJob

  ```yaml
  # 定时任务
  ```
  
  ```yaml
  kind: CronJob
  apiVersion: batch/v1
  ```

------

## 5. rbac

```txt
rbac:
  是 Kubernetes 集群基于角色的访问控制，实现授权决策，允许通过 Kubernetes API 动态配置策略。
  
ClusterRole:
  是一组权限的集合，但与Role不同的是，ClusterRole可以在包括所有NameSpce和集群级别的资源或非资源类型进行鉴权。
```

### apiGroups

```shell
# ""
# "apps"
# "batch"
# "autoscaling"
```

### resources

```shell
# "services"
# "endpoints"
# "pods"
# "secrets"
# "configmaps"
# "crontabs"
# "deployments"
# "jobs"
# "nodes"
# "rolebindings"
# "clusterroles"
# "daemonsets"
# "replicasets"
# "statefulsets"
# "horizontalpodautoscalers"
# "replicationcontrollers"
# "cronjobs"
```

### verbs

```shell
# "get"
# "list"
# "watch"
# "create"
# "update"
# "patch"
# "delete"
# "exec"
```

------

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: prometheus
  name: prometheus-k8s
  namespace: monitoring

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus-k8s
rules:
- apiGroups:
  - ""
  resources:
  - pods
  - services
  - endpoints
  - nodes
  - nodes/proxy
  verbs:
  - get
  - list
  - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
  
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    app.kubernetes.io/component: prometheus
  name: prometheus-k8s
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus-k8s
subjects:
- kind: ServiceAccount
  name: prometheus-k8s
  namespace: monitoring
```

## 6. [helm](https://helm.sh/zh/docs/)

```shell
1. helm: 命令行工具
2. chart: yaml 集合
3. release: 基于 chart 的部署实体，应用级别的版本控制
```

- ##### 安装

  ```shell
  # v3.9.0
  wget -c https://get.helm.sh/helm-v3.9.0-linux-amd64.tar.gz -O - | sudo tar -xz -C $HOME
  mv $HOME/linux-amd64/helm /usr/local/bin/
  
  # 添加仓库源
  # helm repo add [名称] [地址]
  # 官方。国内不好用
  helm repo add official https://brigadecore.github.io/charts
  # 阿里
  helm repo add aliyun https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
  
  # 更新仓库源
  helm repo update
  
  # 删除仓库源
  helm repo remove [名称]
  ```

- ##### 部署

  ```shell
  # 创建 Chart
  helm create [mychart]
  ## Chart.yaml: chart 属性
  ## templates: yaml 文件集合
  ## values.yaml: 全局属性。可在 templates 中引用
  
  # 安装
  helm install [别名] [mychart]
  
  # 更新
  helm upgrade [别名] [mychart]
  ```

- ##### 全局参数

  ```shell
  # values.yaml
  ···
  key: value
  ···
  
  # templates
  ···
  ## 变量
  {{ .Values.key}}
  ## 版本
  {{ .Release.Name}}
  ···
  ```

------

## 7. secret

- ##### kubernetes.io/tls

  ```yaml
  kind: Secret
  apiVersion: v1
  metadata:
    name: https
    namespace: default
  data:
    tls.crt: >-
      LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNNakNDQWRpZ0F3SUJBZ0lVV2dNMWxSaEJ6RFhqY3JwdFo1K21BWXBWQmljd0NnWUlLb1pJemowRUF3SXcKUnpFTE1Ba0dBMVVFQmhNQ1EwNHhFakFRQmdOVkJBZ1RDVU5JVDA1SFVVbE9SekVTTUJBR0ExVUVCeE1KUTBoUApUa2RSU1U1SE1SQXdEZ1lEVlFRREV3ZGphR0Z1WjJGdU1CNFhEVEl5TURrd05qQXlNak13TUZvWERUTXlNRGt3Ck16QXlNak13TUZvd1N6RUxNQWtHQTFVRUJoTUNRMDR4RWpBUUJnTlZCQWdUQ1VOSVQwNUhVVWxPUnpFU01CQUcKQTFVRUJ4TUpRMGhQVGtkUlNVNUhNUlF3RWdZRFZRUURFd3RqYUdGdVoyRnVMbU52YlRCWk1CTUdCeXFHU000OQpBZ0VHQ0NxR1NNNDlBd0VIQTBJQUJLZWVhY29ublhrMzdGcU1IQllqUTR6cCs2OVF0eE16bXdqVWc2dkxScFNLClB2ODZmQ3N3N2s5blZ1K3VCT2drTHEzYkt6bnhVR2hYT3QzRWF1bGhSOVNqZ1owd2dab3dEZ1lEVlIwUEFRSC8KQkFRREFnV2dNQk1HQTFVZEpRUU1NQW9HQ0NzR0FRVUZCd01CTUF3R0ExVWRFd0VCL3dRQ01BQXdIUVlEVlIwTwpCQllFRkw3RkIvS3FSWS9VZUtvdVNXT1p1K2dycGo4aE1COEdBMVVkSXdRWU1CYUFGTThPQ1lRR2RMNi9jcmJRCkdhTmxwaDYzZ2x0dk1DVUdBMVVkRVFRZU1CeUNDMk5vWVc1bllXNHVZMjl0Z2cwcUxtTm9ZVzVuWVc0dVkyOXQKTUFvR0NDcUdTTTQ5QkFNQ0EwZ0FNRVVDSUFub3I3SHVqUTJLTHZQSGV2Y01oakh3VjNNdzBuK2h5Rlc0TDYrOQpGRjU0QWlFQTBjWmpmc1paRlROdDBtaWU3K3Z1ZGQ0KzRDbTVKLzJoYm1QeUw4b05mS3M9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0=
    tls.key: >-
      LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1IY0NBUUVFSUFFU1NvTUk0WXh3M0hGMmlRblFicU5rQ1ZRZzlsd3VBOWlhWFd3TTJZdllvQW9HQ0NxR1NNNDkKQXdFSG9VUURRZ0FFcDU1cHlpZWRlVGZzV293Y0ZpTkRqT243cjFDM0V6T2JDTlNEcTh0R2xJbysvenA4S3pEdQpUMmRXNzY0RTZDUXVyZHNyT2ZGUWFGYzYzY1JxNldGSDFBPT0KLS0tLS1FTkQgRUMgUFJJVkFURSBLRVktLS0tLQ==
  type: kubernetes.io/tls
  
  ```

  ```yaml
  kind: Ingress
  apiVersion: networking.k8s.io/v1
  metadata:
    name: web-ingress
    namespace: default
  spec:
    tls:
      - hosts:
          - demo.k8s.com
        secretName: https
    rules:
      - host: demo.k8s.com
        http:
          paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: web
                  port:
                    number: 8080
  ```

  

- ##### Opaque

  ```yaml
  apiVersion: v1
  kind: Secret
  metadata:
    name: mysecret
  type: Opaque
  data:
    key: key
    value: value
  ```

------

## 8. volumes

### 1. hostPath

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nginx
spec:
  template:
    spec:
      containers:
        - name: nginx
          volumeMounts:
            - name: localtime
              mountPath: /etc/localtime
      volumes:
        - name: localtime
          hostPath:
            # "": 默认配置。不进行数据检查
            # File: 预先存在的文件
            # Directory: 预先存在的路径
            # FileOrCreate: 文件不存在则创建(0644)。所有权属 kubelet
            # DirectoryOrCreate: 文件夹不存在则创建(0755)。所有权属 kubelet
            type: ""
            path: /etc/localtime
```

### 2. configMap

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nginx
spec:
  template:
    spec:
      containers:
        - name: nginx
          volumeMounts:
            - name: config
              mountPath: /etc/nginx/conf.d/
      volumes:
        - name: config
          configMap:
            name: nginx.conf
```

### 3. pvc

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nginx
spec:
  template:
    spec:
      containers:
        - name: nginx
          volumeMounts:
            - name: logs
              mountPath: /var/log/nginx/
      volumes:
        - name: logs
          persistentVolumeClaim:
            claimName: pvc-nginx
```

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nginx
spec:
  template:
    spec:
      containers:
        - name: nginx
          volumeMounts:
            - name: logs
              mountPath: /var/log/nginx/
  volumeClaimTemplates:
    - metadata:
        name: logs
      spec:
        volumeMode: Filesystem
        storageClassName: storage-local
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 512Mi
```

------

## 9. Ingress

![ingress-nginx](.images/ingress-nginx.png)

```txt
目前常用的 ingress-nginx 有俩个。一个是 kubernetes 官方开源的 ingress-nginx，一个是 nginx 官方开源的 ingress-nginx。区别如下
  1. kubernetes 官方的 Controller 是采用 Go 语言开发的，集成了 Lua 实现的 OpenResty；而 nginx 官方的 Controller 是集成 nginx
  2. 俩者的 nginx 配置不同，并且俩者使用的 nginx.conf 配置模板也是不一样的。
     nginx 官方采用的俩个模板文件以 include 的方式配置 upstream；
     kubernetes 官方版本采用 Lua 动态配置 upstream，所以不需要 reload
所以，在 Pod 频繁变更的场景下，采用 kubernetes 官方版本不需要 reload，影响更小

# kubernetes ingress-nginx
https://github.com/kubernetes/ingress-nginx
```

```shell
# version=v1.6.4 && wget -O ingress-nginx.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-$version/deploy/static/provider/cloud/deploy.yaml

# 镜像搬运
# grep -E ' *image:' ingress-nginx.yaml | sed 's/ *image: //' | sort | uniq
```

- ##### internal network

  ```txt
  在内部网络中，请求先经过 ingress-nginx(pod)，通过 nginx.conf 转发到相应的业务 service，再通过 service 请求 pod. (ingress-nginx(svc) 不参与请求处理)
  
  request => ingress-nginx(pod) => service => pod
  ```

  ```shell
  # 需暴露 ingress-nginx-controller 端口，并修改 service 代理方式、修改更新策略为 Recreate。
  if [[ ! $(cat ingress-nginx.yaml | grep "hostPort: 80") ]]; then sed -i '/containerPort: 80/a\          hostPort: 80' ingress-nginx.yaml; fi
  
  if [[ ! $(cat ingress-nginx.yaml | grep "hostPort: 443") ]]; then sed -i '/containerPort: 443/a\          hostPort: 443' ingress-nginx.yaml; fi
  
  # 修改 Service 代理方式
  sed -i -s 's/LoadBalancer/ClusterIP/' ingress-nginx.yaml
  
  # 因使用 hostPort 网络，nginx 重启时会因端口占用而处于 Pending 状态，需要修改更新策略为 Recreate
  sed -i '/minReadySeconds:/i\  strategy:\n    type: Recreate' ingress-nginx.yaml
  
  ...
  apiVersion: apps/v1
  kind: Deployment
  spec:
    strategy:
      type: Recreate
  ...
  ```

- ##### external network

  ```txt
  在外部网络中，用户通过外网域名，先经过第三方 DNS 服务器，将请求转发给 ingress-nginx(svc)，ingress-nginx(svc) 将请求分发给 ingress-nginx(pod)，再通过 nginx.conf 转发给业务 service，service 再请求 pod
  
  request => 第三方 DNS 服务器 => ingress-nginx(svc) => ingress-nginx(pod) => service => pod
  ```

```shell
# 修改资源限制
sed -i -s 's/90Mi/128Mi/' ingress-nginx.yaml
```

------

- ##### ConfigMap

  ```
  https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/
  ```

  ```yaml
  apiVersion: v1
  kind: ConfigMap
  data:
    ...
  metadata:
    name: ingress-nginx-controller
    namespace: ingress-nginx
  ```

- ##### Annotations

  ```
  https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/
  ```

  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: nginx
    namespace: default
    annotations:
      # kubernetes.io/ingress.class: "nginx"                  # 等同于 ingressClassName: nginx
      nginx.ingress.kubernetes.io/enable-cors: "true"
      nginx.ingress.kubernetes.io/proxy-body-size: 1M         # default: 1M
      nginx.ingress.kubernetes.io/proxy-connect-timeout: '30' # 秒
      nginx.ingress.kubernetes.io/proxy-read-timeout: '30'    # 秒
      nginx.ingress.kubernetes.io/proxy-send-timeout: '03'    # 秒
  spec:
    ingressClassName: nginx
    rules:
    - host: demo.k8s.com
      http:
        paths:
        - backend:
            service:
              name: nginx
              port:
                number: 8080
          path: /
          pathType: Prefix
  ```

------

## 10. [Prometheus](./prometheus/README.md)

------

## 11. [KubeSphere](./kubesphere/README.md)

------

## 12. kubectl-command

------

- ##### namespace

  ```shell
  # 创建 namespace
  kubectl create namespace app
  # 配置首选 namespace
  kubectl config set-context --current --namespace=app
  ```
  
- ##### label

  ```shell
  # 查看节点标签
  kubectl get nodes --show-labels
  # 添加节点标签
  kubectl label nodes <node-name> <label-key>=<label-value>
  # 删除标签
  kubectl label nodes <node-name> <label-key>-
  ```

- ##### master:NoSchedule

  ```shell
  # 查看 master 节点
  kubectl describe nodes kube-master
  # 去除污点
  kubectl taint nodes kube-master node-role.kubernetes.io/master:NoSchedule-
  ```

------

### 1. 子命令

| 命令          | 语法                                                     | 说明                              |
| ------------- | -------------------------------------------------------- | --------------------------------- |
| annotate      | kubectl annotate (-f filename \| type name) k1=v1, k2=v2 | 添加或更新资源注解                |
| api-version   | kubectl api-version [--flags]                            | 列出当前版本支持的 api 版本列表   |
| api-resources | kubectl api-resources[--flags]                           | 列出当前版本支持的 api 资源列表   |
| apply         | kubectl apply -f filename [--flags]                      | 从配置文件或 Stdin 中进行资源配置 |
| attach        | kubectl attach type/name -c container [--flags]          | 附着到一个正在运行的容器上        |
| auth          | kubectl auth [--flags] [options]                         | 检测 rbac 权限设置                |
| autoscale     | kubectl autoscale                                        |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |
|               |                                                          |                                   |

--------

### 2. 常用命令

| 命令    | 说明                                           | 示例                                                         |
| ------- | ---------------------------------------------- | ------------------------------------------------------------ |
| apply   | 通过文件名或标准输入，配置资源                 | kubectl apply -f app.yaml                                    |
| create  | 通过文件名或者标准输入创建资源                 | kubectl create deployment app --image=nginx:alpine -o yaml --dry-run=client > app.yaml |
| delete  | 通过文件名、标准输入、资源名称或标签来删除资源 | kubectl delete -f app.yaml                                   |
| edit    | 使用默认的编辑器编辑资源                       |                                                              |
| expose  | 将一个资源公开为一个新的 Service。             | kubectl expose deployment app --port=8080 --type=NodePort --target-port=8080 --name=app -o yaml > app.service.yaml |
| explain | 文档参考资料                                   | kubectl explain Deployment.apiVersion                        |
| get     | 显示一个或多个资源                             | kubectl get pods,svc                                         |
| run     | 在集群中运行一个特定的镜像                     | kubectl run --image nginx:latest                             |
| set     | 在对象上设置特定的功能                         | kubectl set image deployment app nginx=nginx:latest (镜像版本升级) |
| exec    | 在容器内执行命令                               | kubectl exec nginx --bash -c "echo" (执行命令)<br />kubectl exec nginx -it -- bash      (进入容器) |

------

### 3. 镜像管理

  | 说明     | 示例                                                  |
  | -------- | ----------------------------------------------------- |
  | 版本历史 | kubectl rollout history deployment app                |
  | 镜像升级 | kubectl set image deployment app nginx=nginx:latest   |
  | 镜像回退 | kubectl rollout undo deployment app [--to-revision=x] |
  | 升级状态 | kubectl rollout status deployment app                 |

------

### 4. 集群管理

|      |      |      |
| ---- | ---- | ---- |
|      |      |      |
|      |      |      |
|      |      |      |
|      |      |      |

------

### 5. 资源类型

| 类型                    | 缩写   |         版本         | 说明                                                         |
| ----------------------- | ------ | :------------------: | ------------------------------------------------------------ |
| ComponentStatus         | cs     |          v1          | 组件状态                                                     |
| ConfigMap               | cm     |          v1          | ConfigMap 是用来存储配置文件的资源对象                       |
| DaemonSet               | ds     |       apps/v1        | DaemonSet 只管理 Pod 对象，通过 nodeAffinity 和 Toleration 两个调度器，确保每个节点上只有一个 Pod。集群中动态加入了新的 node，DaemonSet 中的 Pod 也会添加在新加入的 node 上。删除一个 DaemonSet 也会级联删除所有其创建的 Podcast |
| Deployment              | deploy |       apps/v1        | Deployment 为 Pod 和 ReplicaSet 提供了一个声明式定义方法，用来替代以前的 ReplicationController 来方便管理应用 |
| Endpoints               | ep     |          v1          | 节点                                                         |
| Event                   | ev     |          v1          | Events 是 Kubelet 中用来记录多个容器运行过程中的事件，命名规则由被记录的对象和时间戳构成 |
| HorizontalPodAutoscaler | hpa    |    autoscaling/v2    |                                                              |
| Ingress                 | ing    | networking.k8s.io/v1 |                                                              |
| Job                     |        |       batch/v1       |                                                              |
| LimitRange              | limits |          v1          |                                                              |
| Namespace               | ns     |          v1          | 命名空间                                                     |
| NetworkPolicy           |        | networking.k8s.io/v1 |                                                              |
| StatefulSet             |        |       apps/v1        |                                                              |
| PersistentVolume        | pv     |          v1          |                                                              |
| PersistentVolumeClaim   | pvc    |          v1          |                                                              |
| Pod                     | po     |          v1          |                                                              |
| PodSecurityPolicy       | psp    |    policy/v1beta1    |                                                              |
| PodTemplate             |        |          v1          |                                                              |
| ReplicaSet              | rs     |       apps/v1        |                                                              |
| ReplicationController   | rc     |          v1          |                                                              |
| ResourceQuota           | quota  |          v1          |                                                              |
| CronJob                 |        |       batch/v1       | 定时任务                                                     |
| Secret                  |        |          v1          | 证书                                                         |
| Service                 | svc    |          v1          |                                                              |
| StorageClass            | sc     |  storage.k8s.io/v1   | 存储类                                                       |

--------

## 13. 问题排查

```shell
# 查看 kubelet 日志
journalctl -xeu kubelet

# 查看 cni 日志
journalctl -xeu kubelet | grep cni
```

### 1: node-NotReady

- ##### master

  ```shell
  # 查看 node 日志
  kubectl describe nodes <node>
  ```

- ##### node

  ```shell
  # 查看 kubelet 状态
  systemctl status kubelet
  ```

### 2: CNI failed ...

```shell
# 查看 CNI 查看状态
kubectl get pods -n kube-system

# 查看 cni 日志
journalctl -xeu kubelet | grep cni
```

### 3: NodePort 无法访问

```shell
# 查看 service 是否绑定 pod
kubectl get endpoints <svc>

# 注意 selector 一致
```

### 4: Pod 互不连通

```shell
# 查看 kube-proxy 模式
kubectl get configmaps -n kube-system kube-proxy -o yaml | grep mode

# 使用 ipvs 模式
## mode: "" => mode: "ipvs"
kubectl edit -n kube-system configmaps kube-proxy

# 重启 kube-proxy
kubectl delete -n kube-system pods $(kubectl get pods -n kube-system | grep kube-proxy | awk '{print $1}')
```

------

## 99. scripts

- ##### super-kubectl

  ```shell
  # kubectl apply ...
  kk -a [folder|files]
  
  # kubectl delete ...
  kk -d [folder|files]
  ```

  ```shell
  cat > $HOME/.super-kuberctl.sh << EOF
  #!/bin/bash
  
  set -e
  
  command="apply"
  
  recursive() {
    local base=$1
    if [[ "${base##*.}" = "yaml" ]]; then
      kubectl $command -f $base
    elif [[ -d "$base" ]]; then
      local subs=($(ls $base))
      for sub in "${subs[@]}"; do
        recursive $base/$sub
      done
    fi
  }
  
  if [[ $1 = "-d" ]]; then
    command = "delete"
  fi
  
  for arg in $@; do
    recursive $arg
  done
  EOF
  
  chmod +x $HOME/.kubectl.sh
  
  cat >> $HOME/.zshrc << EOF
  alias kk="$HOME/.super-kuberctl.sh"
  EOF
  
  source $HOME/.zshrc
  ```

  
