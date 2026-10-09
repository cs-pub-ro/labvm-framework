# VM Framework - Cloud Layer

Layer to install & setup `cloud-init` configuration for deploying cloud images.

Should use it as a final layer, since SSH may not work after that (e.g., 
key-based authentication is forced by default scripts if not configured
otherwise).

## Provisioning scripts

This layer is based on the [../generic/Readme.md](Generic) one, using the same
single `prepare.d` provisioning dir and the two-stage numeric ranges (if using the
default [build.mk](./build.mk) macro values).

The cloud scripts actually configure `cloud-init` for OpenStack
/ EC2-compatible data sources. A couple of common modules are enabled,
especially custom scripts and SSH key authorization.

A couple of configuration variables are available if your cloud setup is
atypical, check out [./scripts/prepare.d/01-init.sh](01-init.sh) (you are
able to override them by inserting a new script, e.g., `02-overrides.sh`).

## Usage

Include the layer's `.mk`, and call the `vm_new_layer_cloud` macro:

```Makefile
include $(FRAMEWORK_DIR)/layers/generic/build.mk
include $(FRAMEWORK_DIR)/layers/cloud/build.mk

# creates the `cloud` VM using defaults
$(call vm_new_layer_cloud,cloud)
# override the name and source scripts
cloud-name = $(examplevm-name)_cloud
# Like most layers, the *-copy-scripts is a list:
#cloud-copy-scripts += $(abspath ./my-prepare.sh) $(abspath ./overrides)/
```
