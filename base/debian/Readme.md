# VM Framework - Debian Base Layer

This layer builds a base Debian 12 image from a netinst ISO, download it and 
configure the ISO path using [the `DEBIAN_12_ISO` variable](./build.mk).

It uses the `base-debian.d` provisioning scripts (single stage, but with an
optional preparation script before).

If you wish to override the defaults, it is recommended you rename the default
VM name (from `debian_$(ver)_base`).

Example makefile snippet using the built-in rules:
```Makefile
include $(FRAMEWORK_DIR)/base/debian/build.mk

# creates the `base` VM (inherited by default by most layers)
$(call vm_new_base_debian,base)
# e.g., override the name
#base-name = Debian_$(base-ver)_custom
```
