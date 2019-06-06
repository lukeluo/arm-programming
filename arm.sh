#!/usr/bin/bash -x
qemu-system-arm -M virt,highmem=off \
  -cpu cortex-a15 \
  -m 2048 \
  -drive file=./arm.raw,format=raw,index=0,if=virtio,media=disk \
  -smp 2  \
  -kernel boot/zImage \
  -initrd boot/initramfs-linux.img \
  -nographic \
  -netdev tap,id=nd0,ifname=tap0,script=no,downscript=no -device e1000,netdev=nd0  \
-append 'root=PARTUUID="4b4f0b88-7eaf-4ae0-8669-4c012107667e" rw'
