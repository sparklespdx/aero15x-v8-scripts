#!/bin/bash

# This applies Karol's pcie link speed patch to Nouveau,
# builds it against the current running kernel and installs it.
# https://bugzilla.kernel.org/show_bug.cgi?id=156341#c93

# It should work with any distro that uses >= 4.12 version kernel.
# I have it working with Fedora 28 / Kernel 4.18

# This requires git, make, and kernel headers.

ls . | grep -q 'build-nouveau.sh'
if [ $? -ne 0 ]; then
	echo 'Run this from the aero15x-v8-scripts directory'
	exit 1
fi

sudo echo 'Starting patch and build of Nouveau module...'

orig_dir=$(pwd)

# Download linux kernel tree if not already there
if [ ! -d ./linux ]; then
	git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
fi

# Reset git tree and apply patch
# Only checks out releases, edit this if you need to
# build  against a release candidate or master.
cd linux
git reset --hard &&
git clean -f &&
git clean -fd &&
git fetch &&
git checkout v$(uname -r | cut -d'.' -f1-2) &&
patch -p1 < ../nouveau-power.patch &&

# Build nouveau and install module
cd drivers/gpu/drm/nouveau &&
make -C /lib/modules/$(uname -r)/build M=$(pwd) clean &&
make -j6 -C /lib/modules/$(uname -r)/build M=$(pwd) modules &&
sudo make -C /lib/modules/$(uname -r)/build M=$(pwd) modules_install &&
make -C /lib/modules/$(uname -r)/build M=$(pwd) clean &&

# Remove module installed by package manager, move it back to reinstall.
cd $orig_dir &&

if [ -f "/lib/modules/$(uname -r)/kernel/drivers/gpu/drm/nouveau/nouveau.ko.xz" ]; then
	sudo mv /lib/modules/$(uname -r)/kernel/drivers/gpu/drm/nouveau/nouveau.ko.xz ./nouveau.ko.xz.orig
fi &&

echo 'Module installed.'
