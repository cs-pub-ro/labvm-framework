---
name: new-labvm-project
description: Bootstrap or migrate a lab/course VM project on top of labvm-framework with the framework as a git submodule — Makefile (base + full-featured layer + vm-combo export + cloud), config.sample.mk, labvm/scripts/prepare-<vm>.d snippets, cloud overrides, and agent-doc/skill wiring. Use when starting a new VM project that consumes the framework, or when upgrading an existing one (RL-lab-vm, ISC-lab-vm style) to the current prepare-multistage architecture.
---

# New lab VM project (consumer of labvm-framework)

Goal: a standalone repo where `make labvm` builds a course VM, `make cloud`
builds its cloud-init variant, and `make localvm` exports VirtualBox/VMware.

## 0. Layout

```
<project>/
├── Makefile
├── config.sample.mk            # committed template
├── config.local.mk             # untracked, user's ISO paths/secrets
├── .gitignore
├── .gitmodules
├── framework/                  # git submodule -> labvm-framework
├── labvm/scripts/prepare-<vm>.d/NN-*.sh
├── labvm/scripts/files/…       # optional static assets
└── cloud/scripts/prepare-cloud.d/NN-*.sh   # overrides, merges with the layer's dir
```

```sh
git submodule add https://github.com/cs-pub-ro/labvm-framework.git framework
```

Every snippet dir needs a **unique name** (`prepare-labvm.d`, not `prepare.d`):
uploaded dirs merge by path, so two layers shipping the same name collapse into
one. `prepare-cloud.d` is the deliberate exception — it is the cloud layer's own
name, and reusing it is how you add overrides (see §5).

## 1. Makefile

```make
## Makefile for <Project> lab VMs
FRAMEWORK_DIR ?= ./framework
include $(FRAMEWORK_DIR)/framework.mk
include $(FRAMEWORK_DIR)/lib/inc_all.mk

DEFAULT_GOAL = labvm
INIT_GOAL = labvm
SUDO ?= sudo                          # used by the zerofree rule

# base image (see skill `new-vm-base` for other distros)
$(call vm_new_base_debian,base)
base-ver = 13

labvm-ver = $(LABVM_VERSION)$(ARCH_SUFFIX)
labvm-prefix = MY_$(labvm-ver)

# the lab VM: full-featured layer + our snippets
$(call vm_new_layer_full_featured,labvm)
labvm-name = $(labvm-prefix)
labvm-src-from = base
labvm-copy-scripts += $(abspath ./labvm/scripts)/
labvm-script-dirs = prepare-labvm.d:prepare-full.d   # ours first (shadows on name clash)
labvm-pre-copy-cmd = rm -rf thirdparty
labvm-deps = $(VM_FULL_FEATURED_SCRIPTS_DIR) $(abspath ./labvm/scripts)
labvm-extra-rules += $(vm_zerofree_rule)

# VirtualBox + VMware export of the same image
localvm-name = $(labvm-prefix)_Local
localvm-type = vm-combo
localvm-vmname = <Project> $(labvm-ver) VM
localvm-src-from = labvm
localvm-extra-rules += $(vm_zerofree_rule)

# cloud-init variant
$(call vm_new_layer_cloud,cloud)
cloud-name = $(labvm-prefix)_cloud
cloud-src-from = labvm
cloud-copy-scripts = $(abspath $(FRAMEWORK_DIR)/scripts)/   # cloud's macro copies only its own dir
cloud-copy-scripts += $(VM_CLOUD_SCRIPTS_DIR)
cloud-copy-scripts += $(abspath ./cloud/scripts)/
cloud-extra-envs = "MY_CLOUD_ADMIN_PASSWORD=$(MY_CLOUD_ADMIN_PASSWORD)",
cloud-extra-rules += $(vm_zerofree_rule)

# dependency order matters
build-vms = base labvm localvm cloud
$(call vm_eval_all_rules)
```

