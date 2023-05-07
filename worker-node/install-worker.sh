#!/bin/bash

# Sửa lỗi 'dnf update -y or install
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# Import GPG key
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
rpm --import https://download.docker.com/linux/centos/gpg
rpm --import https://packages.cloud.google.com/yum/doc/yum-key.gpg
rpm --import https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg

# Cai dat Docker
dnf install -y yum-utils device-mapper-persistent-data lvm2
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install containerd.io docker-ce docker-ce-cli -y
usermod -aG docker $(whoami)

# cài ip route
dnf install -y iproute

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "debug": true,
  "experimental": false,
  "log-driver": "json-file",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

# Restart Docker
systemctl daemon-reload
systemctl enable docker --now

# Tat SELinux
setenforce 0
sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

# Cho phép các cổng  worker-node
firewall-cmd --add-port={10250,30000-32767,5473,179,5473,6783}/tcp --permanent
firewall-cmd --add-port={4789,8285,8472,6783,6784}/udp --permanent
firewall-cmd --reload
firewall-cmd --list-ports

# sysctl
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# Tat swap
sed -i '/swap/d' /etc/fstab
swapoff -a

# Add yum repo file for Kubernetes
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable kubelet
systemctl start kubelet
# remove config.toml khắc phục lỗi 'kubeadm init --pod-network-cidr 192.168.0.0/16'
rm -rfv /etc/containerd/config.toml
systemctl restart containerd