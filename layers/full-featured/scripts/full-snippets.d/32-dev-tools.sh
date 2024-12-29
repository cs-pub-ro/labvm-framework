#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## Dev tools installation snippet

[[ "$VM_INSTALL_DEV_TOOLS" == "1" ]] || { sh_log_info " > Skipped!"; return 0; }

# C tools & manpages
pkg_install --no-install-recommends \
	build-essential make gcc-multilib libc6-dev-i386 libc-devtools \
	cscope exuberant-ctags \
	manpages-posix manpages-dev manpages-posix-dev make-doc \
	glibc-doc-reference


# Add some i386 libraries
if uname -m | grep x86_64 >/dev/null; then
	dpkg --add-architecture i386
	pkg_init_update
	pkg_install libc6-dbg:i386 libgcc-s1:i386
fi

# Tracing & debugging
pkg_install --no-install-recommends \
	gdb gdbserver strace ltrace valgrind libc6-dbg

# Python3 & tools
pkg_install --no-install-recommends \
	python3 python3-venv python3-pip python3-setuptools libssl-dev libffi-dev \
	libglib2.0-dev sqlite3