Why each non-obvious line:
- `labvm-copy-scripts +=` is enough: `vm_new_layer_full_featured` already
  assigns `<FRAMEWORK_DIR>/scripts/` + the layer's scripts (a derived VM needs
  the framework `lib/` even though the base image carries a copy — otherwise it
  runs whatever was baked in when the base was built).
- `labvm-script-dirs` **replaces** the layer default (`prepare-full.d`); list
  both dirs or all framework snippets silently stop running. This is the #1
  wiring bug.
- `labvm-deps` — build deps default to `rwildcard(layers/generic)`, so editing
  your snippets would not rebuild the VM.
- `labvm-pre-copy-cmd = rm -rf thirdparty` — git submodules land read-only;
  packer's upload cannot overwrite them. It runs *inside* the VM before upload.
- `cloud-extra-envs` items are comma-terminated quoted strings; the value is a
  plain env var inside the VM.
- `$(ARCH_SUFFIX)` in the prefix keeps x86_64/aarch64 images from colliding
  (empty for x86_64).
- `vm_new_layer_cloud` defaults `src-from = main`; always override it.

## 2. config.sample.mk + .gitignore

```make
# Copy to config.local.mk (untracked) and edit.
LABVM_VERSION = 2026.01
BASE_ISO_DIR ?= $(HOME)/Downloads/iso
#BUILD_DIR ?= /media/ssd/packer
#VM_AUTHORIZED_KEYS = $(abspath dist/authorized_keys)
#MY_CLOUD_ADMIN_PASSWORD = change-me
```

`config.local.mk` is auto-included from `USER_CONFIG_DIR` (default `.`), so the
Makefile needs no include. Values are make syntax: `$(HOME)`, no quotes.

```
# .gitignore
config.local.mk
dist/
```

## 3. labvm/scripts/prepare-\<vm\>.d/

`NN-name.sh`, sourced under `bash -e` with `lib/base.sh` loaded:

```bash
#!/bin/bash
[[ -n "$__INSIDE_VM_RUNNER" ]] || { echo "Only call within VM runner!" >&2; return 1; }
## <what and why>
sh_log_info "…"
```

Stage selection is by `NN` prefix, ranges `1-19` (stage 1) and `1-4,20-99`
(stage 2). Slot your numbers around the framework's, which are
`01,10,11,15,19,25,30,31,32,37,90`:

| NN | stage | use |
|---|---|---|
| `02` | both | project vars + feature-flag overrides |
| `12`, `18` | 1 | networking, kernel cmdline |
| `26`, `29` | 2 | after docker: services, extra repos |
| `35`, `42`, `45` | 2 | tools, extra user, project payload |
| `60` | 2 | user tweaks / dotfiles |
| `92` | 2 | extra cleanup |

Two rules that decide whether your overrides work:

- Names sort byte-wise across **all** dirs, so `01-init-full.sh` runs *before*
  `01-init.sh` (`-` < `.`). Never override flags from an `01-*` file — use `02-*`.
- A duplicate filename is shadowed **whole** by the first dir listed; you can
  replace a framework snippet, not partially patch it.

Feature flags (defaulted with `${VM_X:-…}` in `prepare-full.d/01-init-full.sh`):
`VM_INSTALL_DOCKER`, `VM_INSTALL_DEV_TOOLS`, `VM_INSTALL_NET_TOOLS`,
`VM_INSTALL_TERM_TOOLS`, `VM_INSTALL_HACKING_TOOLS`, `VM_LEGACY_IFNAMES`,
`VM_SYSTEM_TWEAKS`, `VM_USER_TWEAKS`, `VM_USER_BASH_CONFIGS`,
`VM_USER_ZSH_CONFIGS`.

Static assets: `rsync -rvh --chown=root "$(sh_get_script_path)/files/opt/<x>/"
/opt/<x>/`. Large content (labs, dotfiles) belongs in its own submodule under
`thirdparty/`, which is exactly what `pre-copy-cmd` clears.

## 4. First build

```sh
git submodule update --init --recursive
cp config.sample.mk config.local.mk     # point BASE_ISO_DIR at your ISO
make init
make @debug-rules                       # sanity-check the generated rules
make base                               # slow, unattended install
make labvm
make labvm_edit && make ssh             # fast iteration, port 20022
make labvm_commit
make cloud
```

