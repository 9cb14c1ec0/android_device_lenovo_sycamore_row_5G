# Bootloader unlock: why sn.img is required

Summary of why this device cannot be unlocked with mtkclient/seccfg alone,
based on the stock LK, the dumped partitions, and mtkclient's code.

## The lock state is a standard MTK V4 seccfg

The dumped `seccfg` partition is a normal MTK V4 structure:

```
magic=0x4d4d4d4d ("MMMM")  ver=4  size=60  lock_state=1  critical_lock=0
end=0x45454545 ("EEEE")    + 32-byte SEJ hash
```

`lock_state=1` is locked (3 = unlocked). `lenovolock` is all zeros;
Lenovo only logs unlock *history* to RPMB (`write_region_data_for_unlock`
in LK). The boot gate is the standard seccfg (`sec_get_seccfg`,
"get lock state fail! set lock_state default lock!").

So flipping `lock_state` to 3 would unlock boot without `sn.img` -- if the
seccfg hash could be recomputed.

## Why seccfg can't be rewritten here

The hash is produced by the SEJ hardware engine (device-fused key).
Changing `lock_state` invalidates it, and the LK falls back to "locked"
on a hash mismatch. mtkclient recomputes the hash by poking SEJ registers
(`sej_base=0x1000a000`) through its **V6 DA extensions**
(`custom_read`/`custom_write`/`writeregister` in
`Library/DA/xml/extension/v6.py`, driving `Hardware/seccfg.py`).

Lenovo's signed DA (`DA_BR.bin`) rejects the extension payload
("DA XML Extensions failed"), so those register pokes are unavailable.
The hash can't be computed on the host (the key is in the SoC), and the
byte can't just be flipped. `mtk da seccfg unlock` therefore fails on
this device.

## Why BROM would be needed, and isn't available

Full memory access (to drive SEJ without the DA extension) needs a
bootrom exploit (kamakiri/carbonara) running a payload in BROM. MT6835
(hwcode 0x1209) has secure boot (`SBC=1`) and a patched bootrom:

- mtkclient never leaves preloader for BROM in our runs.
- Carbonara is rejected.
- A TB336FU owner (same MT6835/MT8755) reported "error sending the
  payload" with kamakiri; mtkclient issue #167 (MT8755) is unresolved.

## Why sn.img can't be forged or the LK patched

`sn.img` is a CMS/PKCS#7-style certificate (LK strings:
`id-smime-aa-timeStampToken`, `ICC or token signature`,
`unlock image signature check fail`) signed with Lenovo's private key and
bound to the bootloader SN. It is ~356 bytes: `1a2blenovo` magic + header
+ 64-char SN + RSA-2048 signature. No field is patchable without the key.

Patching the LK to skip the check fails too: with `SBC=1` the preloader
verifies the LK, so a modified LK is rejected before it runs. (The
TB305FU LK patch worked only because that tablet was already unlocked.)

## Conclusion

The signed `sn.img` is required. It is, however, available instantly from
Lenovo's CDN given the 64-char bootloader SN -- see `tools/fetch-sn-img.sh`
and the README. No email or wait is needed in practice.
