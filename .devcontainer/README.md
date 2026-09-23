# Devcontainer with packer + qemu (Debian-based)

Development container for VSCode users and/or AI agent integration.

Host KVM is passed through with `--device /dev/kvm` (if available, see reqs 
below); `postCreateCommand` prints `KVM: OK` or `KVM: MISSING` accordingly.

Built images land in the host's `~/.cache/packer`, bind-mounted into the
container (see `mounts` in `devcontainer.json`), so they persist on the host
across container rebuilds.

## Host requirements & fixes

- **Linux + Docker + `/dev/kvm`** (check with `ls -l /dev/kvm`).
- **WSL2**: works if the kvm module is loaded in WSL (`sudo modprobe kvm_intel`
  or `kvm_amd`); then `--device /dev/kvm` picks it up as usual.
- **Mac (Docker Desktop)**: no KVM available.... revert to TCG emulation
  via `config.local.mk`:
  ```make
  PACKER_ARGS_EXTRA ?= -var qemu_accelerator=tcg
  ```

## Notes

- `make ssh` (port 20022) works from inside the container — qemu forwards it to
  the container's localhost.
