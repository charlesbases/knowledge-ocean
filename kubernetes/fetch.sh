#!/usr/bin/env bash

set -e

nginxIngressVersion=v1.5.1
calicoVersion=v3.23

plugins=(
# nginx-ingress
"https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/cloud/deploy.yaml nginx-ingress.yaml"
# cni-calico
"https://docs.projectcalico.org/v3.23/manifests/calico.yaml calico.yaml"

)

for (( i = 0; i < ${#plugins[@]}; i++ )); do
  args=(${plugins[i]})

  wget -O ${args[1]} ${args[0]}
done
