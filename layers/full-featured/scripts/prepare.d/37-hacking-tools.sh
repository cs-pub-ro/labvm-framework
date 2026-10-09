#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Install some basic hacking/security testing tools

[[ "$VM_INSTALL_HACKING_TOOLS" == "1" ]] || { sh_log_info " > Skipped!"; return 0; }

pkg_install --no-install-recommends \
	testdisk foremost dosfstools mtools pciutils usbutils lshw mc genisoimage \
	imagemagick exiftool binwalk sqlmap nikto pwgen john

