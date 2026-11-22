---
name: new-vm-layer
description: Create or extend a VM layer in labvm-framework — layers/<name>/ with build.mk + a prepare-<name>.d snippet dir, registered in layers/inc_all.mk and wired into a consumer Makefile's -script-dirs/-copy-scripts. Use when asked to add a layer, derive a new VM image from a base or an existing layer, add provisioning snippets to a layer, or write a lab/course VM on top of full-featured.
---

# New VM layer

Goal: `make <vm>` in some consumer Makefile builds a VM derived from an existing
one, provisioned by new bash snippets.

Read [AGENTS.md](../AGENTS.md) §"Provisioning pipeline" first — the stage/range model
matters more than the Makefile plumbing below.

## 1. Layout

One unique snippet dir per layer. **No prepare script, no symlinks, no stage
dirs** — `scripts/prepare-multistage.sh` (shared by every VM) selects snippets
by their numeric prefix.

```
layers/<name>/
├── build.mk
├── Readme.md                        # short: what it installs, how to use
└── scripts/prepare-<name>.d/
    ├── 01-init.sh                   # configuration + defaults
    ├── 12-something.sh              # stage 1: kernel/net/boot
    ├── 30-packages.sh               # stage 2: installs
    └── 90-cleanup.sh
```

The dir name must be **unique across all layers** (`prepare-full.d`,
`prepare-cloud.d`, `prepare-desktop-xfce.d`, `prepare-main.d`, bases
`base-<distro>.d`): uploads merge by path, so two layers shipping
`prepare.d` would collapse into one copy.

## 2. build.mk

Model on `layers/full-featured/build.mk`:

```make
## <Name> VM layer build macros
$(call mk_include_guard,vm_layer_<name>)

VM_<NAME>_SCRIPTS_DIR ?= $(abspath $(FRAMEWORK_DIR)/layers/<name>/scripts)/
VM_<NAME>_SRC_FROM ?= base

define _vm_new_layer_<name>_tpl
$(call check-var,_vm_new_layer_generic_tpl)$(_vm_new_layer_generic_tpl)
$(1)-copy-scripts = $(abspath $(FRAMEWORK_DIR)/scripts)/
$(1)-copy-scripts += $$(VM_<NAME>_SCRIPTS_DIR)
$(1)-script-dirs = prepare-<name>.d
$(1)-src-from = $$(VM_<NAME>_SRC_FROM)
endef

# use with $(call vm_new_layer_<name>,vm-id)
vm_new_layer_<name> = $(eval $(_vm_new_layer_<name>_tpl))
```

- `$(call check-var,_vm_new_layer_generic_tpl)` first: the generic template
  holds the packer vars and defaults; without it this errors instead of
  half-working.
- Copy the framework `scripts/` dir in: the packer template runs
  `source $VM_SCRIPTS_DIR/lib/base.sh` unconditionally, and the source image
  only has whatever `lib/` was baked in by the base build. `full-featured` does
  the same thing (that is why `cloud`/`desktop-xfce`, which copy only their own
  dir, rely on the parent image).
- Optional per-VM overrides (defaults in parentheses): `-script-prepare`
  (`prepare-multistage.sh`), `-script-range1` (`1-19`), `-script-range2`
  (`1-4,20-99`), `-packer-args`, `-extra-envs`, `-pre-copy-cmd`, `-extra-rules`,
  `-deps`.
- Extra packer args look like:
  `$(1)-packer-args += $$(call _packer_var,qemu_vga,virtio)` (see
  `desktop-xfce`).

## 3. Register + wire

- `layers/inc_all.mk`: add the name to `VM_ALL_LAYERS`
  (currently `generic cloud full-featured desktop-xfce`).
- Consumer Makefile:

```make
$(call vm_new_layer_<name>,<vm>)
<vm>-name = $(vm-prefix)_<vm>
<vm>-src-from = base
<vm>-copy-scripts += $(abspath ./<vm>/scripts)/      # your own snippets
<vm>-script-dirs = prepare-<vm>.d:prepare-<name>.d   # yours FIRST (see below)
<vm>-deps = $(VM_<NAME>_SCRIPTS_DIR) $(abspath ./<vm>/scripts)
```

