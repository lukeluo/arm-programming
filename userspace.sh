#!/usr/bin/bash -x



pacman-key --init
pacman-key --populate archlinuxarm


pacman -Syy --noprogressbar
yes | pacman -Su --noprogressbar --noconfirm

#mkinitcpio -p linux-armv7

yes | pacman --noprogressbar --needed  --noconfirm -S gcc gdb

#scp the new initramfs and kernel out Qemu to replace the old /boot/{initramfs-linux.img,zImage} in host.
scp -oStrictHostKeyChecking=accept-new /boot/{initramfs-linux.img,zImage} luke@192.168.200.208:~/
