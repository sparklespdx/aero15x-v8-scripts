#!/bin/bash

# Go to kernel source tree and build

sudo echo 'Starting patch and build of Nouveau module...'

orig_dir=$PWD
cd /home/josh/git/linux

git reset --hard
git checkout v$(uname -r | cut -d'.' -f1-2)
patch -p1 < ../aero15x-scripts/nouveau-power.patch

cd drivers/gpu/drm/nouveau
make -C /lib/modules/$(uname -r)/build M=$(pwd) clean
make -j6 -C /lib/modules/$(uname -r)/build M=$(pwd) modules
sudo make -j6 -C /lib/modules/$(uname -r)/build M=$(pwd) modules_install
make -C /lib/modules/$(uname -r)/build M=$(pwd) clean

# Remove module installed by package
sudo rm /lib/modules/$(uname -r)/kernel/drivers/gpu/drm/nouveau/nouveau.ko.xz
cd $orig_dir
echo 'Patch applied.'
