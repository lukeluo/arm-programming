#!/usr/bin/bash -x

ip a

ip l set br0 down
ip l set tap0 down

ip l del br0
ip l del tap0
ip l set eno1 nomaster 

ip l set eno1 down
sleep 3 
ip l set eno1 up
sleep 20

ip a

