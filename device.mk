LOCAL_PATH := device/lenovo/sycamore_row_5G

# The stock vendor ramdisk already provides lib/modules (including the
# Himax/Goodix/Novatek touch drivers in modules.load.recovery), the
# first-stage fstabs and init.recovery.mt6835.rc / mt8755.rc. TWRP's
# CPIO is appended to it by tools/repack_vendor_boot.py, so nothing here
# may replace those files.
