#!/bin/sh
# Build the TWRP recovery fragment and merge it into a stock vendor_boot.
#
#   source build/envsetup.sh
#   lunch twrp_sycamore_row_5G-ap2a-eng
#   device/lenovo/sycamore_row_5G/tools/build-vendor-boot.sh /path/to/stock/vendor_boot.img
#
# The stock image must come from the firmware that is installed on the
# tablet (17.5.10.354 for this tree). Output:
#   $OUT/vendor_boot-twrp.img
set -eu

stock=${1:?usage: $0 STOCK_VENDOR_BOOT_IMG}
top=${ANDROID_BUILD_TOP:?run lunch first}
out=${ANDROID_PRODUCT_OUT:?run lunch first}
device="$top/device/lenovo/sycamore_row_5G"
fragment="$out/obj/PACKAGING/vendor_ramdisk_fragments_intermediates/recovery.cpio.lz4"

test -f "$stock"
(cd "$top" && m vendorbootimage)
test -f "$fragment"

python3 "$device/tools/repack_vendor_boot.py" build \
    --avbtool "$top/out/host/linux-x86/bin/avbtool" \
    "$stock" "$fragment" "$out/vendor_boot-twrp.img"
sha256sum "$out/vendor_boot-twrp.img"
