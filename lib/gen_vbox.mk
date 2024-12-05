# Makefile templates to generate VirtualBox VM project files

## <vm>-specific (placeholder for VM's ID + goal) variables and their defaults
-vbox-name = $(call _def_value,$(vm)-vmname,$(-vm-name))
-vbox-ostype = $(call _def_value,$(vm)-ostype,Ubuntu_64)
-vbox-ramsize = $(call _def_value,$(vm)-ramsize,2048)
-vbox-vcpus = $(call _def_value,$(vm)-vcpus,2)
-vbox-ssh-nat = $(call _def_value,$(vm)-ssh-nat,10022)
# <vm>-src-image: take source image from another file (when ! <vm>-source-from)
-vbox-src-vmdk = $(strip $(if $(-vm-source-from),\
			$(let vm,$(-vm-source-from),$($(vm)-vmdk-file)),\
			$(call _def_value,$(vm)-src-image,$(vm).vmdk)))
# generate random UUID & MAC
-vbox-machine-uuid = $(shell uuidgen)
-vbox-mac-addr = $(shell printf '080027%02X%02X%02X\n' $$[RANDOM%256] $$[RANDOM%256] $$[RANDOM%256])

define vbox-prj-template=
<?xml version="1.0"?>
<!-- Generated by vm-framework -->
<VirtualBox xmlns="http://www.virtualbox.org/" version="1.19-linux">
  <Machine uuid="{$(-vbox-machine-uuid)}" name="$(-vbox-name)" OSType="$(-vbox-ostype)" 
  	  snapshotFolder="Snapshots" lastStateChange="$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")">
    <MediaRegistry>
      <HardDisks>
        <HardDisk uuid="{{{TEMPLATE_DISK_UUID}}}" location="$(notdir $($(vm)-vbox-dest-vmdk))" 
          format="VMDK" type="Normal"/>
      </HardDisks>
    </MediaRegistry>
    <Hardware>
      <Memory RAMSize="$(-vbox-ramsize)"/>
      <HID Pointing="USBTablet"/>
      <Display controller="VMSVGA" VRAMSize="16"/>
      <Firmware/>
      <BIOS>
        <IOAPIC enabled="true"/>
        <SmbiosUuidLittleEndian enabled="true"/>
        <AutoSerialNumGen enabled="true"/>
      </BIOS>
      <USB>
        <Controllers>
          <Controller name="OHCI" type="OHCI"/>
          <Controller name="EHCI" type="EHCI"/>
        </Controllers>
      </USB>
      <Network>
        <Adapter slot="0" enabled="true" MACAddress="$(-vbox-mac-addr)" type="82540EM">
          <NAT localhost-reachable="true">
            <Forwarding name="SSH" proto="1" hostport="$(-vbox-ssh-nat)" guestport="22"/>
          </NAT>
        </Adapter>
      </Network>
      <AudioAdapter codec="AD1980" useDefault="true" driver="ALSA" enabled="false" enabledOut="true"/>
      <Clipboard/>
      <StorageControllers>
        <StorageController name="IDE" type="PIIX4" PortCount="2" useHostIOCache="true" Bootable="true">
          <AttachedDevice passthrough="false" type="DVD" hotpluggable="false" port="1" device="0"/>
        </StorageController>
        <StorageController name="SATA" type="AHCI" PortCount="1" useHostIOCache="false" 
            Bootable="true" IDE0MasterEmulationPort="0" IDE0SlaveEmulationPort="1" 
            IDE1MasterEmulationPort="2" IDE1SlaveEmulationPort="3">
          <AttachedDevice type="HardDisk" hotpluggable="false" port="0" device="0">
            <Image uuid="{{{TEMPLATE_DISK_UUID}}}"/>
          </AttachedDevice>
        </StorageController>
      </StorageControllers>
      <RTC localOrUTC="UTC"/>
      <CPU count="$(-vbox-vcpus)">
        <HardwareVirtExLargePages enabled="false"/>
        <PAE enabled="false"/>
        <LongMode enabled="true"/>
        <X2APIC enabled="true"/>
      </CPU>
    </Hardware>
  </Machine>
</VirtualBox>
endef

define vm_gen_vbox_prj_rule=
$(vm)-vbox-prj := $(-vm-dest-dir)/$(-vm-name).vbox
$$($(vm)-vbox-prj): $$($(vm)-vbox-dest-vmdk)
	mkdir -p "$(-vm-dest-dir)"
	echo "$$$$$(call normalize_id,_VM_VBOX_DATA__$(vm))" > "$$@"
	@echo "Assigning disk UUID..." && set -x; \
	UUID_RAW=$$$$(VBoxManage internalcommands sethduuid "$$($(vm)-vbox-dest-vmdk)" 2>&1) && \
	UUID_EXTRACT=$$$$(echo -n "$$$$UUID_RAW" | \
				 grep -Po '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}') && \
	[[ -n "$$$$UUID_EXTRACT" ]] || exit 1 && \
	sed -i -e 's/{{TEMPLATE_DISK_UUID}}/'"$$$$UUID_EXTRACT"'/g' "$$@"

export $(call normalize_id,_VM_VBOX_DATA__$(vm)):=$$(vbox-prj-template)

endef

# use vm-type = vbox to generate them
define vm_gen_vbox_rules=
.PHONY: $(vm) $(vm)_clean
#@ $(vm) VirtualBox project build goal
$(vm)-vbox-dest-vmdk := $(-vm-dest-dir)/$(-vm-name).vmdk
$$($(vm)-vbox-dest-vmdk): $(-vbox-src-vmdk)
	mkdir -p "$(-vm-dest-dir)"
	cp -f "$$<" "$$@"
$(vm_gen_vbox_prj_rule)
$(vm): $$($(vm)-vbox-dest-vmdk) $$($(vm)-vbox-prj)

$(vm)_clean:
	rm -rf "$(-vm-dest-dir)"

endef

