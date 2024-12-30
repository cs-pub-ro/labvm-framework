# Virtual Machine framework (qemu + Packer)

This repository contains `vm-framework`, a bundle of libraries and scripts for 
generating Virtual Machines (originally for virtual labs / development, but they 
could be used to build VMs for any purpose) using `qemu` and
[Packer](https://packer.io/).

**Features:**

 - automatic (unattended) installation of base VM images for popular Linux
   distributions (Ubuntu, Debian);
 - Makefile-based macros & scripts for a declarative, layer-based approach to 
   build/edit VM images (powered by qemu's [qcow2 backing
   files](https://kashyapc.fedorapeople.org/virt/lc-2012/snapshots-handout.html)
   feature to optimize development time!);
 - bash-based modules for building streamlined Linux VM provisioning scripts
   (e.g., installing & configuring the required packages);
 - lots of snippets & comprehensive examples (also see projects using it below);
 - well documented & tested (hopefully);
 - flexible, easily embeddable (recommended: as git submodule);

**Requirements:**

 - a modern Linux system;
 - basic build tools (make);
 - [Hashicorp's Packer](https://packer.io/);
 - [qemu+kvm](https://qemu.org/);

## Getting started

Clone the project (although you might wish to use git submodules, see below):

```sh
git clone https://github.com/cs-pub-ro/labvm-framework.git vm-framework
cd vm-framework  # enter the directory
```

Although the project provides a standalone [`Makefile`](./Makefile) for 
configuring & building [a base VM](./base/ubuntu/Readme.md), we'll jump directly 
to the [example](./example/).

So first, let's download and save a [Ubuntu 22.04 Live Server 
install .iso](https://ubuntu.com/download/server) for your architecture
(e.g., `amd64`, but careful not to mistake the `arm64` image).

Next, create an empty `config.local.mk` (see [`config.default.mk`](./config.default.mk)
for a list of variables). We only need to set one right now: the path to your 
downloaded ISO image: `BASE_VM_INSTALL_ISO=$HOME/<path-to-your-iso>` (no
quotes! it's a Make script).

Optionally, you may want to change `BUILD_DIR` to point somewhere else on your 
machine with at least 20GB free space on a fast storage device (SSD recommended).
It defaults to `$HOME/.cache/packer`.

Now go to the [example](./example/) directory and proceed to build some VMs:
```sh
# hopefully, you're inside the framework's directory
cd ./example
# we must first initialize Packer (to install qemu plugin):
make init
# let's build the base image, then the main layer
make base main  # if something went wrong, see the *_clean rules
# for a fully featured VM (cloud-init image), try these targets:
make full full_cloud
```

We could've just issued `make full_cloud` and it should have built all 
dependencies in order (`base`, then `full`).

Let's take a quick look at the makefile code giving the above behavior:

```Makefile 
# instantiate an Ubuntu base layer, which we'll just name `base` :D
# this is what provides the `make base` goal!
$(call vm_new_base_ubuntu,base)

# next, we make the `main` target:
$(call vm_new_layer_generic,main)
# this will be used for the output image directory + file names
# the `vm-prefix` variable was defined above and evaluates to "example_2024.01"
main-name = $(vm-prefix)_main
# take the source layer from `base`; this is the default, so was ommitted from
# the example Makefile:
main-src-from = base
# there are other overridable vars. in the form of the `<VM_TARGET>-*`, e.g.:
main-copy-scripts += $(abspath ./main/scripts)/
```

_Note: the makefile includes are important too, but we're not pasting them here._

Similarly, we can instantiate other kinds of layers:

```Makefile
# create the `full` VM from the fully-featured layer (yes, we have such thing!)
$(call vm_new_layer_full_featured,full)
full-name = $(vm-prefix)_full
```

If we ever want to export the main VM for VMWare, there's a macro available
(our example uses the `vm-combo` exported, which builds projects for VMWare AND
VirtualBox using the same image ;) ):

```Makefile
exported-name = $(vm-prefix)_exported
exported-vmname = Example VM Project
exported-type = vmware  # use vm-combo for both VMware + VBox
exported-src-from = main
```

You should see it by now: we simply create Makefile variables having the form:
`<VM_TARGET>-property = value` (there are some predefined properties, such as
`name`, `type`, `src-from` and many other type-specific ones!).

The `vm_new_*` macros simply do just this (: check out [base layer's 
`build.mk`](./base/ubuntu/build.mk))!

Hope you're not having [Yocto](https://docs.yoctoproject.org/) vibes :D
Just kidding!

Now, there is one more thing... at the bottom of the `Makefile`, we have this:

```Makefile
build-vms = base main full exported full_cloud
$(call vm_eval_all_rules)
```

Yep, we MUST list our TARGETs and invoke the framework's rule generator macro.
Now this is the actual magic glue holding all pieces together!

## VM Derivation / Customization

If you wish to create or customize virtual machine images using the framework,
you have several options: fork/directly modify this repository or include it as 
git submodule (recommended):

```sh
git submodule init
git submodule add https://github.com/cs-pub-ro/labvm-framework.git framework
cp -ar framework/example/* ./
```

Afterwards, you must modify the Makefile and make `FRAMEWORK_DIR` point to the
framework's relative directory, see:
[example Makefile](./example/Makefile) and the
[generic layer](./layers/generic/Readme.md)!

Also check out other projects using it:

- [Computer Networks Lab VM](https://github.com/cs-pub-ro/RL-lab-vm);
- [Introduction to CyberSecurity Lab VM](https://github.com/cs-pub-ro/ISC-lab-vm);
- [Windows 10 VM ;)](https://github.com/niflostancu/packer-windows-vm) (WIP).


## Framework Architecture

The framework has the following three main components:

- The [**Makefile framework**](./framework.mk), used to create declarative VM 
  generation rules (and other artifacts);

- The [**VM provisioning framework**](./scripts/) consisting of modular bash 
  scripts and ready to use snippets for deterministically installing &
  configuring stuff during the VM building process;

- The **layers**, each containing or inheriting a Packer script, categorized 
  into [base layers](./base/) and well, just [layers :D ](./layers/) meant to 
  be used on top of others. Each layer has a couple of provisioning `scripts/`
  and some helper Makefile variables + macros inside a `build.mk` file.

### Base images

For a list of base images, [please see this directory](./base/)
(each one should contain a readme).

If you don't see your favorite distro in there, PRs are always welcome ;)

### Layers

The following layers are available (each documented inside their own directories):

- The [generic layer](./layers/generic): used as starting point for all the 
  others, it consists of a predefined Packer script taking in variables to 
  further customize the provisioning scripts executed inside the Packer VM;
  needless to say, it should be sufficient for most cases, but you can always 
  take its [Packer script](./layers/generic/build.pkr.hcl) and modify it to 
  your heart's desire!

- A [cloud layer](./layers/cloud) providing a default cloud-init configuration 
  for OpenStack and EC2 compatible VMs; yep: you can override scripts / 
  configuration files as desired.

- A [full-featured layer](./layers/full-featured) installing many Linux
  CS / developer-centric packages!

_WIP / soon to have: GUI (Desktop Environment) layers_

### Snippets

For a list and description of the common snippets available, see [this
document](./scripts/common-snippets.d).

### Framework Reference

Note that this framework was meant to be used by developers, which are usually 
expected to delve into the code to fully understand its inner workings
before proceeding (:, so this should only serve as starting guide to using the
most common features:

### Makefile goals

For each declared VM layer (e.g., `base` / `main` / `full`), a Makefile goal 
with the same name is defined by the framework macros, plus several other
utility rules:

- `<VM>` (e.g.: `base`): builds the VM image using Packer;
- `<VM>_edit`: easily edit an already built VM (uses the base image as backing
  snapshot);
- `<VM>_commit`: commits the edited VM back to its original image;
- `<VM>_clean`: removes the generated image(s);
- `ssh`: SSH-es into a running Packer VM (via forwarded port 10022);
- `@debug-*`: used for debugging framework-generated make rules.

If Packer complains about the output file existing, you must delete the
generated VM (either using the `<VM>_clean` rule, or manually), or set the
`FORCE=1` makefile variable (but be careful, since this might also delete
generated dependencies like the `base` image):
```sh
make main FORCE=1
```

If you want to keep the install scripts at the end of the provisioning phase,
set the `DEBUG` variable. Also check out `PAUSE` (it pauses packer,
letting you inspect the VM using qemu console / `ssh`):
```sh
make base_edit PAUSE=1 DEBUG=1
# then, in another terminal:
make ssh
```

### Target-specific variables

TODO _(there's no shame in that, is it?)_

### Target Types

TODO

### Makefile variables

TODO

