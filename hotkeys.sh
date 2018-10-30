#!/bin/bash

# Hotkeys Hax
#
# I'm still figuring out how to add HID drivers for this keyboard.
# I'm not sure if it's possible given that most of the keys that I care about
# (brightness controls, airplane mode, fan toggle) don't seem to register
# key releases; only key presses. The keyboard seems to be using a custom
# implementation for these keys, the codes don't follow the HID standard.
# I will document this behavior further in the README.

# To tide me over while I work on the driver, I am sniffing the HID events 
# off the hidraw bus with hid-recorder and matching the key press events with
# regex. It's ugly, but it works.


# Keycode reference

# [root@lappy-mk5 ~]# hid-recorder /dev/hidraw2
# D: 0
# R: 205 05 01 09 02 a1 01 85 01 09 01 a1 00 05 09 15 00 25 01 19 01 29 05 75 01 95 05 81 02 95 03 81 01 05 01 16 01 80 26 ff 7f 09 30 09 31 75 10 95 02 81 06 15 81 25 7f 09 38 75 08 95 01 81 06 05 0c 0a 38 02 95 01 81 06 c0 c0 05 01 09 80 a1 01 85 02 19 81 29 83 15 00 25 01 75 01 95 03 81 02 95 05 81 01 c0 05 0c 09 01 a1 01 85 03 19 00 2a ff 07 15 00 26 ff 07 95 01 75 10 81 00 c0 06 02 ff 09 01 a1 01 85 04 15 00 26 ff 00 09 03 75 08 95 03 81 00 c0 05 01 09 06 a1 01 85 05 05 07 95 01 75 08 81 03 95 e8 75 01 15 00 25 01 05 07 19 00 29 e7 81 00 c0 05 01 09 02 a1 01 85 06 15 00 26 ff 7f 09 30 09 31 75 10 95 02 81 02 c0
# N: HOLTEK USB-HID Keyboard
# P: usb-0000:00:14.0-11/input2
# I: 3 1044 7a39

# E: 1.048400 4 04 00 00 84	Fn + Esc, "Fan button" press (no signal for release)
# E: 59.807566 2 02 02		Fn + F1, Sleep press	
# E: 59.942351 2 02 00		Fn + F1, Sleep release
# E: 210.391313 4 04 00 00 7c	Fn + F2, Wifi press (no signal for release)
# E: 241.926536 4 04 00 00 7d	Fn + F3, Brightness Down press (no signal for release)
# E: 242.990502 4 04 00 00 7e	Fn + F4, Brightness Up press (no signal for release)
# 				No signal for Fn + F5
# E: 354.099824 4 04 00 00 80	Fn + F6, Some kinda X box thing (no signal for release)

# It fires non-standard events and HID-compliant events for the volume keys.
# This is also the only time we see it register presses AND releases in the
# non-standard format.

# E: 0.000000 4 04 00 01 85	Fn + F7, Mute press
# E: 0.007952 3 03 e2 00	Fn + F7, Mute press (normal HID codes)
# E: 0.191948 4 04 00 00 85	Fn + F7, Mute release
# E: 0.199945 3 03 00 00	Fn + F7, Mute release (Normal HID codes)
# E: 2.167890 4 04 00 01 86	Fn + F8, Volume Down press
# E: 2.175914 3 03 ea 00	Fn + F8, Volume Down press (normal HID codes)
# E: 2.351893 4 04 00 00 86	Fn + F8, Volume Down release
# E: 2.359894 3 03 00 00	Fn + F8, Volume Down release (normal HID codes)
# E: 0.000001 4 04 00 01 87	Fn + F9, Volume Up press
# E: 0.007954 3 03 e9 00	Fn + F9, Volume Up press (normal HID codes)
# E: 0.151898 4 04 00 00 87	Fn + F9, Volume Up release
# E: 0.159971 3 03 00 00	Fn + F9, Volume Up release (normal HID codes)

# E: 103.657585 4 04 00 00 81	Fn + F10, A key in a box (no signal for release)
# E: 149.248696 4 04 00 00 82	Fn + F11, Airplane Mode press (no signal for release)
# E: 0.000000   4 04 00 00 83	Fn + F12, no button graphic but fires a code anyway (no signal for release)


notify_josh () {
	sudo -u josh DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus notify-send "$1" "$2"
}

raise_brightness () {
	brightness=$(cat /sys/class/backlight/intel_backlight/brightness)
	if [[ $brightness -gt 102000 ]]; then
		echo 180000 > /sys/class/backlight/intel_backlight/brightness
	elif [[ $brightness -eq 0 ]]; then
		echo 1 > /sys/class/backlight/intel_backlight/brightness
	else
		echo $(($brightness + 18000)) > /sys/class/backlight/intel_backlight/brightness
	fi
}

lower_brightness () {
	brightness=$(cat /sys/class/backlight/intel_backlight/brightness)
	if [[ $brightness -lt 18000 && $brightness -gt 1 ]]; then
		echo 1 > /sys/class/backlight/intel_backlight/brightness
	elif [[ $brightness -eq 1 ]]; then
		echo 0 > /sys/class/backlight/intel_backlight/brightness
	else
		echo $(($brightness - 18000)) > /sys/class/backlight/intel_backlight/brightness
	fi
}

toggle_cpupower () {
	GOV=$(cpupower frequency-info | grep 'The governor ".*" may decide' | cut -d'"' -f2)

	if [ $GOV == 'powersave' ]; then
		cpupower frequency-set -g performance
		notify_josh "🔥🔥🔥" "cpufreq governer set to 'performance'"
	elif [ $GOV == 'performance' ]; then
		cpupower frequency-set -g powersave
		notify_josh "🐢🐢🐢" "cpufreq governer set to 'powersave'"
	fi
}

toggle_bluetooth () {
	BLUE=$(hciconfig hci0 | head -n3 | tail -n1)
	if echo "$BLUE" | grep -q 'DOWN'; then
		hciconfig hci0 up
		notify_josh "🥶🥶🥶" "Bluetooth is turned on"
	elif echo "$BLUE" | grep -q 'UP'; then
		hciconfig hci0 down
		notify_josh "☀️☀️☀️" "Bluetooth is turned off"
	fi
}

export -f notify_josh
export -f raise_brightness
export -f lower_brightness
export -f toggle_cpupower
export -f toggle_bluetooth

hid-recorder /dev/hidraw2 | \
	awk '/E:.*4 04 00 00 7d/{ system("lower_brightness") }
	     /E:.*4 04 00 00 7e/{ system("raise_brightness") }
	     /E:.*4 04 00 00 84/{ system("toggle_cpupower")  }
	     /E:.*4 04 00 00 7c/{ system("toggle_bluetooth") }'
