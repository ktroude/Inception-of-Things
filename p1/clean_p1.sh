#!/bin/bash

echo "=== Cleaning P1 ==="

# Tuer tous les processus Vagrant
echo "Killing Vagrant processes..."
pkill -9 -f vagrant 2>/dev/null || true

# Arreter les VMs
echo "Stopping VMs..."
VBoxManage controlvm ktroudeS poweroff 2>/dev/null || true
VBoxManage controlvm ktroudeSW poweroff 2>/dev/null || true
sleep 2

# Detruire via Vagrant (si possible)
echo "Destroying VMs via Vagrant..."
vagrant destroy -f 2>/dev/null || true

# Supprimer manuellement de VirtualBox
echo "Removing VMs from VirtualBox..."
VBoxManage unregistervm ktroudeS --delete 2>/dev/null || true
VBoxManage unregistervm ktroudeSW --delete 2>/dev/null || true

# Supprimer les anciennes VMs p1
echo "Cleaning old p1 VMs..."
for vm in $(VBoxManage list vms | grep "p1_" | cut -d'"' -f2); do
    echo "  Removing $vm..."
    VBoxManage controlvm "$vm" poweroff 2>/dev/null || true
    sleep 1
    VBoxManage unregistervm "$vm" --delete 2>/dev/null || true
done

# Nettoyer les fichiers
echo "Cleaning files..."
rm -rf k3s.yaml token .vagrant
rm -rf ~/VirtualBox\ VMs/p1_* 2>/dev/null || true

echo "=== Cleanup P1 complete! ==="
