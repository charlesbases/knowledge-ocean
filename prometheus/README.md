# Prometheus

[GitHub](https://github.com/prometheus-operator/kube-prometheus) [中文文档](https://www.prometheus.wang/quickstart/) [英文文档](https://prometheus.io/docs/introduction/overview/)

------

## 1. 架构

![architecture](.images/architecture.png)

## 2. 安装

![compatibility](.images/compatibility.png)

------

### 2.1 源码下载

```shell
version=release-0.11 && git clone -b $version https://github.com/prometheus-operator/kube-prometheus.git
```

------

### 2.2 镜像整理

```shell
cd kube-prometheus/manifests
vim bash.sh
...
chmod +x bash.sh

# 脚本说明
./bash.sh       # 镜像梳理并改成私有仓库地址
./bash.sh push  # 镜像推送至私有仓库
./bash.sh save  # 镜像保存至本地
./bash.sh tidy  # yaml 文件整理
./bash.sh apply # kubectl 部署
```

```shell
#!/usr/bin/env bash

repository="10.64.21.107:83"

# 统计镜像
collecting() {
  ls $1 | while read file; do
    if [[ -d $file ]]; then
      collecting $1/$file
    else
      if [[ ${file##*.} = "yaml" ]]; then
        cat $1/$file | grep "image: " | sed -s "s/.*image: //g" >> image.bak
        cat $1/$file | grep "prometheus-config-reloader=" | sed -s "s/.*prometheus-config-reloader=//g" >> image.bak
      fi
    fi
  done
}

# 镜像推送
push() {
  cat "images.txt" | while read image; do
    docker push $repository/$image
  done
}

# 镜像打包
save() {
  if [[ ! -d images ]]; then
    mkdir images
  fi

  cat "images.txt" | while read image; do
    if [[ $repository ]]; then
      image=$repository/$image
    fi

    filename=${image##*/}
    filename=${filename//:/_}

    docker save -o ./images/$filename.tar $image
  done
}

# yaml 整理
tidy() {
  dirs=(
    "alertmanager"
    "node-exporter"
    "blackbox-exporter"
    "kube-state-metrics"
    "prometheus-adapter"
    "grafana"
    "operator"
    "prometheus"
    "serviceMonitor"
  )

  for item in ${dirs[@]}; do
    if [[ ! -d $item ]]; then
      mkdir $item
    fi

    ls | grep ".yaml" | grep $item | while read file; do
      mv $file $item
    done
  done
}

# kubectl 部署
apply() {
  # setup(operator)
  if [[ ! -f setup/setup.lock ]]; then
    kubectl apply -f setup
    echo > setup/setup.lock
  else
    echo -e "\033[33mingore setup.\033[0m\c\n"
  fi

  # prometheus
  ls | grep -v "setup" | while read dir; do
    if [[ -d $dir ]] && [[ $(ls $dir) ]]; then
      kubectl apply -f $dir
    fi
  done
}

#  删除本地镜像
delete() {
  # prometheus
  ls | grep -v "setup" | while read dir; do
    if [[ -d $dir ]]; then
      kubectl delete -f $dir
    fi
  done
}

# 
main() {
  collecting .

  # 镜像去重
  cat image.bak | sort | uniq > images.txt && rm -f image.bak

  # 镜像下载
  cat images.txt | while read image; do
    docker pull $image
    if [[ $repository ]]; then
      docker tag $image $repository/$image
    fi
  done

  echo
  if [[ $repository ]]; then
    echo -e "\033[36mComplete! Please replace the mirror repository to '$repository'.\033[0m\c"
  else
    echo -e "\033[36mComplete!.\033[0m\c"
  fi
  echo
}

case $1 in
  push)
  push
  ;;
  save)
  save
  ;;
  tidy)
  tidy
  ;;
  apply)
  apply
  ;;
  delete)
  delete
  ;;
  *)
  main
  ;;
esac

```

------

### 2.3 程序部署

```shell
# 若已部署 Kubesphere，请跳转至 '2.4.2'，在 Kubesphere 中集成 Prometheus，防止冲突。
```

------

#### 2.3.1 修改 yaml

##### 1. (pvc) grafana-deployment.yaml

```yaml
kind: StatefulSet
apiVersion: apps/v1
...
          volumeMounts:
            - mountPath: /var/lib/grafana
              name: grafana-storage
...
      volumes:
-       - emptyDir: {}
-         name: grafana-storage
...
  volumeClaimTemplates:
    - kind: PersistentVolumeClaim
      apiVersion: v1
      metadata:
        name: grafana-storage
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 100Gi
        storageClassName: juicefs-sc
        volumeMode: Filesystem
  serviceName: grafana
```

##### 2. (pvc) prometheus-prometheus.yaml

```yaml
  version: 2.29.1
  storage:
    volumeClaimTemplate:
      spec:
        storageClassName: juicefs-sc
        resources:
          requests:
            storage: 100Gi
```

##### 3. (ing) prometheus-ingress.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  namespace: monitoring
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: alert.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: alertmanager-main
            port:
              number: 9093
  - host: grafana.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 3000
  - host: prom.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-k8s
            port:
              number: 9090
```

##### 4. (rabc) prometheus-clusterRole.yaml

```yaml
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
  - nodes/metrics
  verbs:
  - get
  - list
  - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
```



------

#### 2.3.2 部署清单

```shell
# 详见 2.2 镜像整理
./bash.sh apply

# 主要组件
kubectl apply -f setup(operator)
kubectl apply -f prometheus
kubectl apply -f node-exporter
kubectl apply -f kube-state-metrics
```

```shell
# 将 Prometheus 规则评估间隔设置为 1m，与 KubeSphere 3.3.0 的自定义 ServiceMonitor 保持一致。规则评估间隔应大于或等于抓取间隔

kubectl -n monitoring patch prometheus k8s --patch '{
  "spec": {
    "evaluationInterval": "1m"
  }
}' --type=merge
```

------

#### 2.3.3 错误整理

##### 1. (wan) watchdog

```
watchdog 是一个正常的报警，这个告警的作用是：如果 alermanger 或者 prometheus 本身挂掉了就发不出告警了，因此一般会采用另一个监控来监控 prometheus，或者自定义一个持续不断的告警通知，哪一天这个告警通知不发了，说明监控出现问题了。prometheus operator 已经考虑了这一点，本身携带一个 watchdog，作为对自身的监控。
```

```yaml
# kube-prometheus-prometheusRule.yaml

