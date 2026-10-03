#!/bin/sh
# Called from BOARD_RECOVERY_IMAGE_PREPARE after the recovery root is
# assembled. ro.build.* cannot be set from a vendor property file, so stamp
# the stock OS version / patch level into /prop.default, which recovery
# init loads as a system source. Stock 17.5.10.354 is Android 16, patch
# 2026-08-05; KeyMint keys are bound to these values.
set -eu
root=${1:?}
prop=$root/prop.default
test -f "$prop"
set_prop() {
    name=$1 value=$2
    if grep -q "^${name}=" "$prop"; then
        sed -i "s|^${name}=.*|${name}=${value}|" "$prop"
    else
        printf '%s=%s\n' "$name" "$value" >> "$prop"
    fi
    grep -q "^${name}=${value}\$" "$prop"
}
set_prop ro.build.version.release 16
set_prop ro.build.version.release_or_codename 16
set_prop ro.build.version.release_or_preview_display 16
set_prop ro.build.version.security_patch 2026-08-05
# vold's FBE setup reads these before /data is mounted; TWRP cannot set
# ro.* later, so they must be in the initial property source.
set_prop ro.crypto.state encrypted
set_prop ro.crypto.type file

# The health HAL's VINTF fragment (type="device") sits under the framework
# directory /system/etc/vintf/manifest/, both in TWRP's build and in
# Lenovo's stock recovery CPIO. A device fragment there makes libvintf fail
# to assemble the framework manifest (UNKNOWN_ERROR), so servicemanager
# rejects keystore2's VINTF-declared IKeystoreService and keystore2 aborts.
# Deleting it is not enough: the stock CPIO comes first in vendor_boot and
# still provides it. Overwrite it with an empty framework fragment instead;
# the TWRP CPIO is extracted last, so this copy wins. Health itself is
# declared in /vendor/etc/vintf/manifest.xml.
health_frag="$root/system/etc/vintf/manifest/android.hardware.health-service.example.xml"
mkdir -p "$(dirname "$health_frag")"
printf '%s\n' '<manifest version="1.0" type="framework" />' > "$health_frag"
