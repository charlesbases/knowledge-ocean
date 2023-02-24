#!/usr/bin/env bash

set -e

# 查看 kubernetes 镜像列表
# sudo kubeadm config images list

repository="10.64.21.107:83"

main() {
  ls | grep ".yaml" | while read file; do
    cat $file | grep "image: " | sed -s 's/.*image: //g' | sed -s 's/"//g' | sed -s "s/'//g" >> image.txt
  done

  exit
  cat $images | while read image; do
    if [[ ! $image == \#* ]]; then
      echo -e "\033[32mdocker pull $image ...\033[0m"

      local tag=${image##*:}
      local image=${image%:*}
      local private=$repository/${image##*/}

      if [[ $(docker images | grep "$private" | grep "$tag") ]]; then
        continue
      fi

      if [[ $(docker images | grep "$image" | grep "$tag") ]]; then
        docker tag $image:$tag $private:$tag
        repo "$private:$tag"
        continue
      fi

      # docker pull
      docker pull $image:$tag

      # docker tag
      docker tag $image:$tag $private:$tag

      repo "$private:$tag"
    fi
  done
}

push() {
  if [[ $repository ]]; then
    cat "image.txt" | while read image; do
      docker push $repository/$image
    done
  fi
}

clean() {
  cat "image.txt" | while read image; do
    docker rmi -f $(docker images | grep $image | awk '{if (NR==1){print $3}}')
  done
}

case $1 in
  push)
  push
  ;;
  clean)
  clean
  ;;
  *)
  main
  ;;
esac
