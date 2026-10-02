# android_device_lenovo_sycamore_row_5G

TWRP bring-up for the Lenovo Tab K11 Gen 2 5G (TB336ZA).

This is an early, experimental tree. No image has been tested on
hardware yet. The first goal is TWRP UI, touch and ADB; `/data`
decryption comes later.

## Device

| Item | Value |
| --- | --- |
| Device | Lenovo Idea Tab / Lenovo Tab K11 Gen 2 (5G) |
| Model | TB336ZA |
| Codename / board | `sycamore_row_5G` |
| Platform | MediaTek MT6835 (Dimensity 6300), reported as `mt8755` |
| Storage | UFS |
| Kernel | GKI 5.15 (`android13-5.15`) |
| Boot layout | Boot header v4, `boot` + `init_boot` + `vendor_boot`, A/B, virtual A/B |
| Recovery location | `vendor_boot` (no `recovery` partition) |
| Touch (tested unit) | Himax `hx83102j` (`himax-touchscreen`) |
| Display | 1600x2560, 320 dpi |
| Target firmware | `17.5.10.354` |

## Building

The tree targets TWRP 14.1 and the stock `17.5.10.354` firmware.

```bash
# in a TWRP 14.1 source tree, with this repo at device/lenovo/sycamore_row_5G
source build/envsetup.sh
lunch twrp_sycamore_row_5G-ap2a-eng
device/lenovo/sycamore_row_5G/tools/build-vendor-boot.sh /path/to/stock/vendor_boot.img
```

The result is `$OUT/vendor_boot-twrp.img`.

Stock `vendor_boot` has a single unnamed PLATFORM ramdisk: one
LZ4-legacy CPIO holding both the first-stage vendor ramdisk and Lenovo's
stock recovery. `tools/repack_vendor_boot.py` keeps the stock header,
DTB and AVB footer properties, and appends the TWRP recovery CPIO after
the stock CPIO. TWRP files replace stock recovery files, while the stock
kernel modules, first-stage fstab and `init.recovery.mt6835.rc` stay in
place. The stock first-stage init loads `modules.load.recovery`, which
already includes the touch drivers (`hx83102j`, `gt9896s`, `nt36523n`)
and the display stack.

`prebuilt/kernel` and `prebuilt/dtb` are taken unmodified from the stock
`17.5.10.354` `boot.img` and `vendor_boot.img`.

## Bootloader unlock

The bootloader needs a Lenovo-signed, device-specific `sn.img`; plain
`fastboot flashing unlock` is not enough. The LK checks the image's
signature and serial number ("unlock image signature check fail",
"bootloader unlock sn check fail").

1. Read the bootloader SN: `fastboot getvar all` prints
   `Bootloader_SN_Part1` and `Bootloader_SN_Part2`; concatenate them
   (64 hex characters).
2. Request `sn.img` from Lenovo at https://m.zui.com/iunlock. It is
   emailed, and is also published at
   `http://cdn.zui.lenovomm.com/developer/enhancedboot/<SN>/sn.img`.
3. In the bootloader:
   ```bash
   fastboot flash unlock sn.img
   fastboot oem unlock   # do not reboot between the two commands
   ```
   Confirm on the tablet. This wipes `userdata`.

The `sn.img` is tied to one tablet and cannot be reused on another.

## Download agent

`prebuilt/download_agent/` contains Lenovo's signed MediaTek download agent
(`DA_BR.bin`) and `da.auth`, taken unmodified from the official firmware
package `TB336ZA_ROW_OPEN_USER_M1317.3_W_ZUI_17.5.10.354_ST_260804`.
Checksums are in `prebuilt/download_agent/SHA256SUMS`.

The device has secure boot and DA authentication enabled (target config
`0x5`: SBC on, SLA off, DAA on). mtkclient's bundled DA has no MT6835
loader, but Lenovo's DA is accepted by the preloader.

Use it with [mtkclient](https://github.com/bkerler/mtkclient) in stock mode:

```bash
python mtk.py printgpt --stock --loader prebuilt/download_agent/DA_BR.bin
```

Run the command first, then connect the tablet in preloader mode, for
example with `adb reboot` while it is plugged in.

`--stock` is required. Without it, mtkclient tries to load its DA
extensions; Lenovo's DA rejects them and then stops answering, so reads
fail with "Error reading gpt".

If a run fails partway, the tablet stays in preloader with the watchdog
disabled. Unplug USB and hold power + volume up for about 20 seconds to
restart it.

## License

`DA_BR.bin` and `da.auth` are Lenovo/MediaTek proprietary files and are
not covered by any license in this repository.
