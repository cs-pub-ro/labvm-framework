# VM Framework - Ubuntu Base Layer

This layer builds a base Ubuntu Server 22.04 (for now) image from a live ISO, 
so make sure you download it and configure the ISO path inside [the appropriate
variable](./build.mk).

It uses the `base-debian.d` provisioning scripts (single stage, but with an
optional preparation script before).

If you wish to override the defaults, it is recommended you rename the default
VM name (from `ubuntu_$(ver)_base`).

Example makefile snippet using the built-in rules:
```Makefile
include $(FRAMEWORK_DIR)/base/ubuntu/build.mk

# creates the `base` VM (inherited by default by most layers)
$(call vm_new_base_ubuntu,base)
# e.g., override the name
#base-name = Ubuntu_$(base-ver)_custom
```
