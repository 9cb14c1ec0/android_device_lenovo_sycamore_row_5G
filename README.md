# android_device_lenovo_sycamore_row_5G

TWRP bring-up for the Lenovo Tab K11 Gen 2 5G (TB336ZA).

This is an early, experimental tree. There is no recovery image yet.

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
| Stock firmware tested | `17.0.10.541` (Android 15), `17.5.10.354` (Android 16) |

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