`<vm>-copy-scripts +=` is safe here because the layer macro already assigned the
list (framework + layer). If the layer did not, `=` must include
`<FRAMEWORK_DIR>/scripts/` itself.

`<vm>-script-dirs` **replaces** the default list — it does not append. Always
name the layer's dir too, ours first so our duplicate filenames shadow it.

Then add `"<vm>"` to `build-vms`, after its `src-from` dependency.

## 4. Snippets

Sourced by `prepare-multistage.sh` under `bash -e`, with `lib/base.sh` loaded:

```bash
#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## What this does.
sh_log_info "Installing ..."
@import 'debian/packages.sh'   # resolved from $VM_SCRIPTS_DIR/lib
```

- **No `set -e`** (already on). Scripts are *sourced*: `return 0` skips this
  file, `exit` aborts the whole stage.
- `NN-name.sh` is mandatory — the regex is `^NN[-_ ]` with exactly two digits.
  Anything else is logged `DISABLED (invalid filename)` and never runs.
- Ranges decide the stage, so pick `NN` accordingly:

| NN | stage | use |
|---|---|---|
| `01`–`04` | both | config vars, defaults, `pkg_init_update` |
| `10`–`19` | stage 1 | kernel / bootloader / networking; a reboot at the end is safe |
| `20`+ | stage 2 | package installs, services, users, cleanup (`90`) |

- Snippets from **all** listed dirs are sorted by filename into one sequence.
  Byte order matters: `01-init-full.sh` sorts *before* `01-init.sh`
  (`-` < `.`), so override flags from `02-*`, never `01-*`.
- Duplicate filenames: the **first** dir listed wins, the whole file is
  shadowed (logged as `Ignoring … (shadowed by an earlier dir)`). You can
  replace a snippet that way, but you cannot partially patch one.
- `sh_log_info/debug/error` for output, `sh_get_script_path` for your own dir,
  `vm_run_script "common-snippets.d/reboot"` for shared snippets.
- Static assets: keep `files/` next to the scripts and rsync it in, e.g.
  `rsync -rvh --chown=root "$(sh_get_script_path)/files/opt/<x>/" /opt/<x>/`.

**Extending `full-featured`:** reuse its feature flags instead of writing your
own installs. They are defaulted with `${VM_X:-…}` in `prepare-full.d/01-init-full.sh`,
so override them from a `02-*` snippet or via `<vm>-extra-envs`:
`VM_LEGACY_IFNAMES`, `VM_SYSTEM_TWEAKS`, `VM_INSTALL_TERM_TOOLS`,
`VM_INSTALL_NET_TOOLS`, `VM_INSTALL_DEV_TOOLS`, `VM_INSTALL_HACKING_TOOLS`,
`VM_INSTALL_DOCKER`, `VM_USER_TWEAKS`, `VM_USER_BASH_CONFIGS`,
`VM_USER_ZSH_CONFIGS`. Avoid `NN` collisions with
`01,10,11,15,19,25,30,31,32,37,90`.

## 5. Test

```sh
make @debug-rules              # generated rules + the exact packer command
make @print-<vm>-dest-image
make <vm>_clean <vm>           # full build (slow)
make <vm>_edit                 # fast: backing-file snapshot, PAUSE=1
make ssh                       # 2nd terminal, port 20022
make <vm>_commit               # persist edits into the layer image
make <vm> DEBUG_CONSOLE=1      # failing build: headless + serial/monitor
```

## Gotchas

- Snippet silently not running? Check, in order: filename prefix
  (`DISABLED (invalid filename)`), `NN` outside the stage range, dir missing
  from `<vm>-script-dirs`, dir missing from `-copy-scripts` (uploaded late →
  shadowed), duplicate filename in an earlier dir.
- `<vm>-script-dirs` replacing rather than appending is the single most common
  wiring bug — a VM that runs only your snippets and none of the layer's.
- Build deps default to `rwildcard(<vm>-packer-src)` = `layers/generic/`, so
  editing `layers/<name>/scripts/` does **not** retrigger a build without
  `<vm>-deps`.
- Never name your layer dir `prepare.d` — it is the (still supported) generic
  default and will merge with anything else using it.
- `<vm>-extra-envs` items are comma-terminated quoted strings:
  `"K=V", "K2=V2",`.
