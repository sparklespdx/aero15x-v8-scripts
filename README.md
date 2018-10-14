### Gigabyte Aero 15x v8 Notes and Scripts

I have gotten this laptop to reliably run Linux with some workarounds and caveats. I am using Fedora 28 / Kernel version 4.18 with XWayland.

The laptop has crappy ACPI support for Linux, including issues with powering down the dGPU and issues with the keyboard Fn keys. Other than that, it seems to work pretty well.

##### dGPU / Optimus support

This laptop is plauged by ACPI power issues that result in hard kernel lockups without some workarounds. This is apparently a common problem with NVIDIA Optimus laptops that has persisted over the past 3 years.

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
* Booting with either `nouveau` or `nvidia` loaded makes it hard to unload the modules later, even if the user logs out and logs back in. To get around this, I blacklist the modules at boot time during normal operation. If `noveau` is the active module, we load it using GDM auto-start. This requires an edit to `/etc/sudoers` that allows wheel members to load nouveau without a password.
* On the flipside of this issue, in order to use the `nvidia` module to drive the primary display, the modules must be loaded at boot time. In order to disable the card after starting up this way, a reboot is required.

Helper scripts:
* `build-nouveau.sh`: This script will download the Linux kernel from git.kernel.org, patch it with Karol's power management workaround, build it against your running kernel, and install the new module.
* `gpuswitch.sh`: Loads and unloads modules and shuffles the config files around to turn the dGPU on or off.
* `gpuswitch-configs`: Config files that `gpuswitch.sh` uses, please read it to figure out where they go.

Since the NVIDIA docker runtime works so well on this system, I was going to attempt to pass a TTY to a Docker container and try an `nvidia-xrun`-style setup with X11 inside a container.

###### Keyboard support

What works:
* Normal keys and numpad
* Volume Control Fn keys (F7 - F9)
* Sleep Fn key (F1)

What doesn't work:
* Any of the other Fn keys, including screen brightness. FWIW these don't work on Windows either without the stupid Gigabyte Smart Manager software. Some reverse engineering could probably be done to figure this out, maybe sniff ACPI events or unpack the Smart Manager binary.
* Backlight controls, including brightness. The settings from the last time the machine was booted carry over, so you can change the backlight in Windows and it will stay wherever you left it. I may work on reverse engineering Smart Manager to figure out how to do this.
