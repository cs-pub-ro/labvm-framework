# VM Framework - Fully Featured VM Layer

A layer with scripts for installing a fully-featured (though terminal-only) 
Linux VM for development / "hacking" purposes.

## Snippets

Based on the generic layer, includes many snippets for provisioning many Linux
tools to use in a computer science lab:

- enable legacy `eth*` names and provide portable settings (for netplan / ifupdown);
- install common terminal packages (e.g., `vim`, `curl`, `wget` etc.);
- development packages (`make`, `build-essential`, `gdb` etc.)
- networking tools (`ping`, `traceroute`, `tcpdump`, `netcat` etc.);
- install & configure Docker (incl. sudo access for VM user);
- user tweaks (TERM / bashrc colors & persistent history / zsh config / tmux etc.);

## Usage

A helper makefile include is available:

```Makefile
include $(FRAMEWORK_DIR)/layers/generic/build.mk
include $(FRAMEWORK_DIR)/layers/full-featured/build.mk

# create the `full` VM using the full-featured layer defaults
$(call vm_new_layer_full_featured,full)
# e.g., override the name & base image
full-name = full_vm_v2
full-src-from = base
# the *-copy-scripts is a list, so you can sync multiple directories, e.g.:
#full-copy-scripts += $(abspath ./overrides)/
```

## Customization

The snippets are organized inside the `full-snippets.d` directory, which will
get copied to `/opt/vm-scripts/` by the first Packer provisioning command.

The scripts use the following numbering convention:

- `01-09`: initialization scripts, sourced on all [generic provisioning 
   stages](../generic/Readme.md);
- `10-19`: scripts ran by in `stage1`, before the reboot, used to configure
   kernel / firmware / bootloader aspects of the VM;
- `20+`: install scripts sourced on `stage2` after the reboot.

Note: The snippets are automatically symlinked to the appropiate VM stage by the
[`full-prepare.sh`](./scripts/full-prepare.sh) script using the above
conventions.

If you wish to cherry-pick individual scripts, you must manually study them for
any inter-dependencies!

Many of the features can be disabled either by using bash variables inside 
override files (e.g., set `VM_INSTALL_DOCKER=0` inside a new `02-overrides.sh` 
file) or by simply unlinking the installation script inside your own preparation
script!

