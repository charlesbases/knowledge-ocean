[GitHub](https://github.com/kubesphere/kubesphere)

------

------

## 1. 安装

- ##### minimal

  ```shell
  # https://kubesphere.io/zh/docs/v3.3/quick-start/minimal-kubesphere-on-k8s/
  ```

- ##### offline

  ```shell
  # https://kubesphere.io/zh/docs/v3.3/installing-on-kubernetes/on-prem-kubernetes/install-ks-on-linux-airgapped/
  ```

------

```shell
version=v3.3.2

# yaml
wget https://github.com/kubesphere/ks-installer/releases/download/$version/kubesphere-installer.yaml
wget https://github.com/kubesphere/ks-installer/releases/download/$version/cluster-configuration.yaml

# images list
wget -O images.txt https://github.com/kubesphere/ks-installer/releases/download/$version/images-list.txt

# installation-tool.sh
wget -O installation.sh https://github.com/kubesphere/ks-installer/releases/download/v3.3.1/offline-installation-tool.sh
```

```shell
# kubesphere 相关镜像地址为 ${repository}/kubesphere/*
```

## 99. Error

- ##### node_exportes: 9100 address already in use

  ```shell
  # 方法一: 修改 kubesphere-configuration.yaml
  ···
      node_exporter:
        port: 9100
  ···
  
  # 方法二: 修改 Kubernetes 资源
  kubectl edit -n kubesphere-monitoring-system ds node-exporter
  kubectl edit -n kubesphere-monitoring-system svc node-exporter
  ```

  

