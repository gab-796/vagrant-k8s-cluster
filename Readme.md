# Criação das máquinas via vagrant

## Requisitos
Desabilitar o Secure Boot na BIOS!

Ter o Virtualbox 7.0 e o Vagrant mais atualizado possível.

> Não instale a versão 7.1 pois o Vagrant não tem suporte pra ela.

### Desabilitando o  KVM (Kernel-based Virtual Machine)
`sudo nano /etc/modprobe.d/blacklist-kvm.conf`
e adicione:

blacklist kvm
blacklist kvm_intel

Agora reinicie a máquina
`sudo reboot`

> O VirtualBox não consegue rodar com o KVM rodando. É um ou outro.

## Início
Dentro da pasta onde o arquivo vagrantfile está, execute `vagrant up`. Com isso será criadas as máquinas no VirtualBox conforme descrito no vagrantfile.

Caso já tenha pro visionado as VMs, execute `vagrant provision` que será rodado o bootstrap.sh novamente.

### Desligando o PC
O vagrant precisa ser desligado com segurança, nos moldes do windows 98, e isso é feito com o comando `vagrant suspend`.

Ao reiniciar o PC, basta usar `vagrant up`, que equivalerá ao boot nas VMs.

### Acessando as VMs
`vagrant ssh master` --> entra na VM Master
`vagrant ssh worker1` e tb worker2

### Destruindo as VMs
`vagrant destroy -f`

## Comandos Úteis
1. Verificar as box instaladas
`vagrant box list`

2. Removendo box instalada
`vagrant box remove <NOME_DA_BOX>`

3. Mostrando status geral das box instaladas
`vagrant global-status`

4. Parando VMs
`vagrant  halt`

5. Destruindo totalmente as VMs
`vagrant destroy`

6. Quando alterar algo no bootstrap.sh execute isso
`vagrant provision`

7. Obtendo log completo ao executar o provision
`vagrant provision master --debug`

## Troubleshooting do vagrant

1. Caso o kubelet, kubeadm e kubectl não seja instalado na master
Entre na master: vagrant ssh master
e execute os 3 comandos:
sudo rm /etc/apt/keyrings/kubernetes-apt-keyring.gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
  gpg --dearmor | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.gpg > /dev/null

sudo apt-get install -y kubelet=1.29.3-1.1 kubeadm=1.29.3-1.1 kubectl=1.29.3-1.1

3. Verificação do tamanho das vagrant Box
`du -sh ~/.vagrant.d/boxes/*/*/*`

Por enquanto está assim:
651M	/home/gabriel/.vagrant.d/boxes/bento-VAGRANTSLASH-ubuntu-24.04/202502.21.0/virtualbox
1,1G	/home/gabriel/.vagrant.d/boxes/debian-VAGRANTSLASH-bullseye64/11.20241217.1/virtualbox
750M	/home/gabriel/.vagrant.d/boxes/generic-VAGRANTSLASH-debian12/4.3.12/libvirt
805M	/home/gabriel/.vagrant.d/boxes/generic-VAGRANTSLASH-debian12/4.3.12/virtualbox
1,3G	/home/gabriel/.vagrant.d/boxes/generic-VAGRANTSLASH-fedora39/4.3.12/libvirt
356M	/home/gabriel/.vagrant.d/boxes/ubuntu-VAGRANTSLASH-bionic64/20230607.0.5/virtualbox


