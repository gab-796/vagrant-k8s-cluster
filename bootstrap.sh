#!/bin/bash
set -e

# Versão fixa do Kubernetes
KUBE_VERSION="1.29.3-1.1"

# ----------------------------
# Atualiza repositórios e instala dependências básicas
# ----------------------------
sudo apt-get update
sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  apt-transport-https \
  software-properties-common

# ----------------------------
# Instala Docker versão mais recente disponível
# ----------------------------
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | \
  gpg --dearmor | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian bullseye stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker

# ----------------------------
# Instala Kubernetes versão 1.29.3
# ----------------------------
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
  gpg --dearmor | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.gpg > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

sudo apt-get update
sudo apt-get install -y \
  kubelet=${KUBE_VERSION} \
  kubeadm=${KUBE_VERSION} \
  kubectl=${KUBE_VERSION}
sudo apt-mark hold kubelet kubeadm kubectl

# ----------------------------
# Configurações do sistema
# ----------------------------
# Desativa swap (obrigatório para o Kubernetes)
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Habilita IP forwarding e persistência
sudo modprobe br_netfilter
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee /etc/sysctl.d/k8s.conf
sudo sysctl --system

# ----------------------------
# Inicializa cluster Kubernetes (apenas no master)
# ----------------------------
if hostname | grep -q master && [ ! -f /etc/kubernetes/admin.conf ]; then
  sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=${KUBE_VERSION}

  # Configura acesso kubectl para o usuário vagrant
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  # Aplica o Flannel CNI
  kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

  # Exibe comando de join
  kubeadm token create --print-join-command
fi
