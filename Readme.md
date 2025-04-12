# Criação das máquinas via vagrant

É necessário instalar o Virtualbox 7.0 e o Vagrant.

> Não instale a versão 7.1 pois o Vagrant não tem suporte pra ela.

Dentro da pasta onde o arquivo vagrantfile está, execute `vagrant up`. Com isso será criadas as máquinas no VirtualBox conforme descrito no vagrantfile.

Caso já tenha pro visionado as VMs, execute `vagrant provision` que será rodado o

### Acessando as VMs
`vagrant ssh master` --> entra na VM Master
`vagrant ssh worker1` e tb worker2


### Destruindo as VMs
`vagrant destroy -f`

## Troubleshooting do vagrant

Caso dê o erro do KVMP:

Stderr: VBoxManage: error: VirtualBox can't operate in VMX root mode. Please disable the KVM kernel extension, recompile your kernel and reboot (VERR_VMX_IN_VMX_ROOT_MODE)
VBoxManage: error: Details: code NS_ERROR_FAILURE (0x80004005), component ConsoleWrap, interface IConsole

Execute:
`sudo modprobe -r kvm_intel`

2. Caso o kubelet, kubeadm e kubectl não seja instalado na master
Entre na master: vagrant ssh master
e execute os 3 comandos:
sudo rm /etc/apt/keyrings/kubernetes-apt-keyring.gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
  gpg --dearmor | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.gpg > /dev/null

sudo apt-get install -y kubelet=1.29.3-1.1 kubeadm=1.29.3-1.1 kubectl=1.29.3-1.1

