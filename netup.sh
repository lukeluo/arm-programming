#!/usr/bin/bash -x
ip l

ip  a flush dev  eno1

ip tuntap add tap0 mode tap
ip l add br0 type bridge
sleep 3

ip l set eno1 master br0
ip l set tap0 master br0

sleep 3

ip l set tap0 up
ip l set br0 up

ip a

