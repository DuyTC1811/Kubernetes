# Kubernetes

Khởi tạo cụm Kubernetes
kubeadm init --pod-network-cidr=192.168.0.0/16

Coppy và chạy lệnh này

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

Thêm plugin
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

nếu các node  NotReady thì vào trang chủ cài plugin mới nhất 
https://www.weave.works/docs/net/latest/kubernetes/kube-addon/#install
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml