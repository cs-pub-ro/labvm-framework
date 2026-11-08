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
   all other stages!). All provisioning snippets live in `prepare.d` (see below),
   each named `NN-name.sh`;

2. Run the first stage: `prepare-multistage.sh` over the snippets dirs with a
   numeric range (default `1-19`); the last script may issue an optional reboot,
   it will be properly awaited by Packer; use this stage to fix networking and do
   kernel / bootloader-level configuration (e.g., `net.ifnames` cmdline options);

3. Run the second (and last) stage: `prepare-multistage.sh` over the snippets
   dirs with a numeric range (default `1,20-99`); the init scripts (`NN < 10`) are
   sourced again here, followed by all the install scripts expecting a proper
   kernel setup (ran after the reboot).

The ranges are just the `NN` prefix filters, so a snippet runs in a stage when its
`NN` falls inside that stage's range -- no symlinks are involved.

### Snippets dirs

The snippet dirs are configured with the `vm_prepare_dirs` Packer variable: a
colon-separated (`PATH`-style) list of dirs relative to `/opt/vm-scripts/` (or
absolute). The default is:

```
prepare.d:install-stage1.d:install-stage2.d
```

Missing dirs are skipped, so the legacy names keep old trees working.
The dirs form a single virtual dir: snippets from **all** of them are sorted 
by `NN`, and on duplicate filenames the **first** dir listed wins (again like 
`$PATH`).
So put `prepare.d` first so it shadows legacy snippets.
From a `Makefile`, override the list with e.g.:

```Makefile
main-packer-args += -var 'vm_prepare_dirs=prepare.d:my-legacy.d'
```

Note: two dirs with the *same* name cannot be listed -- `<layer>-copy-scripts` rsyncs
all of them into the same path in the VM (last copied wins at that stage).

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
#main-copy-scripts += $(abspath ./my-prepare.sh) $(abspath ./overrides)/
```

Note: this generic layer does NOT customize anything on the VM image -- it is
meant to be used as a starter layer for further extensions, so you must add your
own install snippets inside the appropiate provisioning directories executed.

See the [full-featured](../full-featured/Readme.md) layer for an advanced
example of defining layers on top of this, or the [example 
template](../../example).

