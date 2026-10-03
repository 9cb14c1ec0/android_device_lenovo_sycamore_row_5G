LOCAL_PATH := device/lenovo/sycamore_row_5G

# The stock vendor ramdisk already provides lib/modules (including the
# Himax/Goodix/Novatek touch drivers in modules.load.recovery), the
# first-stage fstabs and init.recovery.mt6835.rc / mt8755.rc. TWRP's
# CPIO is appended to it by tools/repack_vendor_boot.py, so nothing here
# may replace those files.

# Recovery-only init scripts, wrappers, properties and VINTF manifests.
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/recovery/root,$(TARGET_COPY_OUT_RECOVERY)/root)

# Beanpod (Microtrust) TEE, KeyMint 2.0 and HIDL gatekeeper from stock
# 17.5.10.354 vendor, plus the VNDK v33 libraries those blobs need and
# recovery does not provide (keymint-V2-ndk, sharedsecret/secureclock-V1-ndk)
# or that are not ABI-stable across releases (libcrypto). Installed under
# the recovery /vendor so the stock paths (/vendor/thh/ta, /vendor/lib64/hw)
# resolve unchanged.
PRODUCT_COPY_FILES += \
    $(call find-copy-subdir-files,*,$(LOCAL_PATH)/prebuilt/crypto/vendor,$(TARGET_COPY_OUT_RECOVERY)/root/vendor)
