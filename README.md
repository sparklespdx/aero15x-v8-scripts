# Gigabyte Aero 15x v8 Notes and Scripts

I have gotten this laptop to reliably run Linux with some workarounds and caveats. I am using Fedora 28 / Kernel version 4.18 with XWayland.

The laptop has crappy ACPI support for Linux, including issues with powering down the dGPU and issues with the keyboard Fn keys. Other than that, it seems to work pretty well.

### dGPU / Optimus support

This laptop is plauged by ACPI power issues that result in hard kernel lockups without some workarounds. This is apparently a common problem with NVIDIA Optimus laptops that has persisted over the past 2 years.

For details on this problem, [this bug report for nouveau](https://bugzilla.kernel.org/show_bug.cgi?id=156341) is the best source of information.

This issue prevents `bbswitch` / `bumblebee` from working. When the card is off, the kernel locks up whenever any program tries to initiate communication with the card (i.e. `lspci` crashes the system.) There is a [github issue](https://github.com/Bumblebee-Project/Bumblebee/issues/764#issuecomment-234494238) that details the problem; it's the same issue as the referenced bug in nouveau. None of the `acpi_osi` workarounds were successful on the Aero 15x v8, presumably because it doesn't support Windows 7.

Nouveau also causes kernel lockups when suspending / resuming the system. Karol Herbst has [provided a patch](https://bugzilla.kernel.org/show_bug.cgi?id=156341#c93) that fixes this issue with Nouveau in my setup. Nouveau will power off the card when it is not in use.

What works on my setup:
* Attaching dGPU to primary display with NVIDIA proprietary drivers using the modesetting driver (when `nvidia` module is loaded at boot time).
* Attaching dGPU to primary display using `noveau` (when `noveau` is loaded at boot time).
* Powering on/off the card works by dynamically loading / unloading the `nvidia` and `nouveau` modules while XWayland is bound to the Intel card on the primary display. This works for CUDA/OpenCL workloads and the NVIDIA Docker runtime.

What doesn't work:
* X11 gets angry about dynamically loading and unloading `nvidia` and `nouveau`, so this only works with XWayland. As a result, `nvidia-xrun` doesn't work.
* `bumblebee` doesn't work because of the dependency on `bbswitch`.

Caveats:
* Booting with either `nouveau` or `nvidia` loaded makes it hard to unload the modules later, even if the user logs out and logs back in. To get around this, I blacklist the modules at boot time if I want to use the Intel graphics for the primary display. We load `noveau` using GDM auto-start instead of at boot time, preventing XWayland from grabbing it and using it to render the screen, so we can display things with Intel and `nouveau` can turn the card off. **This requires an edit to `/etc/sudoers` that allows wheel members to load nouveau without a password.** Something like:

```
%wheel	ALL=(ALL)	NOPASSWD: /usr/sbin/modprobe nouveau
```

* On the flipside of this issue, in order to use the `nvidia` module to drive the primary display, the modules must be loaded at boot time. In order to disable the card after starting up this way, a reboot is required.

Helper scripts:
* `build-nouveau.sh`: This script will download the Linux kernel from git.kernel.org, patch the `nouveau` module with Karol's power management workaround, build it against your running kernel, and install the new module.
* `gpuswitch.sh`: Loads and unloads modules and shuffles the config files around to turn the dGPU on or off.
* `gpuswitch-configs`: Config files that `gpuswitch.sh` uses, please read it to figure out where they go.

Since the NVIDIA docker runtime works so well on this system, I was going to attempt to pass a TTY to a Docker container and try an `nvidia-xrun`-style setup with X11 inside a container.

### Keyboard support

The keyboard sends out sensible HID codes for the Fn volume controls and Sleep button,
but the scan codes for the other buttons do not follow the HID standard as I understand it.
They (mostly) do not fire events on key release and the format of the scan codes doesn't
conform to the HID documentation. The usbhid driver doesn't know what to do with the messages
and drops them on the floor; we don't even see "unknown key" messages in `dmesg`. We can only
see them if we record the raw messages from the kernel using `/dev/hidraw`.

What's even weirder is that the Volume keys fire normal HID events AND these non-standard events.
They are also the only keys that fire a key press and key release in the non-standard format.
It's possible these are WMI events, but the keys don't do anything in Windows either. I don't know
much about WMI and I am exploring this further; if possible I would like to add support in the kernel.

Until the driver is working, I have done some hacky stuff with hid-record, awk and bash to get Fn-key
support working for my use cases. I've also documented the nonstandard scan codes and mapped them to
their keys. See `hotkeys.sh` for details.

What works:
* Normal keys and numpad
* Break, Insert, PrtScr
* Volume Control Fn keys (F7 - F9)
* Sleep Fn key (F1)
* Sniffing /dev/hidraw and doing hacky things for the other hotkeys

What doesn't work:
* Natve support in usbhid driver for most of the Fn hotkeys.
