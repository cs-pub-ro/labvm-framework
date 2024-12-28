# VM Framework - Generic Layer

This is a generic Linux VM build layer designed for simplicity and flexibility.

It is compatible with any base layer (just make sure the SSH server is installed
and properly configured).

## Provisioning Stages

It consists of following stages (note: all script stages are optional and will
not error if they do not exist!):

1. Sync files from a local `vm_scripts_src` path (defaults to `scripts/` 
   relative to the packer file, so make sure you use absolute path inside your 
   Makefile!) onto the VM (hardcoded path: `/opt/vm-scripts/` -- used as base for
   all other stages!);

2. Execute the `vm-prepare.sh` scripts (from the synced scripts dir); you can use
   this to setup / symlink the scripts for the two stages following it (see the
   example);

3. Execute the first installation stage (sorted scripts inside `install-stage1.d` 
   vm-scripts path); the last script may issue an optional reboot, it will be
   properly awaited by Packer; you can use this stage to fix networking and do 
   kernel / bootloader-level configuration (e.g., `net.ifnames` cmline options);

4. Execute the second (and last) stage (`install-stage2.d`); in here, you should
   put all other scripts expecting a proper kernel setup (ran after the reboot);

You can include (or simply inspire from) the layer's `build.mk` containing the
VM framework macros to use for building a VM.

**Important scripts syncing note**: Packer uses `rsync` semantics for copying
files onto the VM, so if you want to copy the contents of a directory only, make
sure to end it with `/` (slash)!

## Usage

To get started, simply include layer's `build.mk` and call the `vm_new_layer_generic` 
macro:

```Makefile
include $(FRAMEWORK_DIR)/layers/generic/build.mk

# creates the `main` VM using defaults
$(call vm_new_layer_generic,main)
# override the name and source scripts
main-name = examplevm_$(examplevm-ver)
# Note: make sure the directory ends with '/' so its contents are copied!
main-copy-scripts = $(abspath ./main/scripts)/
# the *-copy-scripts is a list, so you can sync multiple directories, e.g.:
#main-copy-scripts += $(abspath ./vm-prepare.sh) $(abspath ./overrides)/
```

