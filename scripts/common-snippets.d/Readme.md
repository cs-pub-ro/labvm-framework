# VM Framework - Common provisioning scripts

This directory contains several common (but optional) Linux VM provisioning
snippets such as `reboot`, `ssh-authorized-keys` etc.

The snippets are synced into the base image by default, though they remain
inactive. Thus, you must manually cherry pick and run them inside a VM
provisioning stage.

## Usage

There are several ways to call snippets (all from the single `prepare.d` dir, 
selected by the stage ranges):

1. Copy / symlink the snippet into `prepare.d` with a `NN-` prefix matching the 
   stage you want (e.g., [generic 
   layer's](../../layers/generic/Readme.md) default second-stage range `20-99`).

2. Create a dummy script sourcing the snippet, e.g. `32-ssh-authorized-keys`
   containing:
    
    ```sh
    vm_run_script "common-snippets.d/ssh-authorized-keys"
    ```

Check out the [cloud](../../layers/cloud) layer or the [official 
template](../../example) for examples how to use them!

