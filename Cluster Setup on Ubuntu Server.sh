Ref link for ConatinerD and RunC:
#https://github.com/containerd/containerd/blob/main/docs/getting-started.md
#https://www.itzgeek.com/how-tos/linux/ubuntu-how-tos/install-containerd-on-ubuntu-22-04.html

#Install ContainerD

sudo wget https://github.com/containerd/containerd/releases/download/v1.6.2/containerd-1.6.2-linux-amd64.tar.gz #downlading containerd
sudo tar Czxvf /usr/local containerd-1.6.2-linux-amd64.tar.gz #extracted the downloaded containerd file

sudo wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service #downloading containerd service
sudo mv containerd.service /usr/lib/systemd/system/ #moved the downloaded containerd svc into specific dir

sudo systemctl daemon-reload #reloaded the daemon for ....
sudo systemctl enable --now containerd #enable the containerd
sudo systemctl status containerd #checking the containerd service is active or not

#Install RunC
sudo wget https://github.com/opencontainers/runc/releases/download/v1.1.1/runc.amd64 #downloading runc
sudo install -m 755 runc.amd64 /usr/local/sbin/runc #installing the downloaded runc

sudo mkdir -p /etc/containerd/ #creating a dir for containerd
containerd config default | sudo tee /etc/containerd/config.toml #writing config for containerd & send it to the above dir 

sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml #setting ....

sudo systemctl restart containerd #restarting the containerd
sudo systemctl status containerd #checking the containerd service is active or not



#Install Pre-requisite
#https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay #lorem ipsum ....
sudo modprobe br_netfilter #lorem ipsum ....

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

lsmod | grep br_netfilter
lsmod | grep overlay

sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

#Install Kubeadmin, Kubelet, Kubectl
#https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
#List open ports
netstat -lntu

sudo ufw allow 6443
sudo ufw allow 10250
sudo ufw allow 10259
sudo ufw allow 10257

sudo apt-get update
#weak message (optional)
# sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys B53DC80D13EDEF05
# sudo apt-get update

sudo apt-get install -y apt-transport-https ca-certificates curl



sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg


echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
#For control plane
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
##if error
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo swapoff -a

#create token on master node
kubeadm token create --print-join-command

sudo kubeadm init --control-plane-endpoint="192.168.101.201" --apiserver-cert-extra-sans="192.168.101.201" --pod-network-cidr="10.10.10.0/16" --node-name "cpu1" --ignore-preflight-errors Swap

# Your Kubernetes control-plane has initialized successfully!

# To start using your cluster, you need to run the following as a regular user:

#copy and paste the below lines
#   mkdir -p $HOME/.kube
#   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#   sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Alternatively, if you are the root user, you can run:

#   export KUBECONFIG=/etc/kubernetes/admin.conf

# You should now deploy a pod network to the cluster.
# Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
#   https://kubernetes.io/docs/concepts/cluster-administration/addons/

# You can now join any number of control-plane nodes by copying certificate authorities
# and service account keys on each node and then running the following as root:

#   kubeadm join 192.168.101.201:6443 --token 1q8eoi.t8p63ms8bhuqbo32 \
#         --discovery-token-ca-cert-hash sha256:c08171f87a28be21b162bd08406ca50d473d106d9bb421f1f642ed07f41af33c \
#         --control-plane 

# Then you can join any number of worker nodes by running the following on each as root:

# kubeadm join 192.168.101.201:6443 --token 1q8eoi.t8p63ms8bhuqbo32 \
#         --discovery-token-ca-cert-hash sha256:c08171f87a28be21b162bd08406ca50d473d106d9bb421f1f642ed07f41af33c 



kubectl cluster-info 
# Kubernetes control plane is running at https://192.168.101.201:6443
# CoreDNS is running at https://192.168.101.201:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

# To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.


#Remove taint to schedule in control plane
kubectl taint nodes --all node-role.kubernetes.io/control-plane-


#Label the worker node
kubectl label node worker-node01  node-role.kubernetes.io/worker=worker

#Install Calico CNI
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml







#Install Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

EOF