...
    - alert: Watchdog
      annotations:
        description: |
          This is an alert meant to ensure that the entire alerting pipeline is functional.
          This alert is always firing, therefore it should always be firing in Alertmanager
          and always fire against a receiver. There are integrations with various notification
          mechanisms that send a notification when this alert is not firing. For example the
          "DeadMansSnitch" integration in PagerDuty.
        runbook_url: https://runbooks.prometheus-operator.dev/runbooks/general/watchdog
        summary: An alert that should always be firing to certify that Alertmanager is working properly.
      expr: vector(1)
      labels:
        severity: none
...
```

##### 2. (err) connection refused

- ###### [10257] kube-controller-manager

  ```shell
  file=/etc/kubernetes/manifests/kube-controller-manager.yaml
  sudo sh -c "sed -s -i 's/--bind-address=127.0.0.1/--bind-address=0.0.0.0/g' $file"
  ```

- ###### [10259] kube-scheduler

  ```shell
  file=/etc/kubernetes/manifests/kube-scheduler.yaml
  sudo sh -c "sed -s -i 's/--bind-address=127.0.0.1/--bind-address=0.0.0.0/g' $file"
  ```

##### 3. (err) 403

- ##### kubelet

##### others

- ##### serviceMonitor 绑定不了 service

  ```shell
  # serviceMonitor 可绑定任意 namespace 下匹配 labels 的 service，如需指定 namespace，可通过 namespaceSelector 配置
  
  ...
    namespaceSelector:
      matchNames:
      - my-namespace
  ....
  ```

  

------

### 2.4 Kubesphere

#### 2.4.1 未安装 Kubesphere

##### 1. 部署 Prometheus

```shell
# 详见 2.3 程序部署
./bash apply
```

##### 2. 集成 Kubesphere

```shell
vim cluster-configuration.yaml

...
    monitoring:
      endpoint: http://prometheus-operated.monitoring.svc:9090
...
```

------

#### 2.4.2 已安装 Kubesphere

```shell
# v3.3
# https://kubesphere.io/zh/docs/v3.3/faq/observability/byop/
```

##### 1. 卸载 kubesphere-prometheus

- ###### alertmanager

  ```shell
  kubectl -n kubesphere-system exec $(kubectl get pod -n kubesphere-system -l app=ks-installer -o jsonpath='{.items[0].metadata.name}') -- kubectl delete -f /kubesphere/kubesphere/prometheus/alertmanager/ 2>/dev/null
  ```

- ###### grafana

  ```shell
  kubectl -n kubesphere-system exec $(kubectl get pod -n kubesphere-system -l app=ks-installer -o jsonpath='{.items[0].metadata.name}') -- kubectl delete -f /kubesphere/kubesphere/prometheus/grafana/ 2>/dev/null
  ```

- ###### devops

  ```shell
  kubectl -n kubesphere-system exec $(kubectl get pod -n kubesphere-system -l app=ks-installer -o jsonpath='{.items[0].metadata.name}') -- kubectl delete -f /kubesphere/kubesphere/prometheus/devops/ 2>/dev/null
  ```

- ###### etcd

  ```shell
  kubectl -n kubesphere-system exec $(kubectl get pod -n kubesphere-system -l app=ks-installer -o jsonpath='{.items[0].metadata.name}') -- kubectl delete -f /kubesphere/kubesphere/prometheus/etcd/ 2>/dev/null
  ```

- ###### upgrade

  ```shell
  kubectl -n kubesphere-system exec $(kubectl get pod -n kubesphere-system -l app=ks-installer -o jsonpath='{.items[0].metadata.name}') -- kubectl delete -f /kubesphere/kubesphere/prometheus/upgrade/ 2>/dev/null
  ```

- ###### operator

  ```shell
  kubectl -n kubesphere-system exec $(kubectl get pod -n kubesphere-system -l app=ks-installer -o jsonpath='{.items[0].metadata.name}') -- kubectl delete -f /kubesphere/kubesphere/prometheus/prometheus-operator/ 2>/dev/null
  
  kebuctl -n kubesphere-monitoring-system delete svc prometheus-operated 2>/dev/null
  ```

- ###### kube-state-metrics

  ```shell
  kubectl -n kubesphere-system exec $(kubectl get pod -n kubesphere-system -l app=ks-installer -o jsonpath='{.items[0].metadata.name}') -- kubectl delete -f /kubesphere/kubesphere/prometheus/kube-state-metrics/ 2>/dev/null
  ```

- ###### node-exporter

  ```shell
  kubectl -n kubesphere-system exec $(kubectl get pod -n kubesphere-system -l app=ks-installer -o jsonpath='{.items[0].metadata.name}') -- kubectl delete -f /kubesphere/kubesphere/prometheus/node-exporter/ 2>/dev/null
  ```

- ###### prometheus

  ```shell
  kubectl -n kubesphere-system exec $(kubectl get pod -n kubesphere-system -l app=ks-installer -o jsonpath='{.items[0].metadata.name}') -- kubectl delete -f /kubesphere/kubesphere/prometheus/prometheus/ 2>/dev/null
  ```

- ###### pvc

  ```shell
  kubectl -n kubesphere-monitoring-system delete pvc $(kubectl -n kubesphere-monitoring-system get pvc | grep -v VOLUME | awk '{print$1}' | tr '\n' ' ')
  ```

##### 2. 部署 Prometheus

- ##### 官网安装

  ```shell
  # 详见 2.3 程序部署
  ./bash apply
  ```

- ##### Kubesphere 安装

  ```shell
  # v3.3
  git clone -b release-3.3 https://github.com/kubesphere/ks-installer.git && cd ks-installer/roles/ks-monitor/files/prometheus
  
  # 创建 kustomization.yaml
  cat > kustomization.yaml << EOF
  kind: Kustomization
  apiVersion: kustomize.config.k8s.io/v1beta1
  namespace: monitoring
  resources:
  EOF
  
  find . -mindepth 2 -name "*.yaml" -type f -print | sed 's/^/- /' >> kustomization.yaml
  
  # (可选) 移除不必要的组件
  sed -i '/grafana\//d' kustomization.yaml
  
  # 部署
  kubectl apply -k .
  ```

##### 3. 集成 Prometheus

```shell
kubectl edit cm -n kubesphere-system kubesphere-config

