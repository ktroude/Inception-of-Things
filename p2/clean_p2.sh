#!/bin/bash

echo "=== Cleaning P2 ==="

# Tuer tous les processus Vagrant
echo "Killing Vagrant processes..."
pkill -9 -f vagrant 2>/dev/null || true
sleep 1

# Arreter la VM
echo "Stopping VM..."
VBoxManage controlvm ktroudeS poweroff 2>/dev/null || true
sleep 2

# Detruire via Vagrant
echo "Destroying VM via Vagrant..."
vagrant destroy -f 2>/dev/null || true

# Supprimer manuellement de VirtualBox
echo "Removing VM from VirtualBox..."
VBoxManage unregistervm ktroudeS --delete 2>/dev/null || true

# Supprimer les anciennes VMs p2
echo "Cleaning old p2 VMs..."
for vm in $(VBoxManage list vms | grep "p2_" | cut -d'"' -f2); do
    echo "  Removing $vm..."
    VBoxManage controlvm "$vm" poweroff 2>/dev/null || true
    sleep 1
    VBoxManage unregistervm "$vm" --delete 2>/dev/null || true
done

# Nettoyer les fichiers
echo "Cleaning files..."
rm -f k3s.yaml token
rm -rf .vagrant
rm -rf ~/VirtualBox\ VMs/p2_* 2>/dev/null || true

echo "=== Cleanup P2 complete! ==="
