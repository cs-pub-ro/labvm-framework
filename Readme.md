# CS Labs virtual machine framework

This repository contains a base framework and scripts for generating Lab
VMs using `qemu` and Packer (check the requirements below).

**Features:**

 - automatic generation of Ubuntu-based VM images;
 - Makefile rules for a consistent development workflow;
 - customizable & embeddable (recommended: as git submodule);

**Base requirements:**

 - a modern Linux system;
 - basic build tools (make);
 - [Hashicorp's Packer](https://packer.io/);
 - [qemu+kvm](https://qemu.org/);

## Base image preparation

Download and save a [Ubuntu 22.04 Live Server install](https://ubuntu.com/download/server) `.iso` cd image.

Optionally, create `config.local.mk`, copy the variables from
[`config.default.mk`](./config.default.mk) and edit them to your liking.

You may want to set the path to your downloaded Ubuntu Server `.iso` on your
disk (`BASE_VM_INSTALL_ISO`) and, optionally, change `BUILD_DIR` somewhere with
at least 10GB free space on a fast + large drive (SSD recommended :P).

Finally, run: `make init` to ensure that all required Packer plugins are installed.

## Makefile usage

The following VMs are defined in the base framework (see the [Makefile](./Makefile)):

- `basevm`: automatically installs a base Ubuntu VM from a live ISO (with
  `student:student` credentials);
- `cloudvm`: builds a cloud-init VM, cleaned up and readily integrated with
  cloud VMs (e.g., OpenStack).

For each declared VM layer (e.g., `basevm`), a Makefile goal with the same name
is defined by the `framework.mk`, plus several other utility rules:

- `<VM>` (e.g.: `basevm`): builds the VM image using Packer;
- `<VM>_edit`: easily edit an already built VM (uses the base image as backing
  snapshot);
- `<VM>_commit`: commits the edited VM back to its original image;
- `<VM>_clean`: removes the generated image(s);
- `ssh`: SSH-es into a running Packer VM (via forwarded port 10022);
- `@debug`: used for debugging framework-generated make rules.

If packer complains about the output file existing, you must delete the
generated VM (either using the `<VM>_clean` rule, or manually), or set the
`FORCE=1` makefile variable (but be careful):
```sh
make basevm FORCE=1
```

If you want to keep the install scripts at the end of the provisioning phase,
set the `DEBUG` variable. Also check out `PAUSE` (it pauses packer,
letting you inspect the VM using qemu console / `ssh`):
```sh
make basevm_edit PAUSE=1 DEBUG=1
```

## Derivation & Customization

If you want to create your own custom VMs using this as base image, it is
you can either fork this repository or include it as git submodule
(recommended):

```sh
git submodule init
git submodule add https://github.com/cs-pub-ro/labvm-framework.git framework
cp -r framework/template/* ./
```

Afterwards, you must modify the Makefile and make `FRAMEWORK_DIR` point to the
framework's relative directory (see TODOs inside the template), see:
[packer file](./template/examplevm/example.pkr.hcl) &
[provisioning scripts](./template/examplevm/scripts/)!

Also check out other VM projects using it:

- [Computer Networks Lab VM](https://github.com/cs-pub-ro/RL-lab-vm)
- [Introduction to CyberSecurity Lab VM](https://github.com/cs-pub-ro/ISC-lab-vm)

