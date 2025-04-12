#!/bin/bash

set -e

# Verifica se a vboxnet0 já existe
if VBoxManage list hostonlyifs | grep -q "Name:.*vboxnet0"; then
  echo "[✔] A interface 'vboxnet0' já existe."
else
  echo "[+] Criando a interface 'vboxnet0'..."
  VBoxManage hostonlyif create
fi

# Configura IP e netmask
echo "[+] Configurando IP da vboxnet0 para 192.168.56.1..."
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0

echo "[✔] Interface vboxnet0 pronta para uso com Vagrant!"
