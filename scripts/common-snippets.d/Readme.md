# VM Framework - Common provisioning scripts

This directory contains several common (but optional) Linux VM provisioning
snippets such as `reboot`, `ssh-authorized-keys` etc.

The snippets are synced into the base image by default, though they remain
inactive. Thus, you must manually cherry pick and run them inside a VM
provisioning stage.

## Usage

There are several ways to call snippets:

1. Symlink them to your preferred stage's directory (e.g., [generic 
   layer's](../../layers/generic/Readme.md) `install-stage2.d`) using your 
   preparation script (`vm-prepare.sh`). This makes the actual ordering of the
   stage scripts somewhat harder to understand...

2. Create a dummy script sourcing the snippet, e.g. `32-ssh-authorized-keys`
   containing:
    
    ```sh
    vm_run_script "common-snippets.d/ssh-authorized-keys"
    ```

Check out the [cloud](../../layers/cloud) layer or the [official 
template](../../example) for examples how to use them!

