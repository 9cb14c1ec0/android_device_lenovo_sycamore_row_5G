# Debugging a first TWRP boot

Channels available if `vendor_boot-twrp` misbehaves, roughly in order of
how far the boot got.

## 1. It shows the TWRP UI
The display stack (`mediatek-drm`, the `panel-*-sycamore` modules) loads
from the stock `modules.load.recovery`, so a visible TWRP UI is the
primary "it booted" signal.

- Touch not working / wrong coordinates: read raw kernel events over ADB
  with `adb shell getevent -lt` (toybox `getevent` is in the ramdisk).
  Three touch drivers load (`hx83102j`, `gt9896s`, `nt36523n`); the tested
  unit reports as `himax-touchscreen` (`hx83102j`). Compare against how
  TWRP interpreted them in `/tmp/recovery.log`. (`_EVENT_LOGGING` is a
  compile-time TWRP define with no board toggle in this tree; `getevent`
  is the equivalent and does not need a rebuild.)

## 2. Root ADB (main log channel)
The recovery ramdisk sets `ro.debuggable=1`, `ro.secure=0`,
`persist.sys.usb.config=adb`, and ships `adbd`. MTP is excluded
(`TW_EXCLUDE_MTP`) because on the TB336FU its startup flipped
`sys.usb.config` to `mtp,adb` and tore down the ConfigFS ADB gadget.

USB on this SoC is ConfigFS (`sys.usb.configfs 1`,
controller `11201000.usb0`, both set by the stock
`init.recovery.mt6835.rc`), not the legacy `android_usb` path TWRP's
default `init.recovery.usb.rc` writes to; those writes are harmless
no-ops and init's ConfigFS handling brings the gadget up. This is the
same configfs+controller pattern that gives the TB305FU working
persistent ADB, so it is expected to work here too.

```bash
adb devices                 # expect "recovery"
adb pull /tmp/recovery.log
adb shell dmesg > dmesg.txt
adb shell 'ls -la /sys/class/udc; cat /sys/class/udc/*/state'   # ConfigFS/UDC state
```

If ADB does not enumerate, check `/sys/class/udc/*/state` on the next
boot via the UI terminal, and see the TB336FU `tb336fu-usb-snapshot.sh`
approach.

## 3. Black screen / bootloop / kernel panic (no ADB)
MediaTek writes the LK boot trace and the last kernel `ram_console` to
the **`expdb`** partition, and crash data to `pstore` / `mrdump`. These
survive a reboot and can be dumped with mtkclient (no unlock needed),
using the Lenovo DA in stock mode:

```bash
cd mtkclient
.venv/bin/python mtk.py rl /tmp/dbg \
    --stock --loader <fw>/image/download_agent/DA_BR.bin \
    --skip userdata
# then, after catching preloader (adb reboot):
strings -n 8 /tmp/dbg/expdb.bin   | less   # LK trace + ram_console
strings -n 8 /tmp/dbg/pstore.bin  | less
```

Verified: a stock `expdb` dump contains `boot_linux_fdt`,
`jump to linux kernel`, `ram_console`, and timestamped `NOTICE:` lines.

## 4. Always-recoverable
- Only `vendor_boot_a` is flashed; **slot B stays stock and bootable**.
  `fastboot set_active b` (or let A fail past its retry count) boots
  stock.
- mtkclient can rewrite `vendor_boot_a` with the stock
  `vendor_boot.img` from the firmware package to undo any test image.

## Escalation if a boot stage blocks on SELinux
The tree runs enforcing (as the TB305FU did). If denials block touch
module loading or USB bring-up, add device `sepolicy/recovery.te` allows
(see the TB305FU tree) rather than disabling SELinux.
