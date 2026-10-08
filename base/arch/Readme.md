# VM Framework - Arch Linux Base Layer

This layer builds a base Arch Linux (rolling release) image from the live
ISO, so make sure you download it and configure the ISO path using [the
`ARCH_ISO_NAME` variable](../../config.default.mk).

It installs the system in the live environment via [`bootstrap.sh.pkrtpl`](./bootstrap.sh.pkrtpl) + 
[`arch-install.sh`](./arch-install.sh) (GRUB bootloader, x86_64 BIOS/EFI
& aarch64-EFI supported), then uses the `base-arch.d` provisioning scripts
(pacman-based) for final setup.

If you wish to override the defaults, it is recommended you rename the default
VM name (from `arch_base`).

Example makefile snippet using the built-in rules:
```Makefile
# creates the `base` VM (inherited by default by most layers)
$(call vm_new_base_arch,base)
# e.g., override the name
#base-name = Arch_custom
```
or simply run the top-level Makefile with `make BASE=arch base`.
