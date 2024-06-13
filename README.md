#!/bin/sh
cd ~
mkdir kubernetes_installation/
cd /home/sysadm/kubernetes_installation
git clone https://github.com/kubernetes-sigs/kubespray.git --branch release-2.25
cd /home/sysadm/kubernetes_installation/kubespray
cp -rf inventory/sample inventory/giangnh-cluster
cd /home/sysadm/kubernetes_installation/kubespray/
cd inventory/giangnh-cluster
vi hosts.yaml
[all]
giangnh-master1  ansible_host=10.6.13.113      ip=10.6.13.113
giangnh-master2  ansible_host=10.6.13.114      ip=10.6.13.114
giangnh-master3  ansible_host=10.6.13.115      ip=10.6.13.115
giangnh-worker1  ansible_host=10.6.13.116      ip=10.6.13.116
giangnh-worker2  ansible_host=10.6.13.117      ip=10.6.13.117
giangnh-worker3  ansible_host=10.6.13.118      ip=10.6.13.118
                             
[kube-master]
giangnh-master1
giangnh-master2
giangnh-master3

[kube-node]
giangnh-worker1
giangnh-worker2
giangnh-worker3

[etcd]
giangnh-master1
giangnh-master2
giangnh-master3

[k8s-cluster:children]
kube-node
kube-master

[calico-rr]

[vault]
giangnh-master1
giangnh-master2
giangnh-master3
giangnh-worker1
giangnh-worker2
giangnh-worker3

vi /home/sysadm/kubernetes_installation/kubespray/inventory/giangnh-cluster/group_vars/k8s_cluster/k8s-cluster.yml
Từ
kube_network_plugin: calico
Thành
kube_network_plugin: flannel

docker run --rm -it --mount type=bind,source=/home/sysadm/kubernetes_installation/kubespray/inventory/giangnh-cluster,dst=/inventory quay.io/kubespray/kubespray:v2.25.0 bash

ansible-playbook -i /inventory/hosts.yaml cluster.yml --user=sysadm --ask-pass --become --ask-become-pass

##config master-all
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
