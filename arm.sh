#!/usr/bin/bash -x
qemu-system-arm -M virt,highmem=off \
  -cpu cortex-a15 \
  -m 2048 \
  -blockdev driver=file,node-name=arm.disk,filename=./arm.raw  -device virtio-blk-pci,drive=arm.disk \
  -smp 2  \
  -kernel boot/zImage \
  -initrd boot/initramfs-linux.img \
  -nographic \
  -netdev tap,id=nd0,ifname=tap0,script=no,downscript=no,vhost=off -device virtio-net-pci,netdev=nd0 \
-append 'root=PARTUUID="83aedb0a-e597-4e4a-8e0b-e816732af9b6" rw'
