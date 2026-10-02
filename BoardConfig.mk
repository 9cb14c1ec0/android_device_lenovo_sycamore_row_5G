# Lenovo Tab K11 Gen 2 5G (TB336ZA, sycamore_row_5G), MediaTek MT6835.
# Early bring-up configuration, derived from stock firmware 17.5.10.354.

DEVICE_PATH := device/lenovo/sycamore_row_5G

BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# MT6835: 2x Cortex-A76 + 6x Cortex-A55.
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a55
TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55
TARGET_SUPPORTS_64_BIT_APPS := true

TARGET_BOARD_PLATFORM := mt6835
TARGET_BOOTLOADER_BOARD_NAME := sycamore_row_5G
TARGET_NO_BOOTLOADER := true

# Stock GKI 5.15.197-android13 kernel from boot.img (LZ4) and stock DTB
# from vendor_boot.img. The final image keeps the stock DTB either way.
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilt
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_KERNEL_IMAGE_NAME := Image

# Values from the stock vendor_boot v4 header.
BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_BASE := 0x40000000
BOARD_KERNEL_OFFSET := 0x00000000
BOARD_RAMDISK_OFFSET := 0x26f00000
BOARD_TAGS_OFFSET := 0x07c80000
BOARD_DTB_OFFSET := 0x07c80000
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2
BOARD_MKBOOTIMG_ARGS := --header_version 4 --kernel_offset $(BOARD_KERNEL_OFFSET) \
    --ramdisk_offset $(BOARD_RAMDISK_OFFSET) --tags_offset $(BOARD_TAGS_OFFSET) \
    --dtb_offset $(BOARD_DTB_OFFSET)
BOARD_RAMDISK_USE_LZ4 := true

BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608
BOARD_DTBOIMG_PARTITION_SIZE := 8388608
BOARD_FLASH_BLOCK_SIZE := 262144

# super is 0x2c0000000 bytes in the stock GPT.
BOARD_SUPER_PARTITION_SIZE := 11811160064

AB_OTA_UPDATER := true
AB_OTA_PARTITIONS := \
    boot \
    dtbo \
    init_boot \
    odm_dlkm \
    product \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor \
    vendor \
    vendor_boot \
    vendor_dlkm
BOARD_USES_METADATA_PARTITION := true
BOARD_BUILD_SUPER_IMAGE_BY_DEFAULT := false

# No recovery partition. The build emits a recovery ramdisk fragment for
# vendor_boot; tools/build-vendor-boot.sh merges it into the stock
# single-entry vendor ramdisk.
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
TARGET_NO_RECOVERY := true

TARGET_USERIMAGES_USE_F2FS := true
TARGET_USERIMAGES_USE_EXT4 := true
BOARD_HAS_LARGE_FILESYSTEM := true

# Recovery UI. Panel is 1600x2560 portrait at 320 dpi.
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_SCREEN_WIDTH := 1600
TARGET_SCREEN_HEIGHT := 2560
TW_THEME := portrait_hdpi
# hall_irq is the cover sensor. The pen digitizer (lenovo-stylus) should
# be ignored too, but soong cannot pass the \x0a separator TWRP expects.
# TODO: blacklist lenovo-stylus once there is a working way to list two.
TW_INPUT_BLACKLIST := "hall_irq"
# TODO: confirm the backlight node and range on hardware before setting
# TW_BRIGHTNESS_PATH / TW_MAX_BRIGHTNESS.

TW_INCLUDE_FASTBOOTD := true
# TB336FU bring-up showed TWRP's MTP startup switching sys.usb.config to
# an unsupported mtp,adb and dropping ADB. Keep MTP out until that is fixed.
TW_EXCLUDE_MTP := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_LIBRESETPROP := true
TW_USE_TOOLBOX := true

# First milestone is UI, touch and ADB. /data uses metadata encryption
# plus FBE v2 with a Beanpod TEE; decryption comes later, following the
# TB305FU crypto work.
TW_EXCLUDE_ENCRYPTED_BACKUPS := true
TW_SKIP_ADDITIONAL_FSTAB := true

TWRP_INCLUDE_LOGCAT := true
TARGET_USES_LOGD := true
TW_DEVICE_VERSION := TB336ZA-alpha1
