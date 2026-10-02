# Stock firmware analysis

Notes from the stock images. `.541` is `17.0.10.541` (Android 15, dumped
from the tablet with mtkclient); `.354` is `17.5.10.354` (Android 16,
official Lenovo package). This tree targets `.354`.

## Boot images

| | `.541` | `.354` |
| --- | --- | --- |
| Kernel | `5.15.170-android13-8-00003-g9a0b9d56c900-ab13225392` | `5.15.197-android13-8-00005-g2d8ad9139b89-ab15063902` |
| `boot` | v4, kernel only (LZ4), AVB signed | same |
| `init_boot` | v4, generic ramdisk | same |
| `vendor_boot` | v4, 1 unnamed PLATFORM ramdisk, LZ4 legacy | same |
| Vendor cmdline | `bootopt=64S3,32N2,64N2` | same |
| DTB size | 192119 | 192119 |
| Bootconfig | empty | empty |

`vendor_boot` load addresses: kernel `0x40000000`, ramdisk
`0x66f00000`, tags/DTB `0x47c80000`, page size 4096.

The AVB footer on `vendor_boot` is an unsigned hash descriptor
(algorithm NONE, verified through `vbmeta`) with one property,
`com.android.build.vendor_boot.fingerprint`.

## Vendor ramdisk

One CPIO containing both the first-stage vendor ramdisk and Lenovo's
stock AOSP recovery:

- `lib/modules/`: 208 modules. `modules.load` has 179 entries;
  `modules.load.recovery` has 197.
- `modules.load.recovery` includes the touch drivers `hx83102j`,
  `gt9896s` and `nt36523n` (not in `modules.load`), the display stack
  (`mediatek-drm`, `mtk_panel_ext`, five `panel-*-sycamore-90hz-drv`
  panels) and `leds-mtk-disp`.
- `first_stage_ramdisk/fstab.mt6835` (identical to `fstab.mt8755`).
- `init.recovery.mt6835.rc` (identical to `init.recovery.mt8755.rc`):
  sets `sys.usb.configfs 1` and `sys.usb.controller 11201000.usb0`,
  creates the preloader and `dm-userdata` symlinks and runs
  `mtk_plpath_utils`.
- Stock recovery binaries include `recovery`, `fastbootd`, `adbd`,
  `minadbd`, `snapuserd` and `update_engine_sideload`.
- `prop.default` carries the vendor_boot fingerprint
  `Lenovo/TB336ZU/TB336ZU:15/AP3A.240905.015.A2/260804_354` (the
  vendor ramdisk is shared with the TB336ZU).

## Storage and encryption

From `fstab.mt6835`:

- Logical partitions in `super`: `system`, `system_ext`, `vendor`,
  `product`, `vendor_dlkm`, `odm_dlkm`, `system_dlkm`, all EROFS (ext4
  fallback entries exist).
- `/metadata`: f2fs on `by-name/metadata`.
- `/data`: f2fs, metadata encryption plus FBE v2:
  `fileencryption=aes-256-xts:aes-256-cts:v2+inlinecrypt_optimized`,
  `keydirectory=/metadata/vold/metadata_encryption`, `fsverity`.
- Lenovo partitions: `lenovocust` (ext4), `lenovoraw`, `lenovosku_1/2`,
  `lenovolock`.

## Partition versions (`.354`)

| | Release | SDK | Security patch |
| --- | --- | --- | --- |
| system | 16 (`BP2A.250605.031.A3`) | 36 | 2026-08-05 |
| vendor | 13 | 33 | 2026-08-05 |
| boot / init_boot | 13 (GKI) | | 2024-05-05 |

## Crypto stack (`.354` vendor)

- `android.hardware.security.keymint@2.0-service.beanpod`
  (`vendor.keymint-beanpod`, class `early_hal`)
- `android.hardware.gatekeeper@1.0-service` (HIDL)
- `teei_daemon` (Microtrust/Beanpod TEE, started from `microtrust.rc`)

This differs from the TB305FU, which uses Beanpod Keymaster 4.1. For
decryption, recovery will probably have to report OS 16 and patch level
2026-08-05 to match the stock key parameters.

## Hardware seen on the tested unit

- Touch: `himax-touchscreen` (`hx83102j`)
- Other inputs: `hall_irq` (cover sensor), `lenovo-stylus`,
  `mtk-pmic-keys`, `mtk-kpd`, headset jack
- Display: 1600x2560, 320 dpi
- Storage: UFS, user LU 0x1dcb000000 bytes; 8 GB RAM

## Preloader / download agent

Target config `0x5`: SBC on, SLA off, DAA on. Memory read and write
auth are off. Lenovo's `DA_BR.bin` is accepted, and mtkclient works with
`--stock --loader prebuilt/download_agent/DA_BR.bin`; see the README.