...
    monitoring:
      endpoint: http://prometheus-operated.monitoring.svc:9090
...
```

------

## 3. Monitor

### 3.1 kubelet

### 3.2 kube-apiserver

### 3.3 kube-scheduler

### 3.4 kube-controller-manager

### 3.5 calico

```shell
# 修改 felix 配置
kubectl edit felixconfigurations

...
spec:
  prometheusMetricsEnabled: true
...

# 开放 daemonset/calico-node 端口
kubectl get -n kube-system daemonsets calico-node -o yaml | sed '/^        name: calico-node/a\        ports:\n        - name: http-metrics\n          hostPort: 9091\n          containerPort: 9091' | kubectl apply -f -

...
spec:
  template:
    spec:
      containers:
      - name: calico-node
        ports:
        - name: http-metrics
          hostPort: 9091  
          containerPort: 9091                 
...
```

```yaml
# calico-podMonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  labels:
    k8s-app: calico-node
  name: calico
  namespace: monitoring
spec:
  namespaceSelector:
    matchNames:
    - kube-system
  podMetricsEndpoints:
  - interval: 15s
    path: /metrics
    port: http-metrics
  selector:
    matchLabels:
      k8s-app: calico-node
```

### 3.6 ingress

```shell
# metrics
kubectl get -n ingress-nginx deployments ingress-nginx-controller -o yaml | sed '/creationTimestamp/i\    prometheus.io/scrape: "true"\n    prometheus.io/port: "10254"' | sed '/ports:/a\        - name: metrics\n          containerPort: 10254' | kubectl apply -f -

# service
cat > ingress-nginx-metrics.yaml << EOF

EOF

kubectl get -n ingress-nginx svc ingress-nginx-controller -o yaml | sed '/creationTimestamp/i\    prometheus.io/scrape: "true"\n    prometheus.io/port: "10254"' | sed '/ports:/a\  - name: metrics\n    port: 10254\n    targetPort: metrics' | kubectl apply -f -
```

```shell
# 日志查看
kubectl logs -n ingress-nginx $(kubectl get -n ingress-nginx pods | grep ingress-nginx-controller | awk '{print $1}')

# 查看标签
kubectl get -n ingress-nginx svc ingress-nginx-controller -o yaml
```

```yaml
---
kind: Service
apiVersion: v1
metadata:
  name: ingress-nginx-metrics
  namespace: ingress-nginx
  labels:
    k8s-app: ingress-nginx
spec:
  ports:
    - name: metrics
      protocol: TCP
      port: 10254
      targetPort: metrics
  selector:
    app.kubernetes.io/component: controller
  type: ClusterIP
  
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app.kubernetes.io/name: ingress-nginx
  name: ingress-nginx
  namespace: monitoring
spec:
  endpoints:
  - interval: 30s
    port: metrics
    path: /metrics
  namespaceSelector:
    matchNames:
    - ingress-nginx
  selector:
    matchLabels:
      k8s-app: ingress-nginx
```

------

## 4. Exporter

