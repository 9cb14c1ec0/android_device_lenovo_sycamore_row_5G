#!/system/bin/sh
# init's setenv does not reliably reach vendor binaries through the
# recovery linker config, so set the library path here and exec.
# Recovery's own libbinder_ndk is used; only vendor-specific and VNDK v33
# libraries are shipped in /vendor/lib64.
export LD_LIBRARY_PATH=/vendor/lib64:/system/lib64
exec /vendor/bin/hw/android.hardware.security.keymint@2.0-service.beanpod
