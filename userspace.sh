#!/usr/bin/bash -x



pacman-key --init
pacman-key --populate archlinuxarm


pacman -Syy
pacman -Su

mkinitcpio -p linux-armv7

pacman -S gcc gdb 

#scp the new initramfs out Qemu to replace the old /boot/initramfs-linux.img in host. 
# scp /boot/initramfs-linux.img luke@192.168.200.208:~/

