$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/compression.mk)
$(call inherit-product, vendor/twrp/config/common.mk)
$(call inherit-product, device/lenovo/sycamore_row_5G/device.mk)

PRODUCT_DEVICE := sycamore_row_5G
PRODUCT_NAME := twrp_sycamore_row_5G
PRODUCT_BRAND := Lenovo
PRODUCT_MODEL := TB336ZA
PRODUCT_MANUFACTURER := LENOVO

# Same baseline as the TB305FU tree. Stock firmware is API 35, vendor API 33.
PRODUCT_SHIPPING_API_LEVEL := 31
PRODUCT_USE_DYNAMIC_PARTITIONS := true
