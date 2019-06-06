#!/usr/bin/bash -x

./disk.sh
sudo ./netdown.sh
sudo ./netup.sh
./arm.sh
