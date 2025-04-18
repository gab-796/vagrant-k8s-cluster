#!/bin/bash

# Faz com que o vagrant pare logo no primeiro erro
set -e

# Imprime o comando no terminal antes de executar
set -x

KUBE_VERSION="1.29.3-1.1"
MASTER_IP="10.0.2.15"
JOIN_FILE="/vagrant/join-command.sh" # pasta compartilhada

# ----------------------------
# Instalação de dependências
# ----------------------------
sudo apt-get update
sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  apt-transport-https \
  software-properties-common \
  openssh-client \
  openssh-server

# ----------------------------
# Docker + containerd com CRI habilitado pra uso em k8s
# ----------------------------
sudo install -m 0755 -d /etc/apt/keyrings
DOCKER_KEYRING=/etc/apt/keyrings/docker.gpg
CONTAINERD_KEYRING=/etc/apt/keyrings/containerd.gpg

# Remove entradas antigas
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/sources.list.d/containerd.list

# Adiciona chave e repositório Docker
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor | sudo tee ${DOCKER_KEYRING} > /dev/null

echo "deb [arch=$(dpkg --print-architecture) signed-by=${DOCKER_KEYRING}] \
  https://download.docker.com/linux/debian bullseye stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Adiciona chave e repositório Containerd
curl -fsSL https://download.containerd.io/linux/amd64/containerd-1.6.9.linux-amd64.tar.gz | gpg --dearmor | sudo tee ${CONTAINERD_KEYRING} > /dev/null

echo "deb [arch=$(dpkg --print-architecture) signed-by=${CONTAINERD_KEYRING}] \
  https://download.containerd.io/debian/stable/amd64/ bullseye main" | \
  sudo tee /etc/apt/sources.list.d/containerd.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# ----------------------------
# Configura o containerd para CRI
# ----------------------------
# Gera o config.toml padrão
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# Remove a linha que desativa o plugin cri, se existir
sudo sed -i '/disabled_plugins/d' /etc/containerd/config.toml

# Habilita SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Reinicia e habilita containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# ----------------------------
# Kubernetes
# ----------------------------
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.gpg > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

sudo apt-get update
sudo apt-get install -y kubelet=${KUBE_VERSION} kubeadm=${KUBE_VERSION} kubectl=${KUBE_VERSION}
sudo apt-mark hold kubelet kubeadm kubectl

# ----------------------------
# Configurações do sistema - Desabilita o Swap e Habilita IP Forward e persistência
# ----------------------------
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo modprobe br_netfilter
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee /etc/sysctl.d/k8s.conf
echo 'br_netfilter' | sudo tee /etc/modules-load.d/k8s-br-netfilter.conf #Torna a config eterna.
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.d/k8s.conf #Habilita o IP Forwarding
sudo sysctl --system


# ----------------------------
# Sincronização de horário com systemd-timesyncd
# ----------------------------
sudo apt-get install -y systemd-timesyncd
sudo timedatectl set-ntp true
sudo systemctl enable systemd-timesyncd
sudo systemctl start systemd-timesyncd

# ----------------------------
# Master node
# ----------------------------
if hostname | grep -q master && [ ! -f /etc/kubernetes/admin.conf ]; then
  sudo kubeadm init --apiserver-advertise-address=192.168.56.10 --pod-network-cidr=10.244.0.0/16 --kubernetes-version=1.29.3

  # Configura acesso kubectl para o usuário vagrant
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  # Instala o CNI Flannel
  kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

  MASTER_IP=$(ip -4 -o addr show eth1 | awk '{print $4}' | cut -d/ -f1)

  JOIN_CMD=$(kubeadm token create --print-join-command)
  JOIN_CMD=$(echo $JOIN_CMD | sed "s/[^ ]\+:6443/${MASTER_IP}:6443/")
  
  echo $JOIN_CMD > ${JOIN_FILE}
  chmod +x ${JOIN_FILE}

fi

# ----------------------------
# Worker node
# ----------------------------
if hostname | grep -q worker; then
  # Espera o master disponibilizar o join-command
  while [ ! -s ${JOIN_FILE} ]; do
    echo "Aguardando comando de join do master..."
    sleep 5
  done

  # Executa o comando
  sudo bash ${JOIN_FILE}
fi
