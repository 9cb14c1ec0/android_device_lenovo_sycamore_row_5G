#!/system/bin/sh
# HIDL passthrough service: loads android.hardware.gatekeeper@1.0-impl.so,
# which loads gatekeeper.beanpod.so via libhardware (ro.hardware.gatekeeper).
export LD_LIBRARY_PATH=/vendor/lib64/hw:/vendor/lib64:/system/lib64
exec /vendor/bin/hw/android.hardware.gatekeeper@1.0-service
