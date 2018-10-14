#!/bin/bash

# Go to kernel source tree and build
cd /home/josh/git/linux/drivers/gpu/drm/nouveau
make -C /lib/modules/$(uname -r)/build M=$(pwd) clean
make -j6 -C /lib/modules/$(uname -r)/build M=$(pwd) modules
sudo make -j6 -C /lib/modules/$(uname -r)/build M=$(pwd) modules_install
make -C /lib/modules/$(uname -r)/build M=$(pwd) clean

# Remove module installed by package
sudo rm /lib/modules/$(uname -r)/kernel/drivers/gpu/drm/nouveau/nouveau.ko.xz