## 5. Cloud overrides

`cloud/scripts/prepare-cloud.d/` deliberately reuses the layer's dir name, so
the files merge into `/opt/vm-scripts/prepare-cloud.d/` and the layer's
`-script-dirs = prepare-cloud.d` picks them up — **no `-script-dirs` change**.
Keep your dir **last** in `cloud-copy-scripts` so same-named files win.

Use distinct `NN` names (`02-`, `37-`, `45-`, `91-`) to add behaviour, or an
identical filename to replace a framework snippet outright. Typical content:
admin/root password from `$(MY_CLOUD_ADMIN_PASSWORD)`,
`sshd_config.d/20-admin-auth.conf` with `PasswordAuthentication yes`, console
security, zswap disable, cloud-init clean.

Cloud-layer knobs read in `prepare-cloud.d/01-init.sh`: `VM_PASSWORD`,
`VM_SSH_PASSWORD_AUTH`, `VM_SSH_LEGACY_ALGS`, `VM_CONSOLE_SECURITY`.

For a bigger override that must *shadow* the layer rather than merge, use a
unique dir name and prepend it: `cloud-script-dirs = prepare-cloud-x.d:prepare-cloud.d`.

## 6. Agent docs + skills

```sh
mkdir -p .agents && ln -s ../framework/.agents/skills .agents/skills
```

Skills are discovered through `.agents/skills/`, so the symlink suffices. For
`AGENTS.md`, write a small real file (a symlink leaves you nowhere to put
project deltas):

```markdown
# <Project> VM
Framework rules live in `framework/.agents/AGENTS.md` — read them first;
everything there applies. Project specifics:
- base is Debian 13, layer `labvm` = full-featured + `prepare-labvm.d`
- used NN slots: 02, 35, 42, 92
```

## 7. Migrating an old project to master

The old shape was `<prefix>-prepare.sh` + `full-snippets.d/` + `install-stage*.d`.
Master has one shared runner and range selection, so:

1. `git mv labvm/scripts/full-snippets.d labvm/scripts/prepare-<vm>.d`
2. Delete `<prefix>-prepare.sh` (it only called the now-removed
   `full-prepare.sh`) and drop `<vm>-script-prepare`.
3. Add `<vm>-script-dirs = prepare-<vm>.d:prepare-full.d`.
4. `git mv cloud/scripts/install-cloud.d cloud/scripts/prepare-cloud.d`
   (`install-*.d` is legacy: still scanned only if listed, and logged as legacy).
5. Keep your `-copy-scripts` additions (`thirdparty`, override dirs) — but make
   sure the framework `scripts/` dir is in the list; `full-featured` now adds it,
   `cloud` does not.
6. Re-check feature-flag names after the bump:
   ```sh
   git -C framework fetch && git -C framework checkout <sha>
   grep -roh 'VM_[A-Z0-9_]*' framework/layers/*/scripts | sort -u
   ```
   Compare with what your snippets set — that is the usual breakage, together
   with `NN` numbers that moved between stage ranges.
7. `make @debug-rules` and confirm `<vm>-script-dirs` lists every dir that has
   snippets, then `make labvm_clean labvm`.

## Gotchas

- `make base` is the seed for `/opt/vm-scripts/` in every derived VM; a stale
  base means stale `lib/`. Rebuild it after `scripts/lib/` changes, or rely on
  the explicit `<FRAMEWORK_DIR>/scripts/` entry.
- Never commit `config.local.mk` (ISO paths, mirrors, passwords).
- `vm-combo` export (`localvm`) is a separate VM that only produces
  `.vmdk`/`.ovf`; it is slow and needs the parent image present.
- `vm_zerofree_rule` needs `qemu-nbd` + `sudo`; `ZEROFREE_PART_NUM` defaults to
  `2`, which is wrong for images with a separate `/boot`.
- Deleting only the `.qcow2` leaves `<dest>/.exists` behind; use
  `make <vm>_clean`.
