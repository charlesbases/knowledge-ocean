#!/usr/bin/env bash

set -e

# 查看 kubernetes 镜像列表
# sudo kubeadm config images list > images.txt

repository="10.64.21.107:83"

main() {
  ls | grep ".yaml" | while read file; do
    cat $file | grep "image: " | sed -s 's/.*image: //g' | sed -s 's/"//g' | sed -s "s/'//g" >> images.txt
  done

  cat images.txt | sort | uniq > images.txt

  cat images.txt | while read image; do
    echo -e "\033[32mdocker pull $image ...\033[0m"
    docker pull $image
  done
  
  if [[ $repository ]]; then
    cat images.txt | while read image; do
      local target=$repository/${image##*/}

      echo -e "\033[34m$image => $target\033[0m"
      docker tag $target
    done

    echo -e "\033[36m\nComplete! Please replace the mirror repository to '$repository'.\033[0m\c"
  fi
}

push() {
  if [[ $repository ]]; then
    cat "images.txt" | while read image; do
      local target=$repository/${image##*/}

      echo -e "\033[32mdocker push $target ...\033[0m"
      docker push $target
    done
  fi
}

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

    echo -e "\033[32mdocker save $image ...\033[0m"
    docker save -o ./images/$filename.tar $image
  done
}

clean() {
  cat "images.txt" | while read image; do
    docker rmi -f $(docker images | grep $image | awk '{if (NR==1){print $3}}')
  done
}

case $1 in
  push)
  push
  ;;
  save)
  save
  ;;
  clean)
  clean
  ;;
  *)
  main
  ;;
esac
