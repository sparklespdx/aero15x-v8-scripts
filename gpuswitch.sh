#!/bin/bash

# Switches from nvidia to nouveau driver

load_nvidia () {
	lsmod | grep -q nvidia
	if [[ $? -ne 0 ]]; then
		sudo rmmod nouveau
		sudo modprobe nvidia
		sudo modprobe nvidia_uvm
		sudo modprobe nvidia_modeset
		sudo modprobe nvidia_drm
	fi
}

x11_nvidia () {
	if [[ -f "/etc/X11/xorg.conf.d/10-nvidia.disabled" ]]; then
		sudo mv /etc/X11/xorg.conf.d/10-nvidia.disabled /etc/X11/xorg.conf.d/10-nvidia.conf
	fi

	if [[ -f "/home/josh/.config/autostart/nouveau.desktop" ]]; then
		mv /home/josh/.config/autostart/nouveau.desktop /home/josh/.config/autostart/nouveau.desktop.disabled
	fi

	if [[ -f "/etc/modprobe.d/blacklist-nvidia.conf" ]]; then
		sudo mv /etc/modprobe.d/blacklist-nvidia.conf /etc/modprobe.d/blacklist-nvidia.disabled
	fi
}

unload_nvidia () {
	lsmod | grep -q nvidia
	if [[ $? -eq 0 ]]; then
		sudo rmmod nvidia_drm
		sudo rmmod nvidia_modeset
		sudo rmmod nvidia_uvm
		sudo rmmod nvidia
		sudo modprobe nouveau
	fi
}

x11_intel () {
	if [[ -f "/etc/X11/xorg.conf.d/10-nvidia.conf" ]]; then
		sudo mv /etc/X11/xorg.conf.d/10-nvidia.conf /etc/X11/xorg.conf.d/10-nvidia.disabled
	fi

	if [[ -f "/home/josh/.config/autostart/nouveau.desktop.disabled" ]]; then
		mv /home/josh/.config/autostart/nouveau.desktop.disabled /home/josh/.config/autostart/nouveau.desktop
	fi

	if [[ -f "/etc/modprobe.d/blacklist-nvidia.disabled" ]]; then
		sudo mv /etc/modprobe.d/blacklist-nvidia.disabled /etc/modprobe.d/blacklist-nvidia.conf
	fi
}

case "$1" in
	off)	
		x11_intel
		unload_nvidia
		if [[ $? -ne 0 ]]; then
			echo "******"
			echo "A reboot is required to disable the GPU."
		fi
		;;
	on)
		load_nvidia
		x11_nvidia
		;;
	*)
		echo "please say 'off' or 'on'."
esac
