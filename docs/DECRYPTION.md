# /data decryption

Stock `/data` is metadata-encrypted (dm-default-key) with FBE v2
(`aes-256-xts` contents, `aes-256-cts:v2+inlinecrypt_optimized` filenames),
keyed by the Beanpod (Microtrust) TEE. The keys are reachable only through
KeyMint 2.0 (AIDL) and a HIDL `gatekeeper@1.0`. TWRP runs that whole stack
itself, in the `recovery` domain, and uses its in-process vold to unwrap
user 0's keys. There is no lockscreen PIN, so the default credential is used.

## What ships in the recovery ramdisk

- `prebuilt/crypto/vendor/` — the stock `17.5.10.354` vendor binaries and
  their dependencies, installed under the recovery `/vendor` so the stock
  paths resolve unchanged:
  - `bin/teei_daemon`, `bin/hw/android.hardware.security.keymint@2.0-service.beanpod`,
    `bin/hw/android.hardware.gatekeeper@1.0-service`
  - `lib64/hw/{gatekeeper.beanpod.so, android.hardware.gatekeeper@1.0-impl.so}`
    and the vendor keymaster/keymint support libraries
  - `thh/ta/*` — the TEE trusted applets
  - VNDK v33 libraries recovery does not provide:
    `android.hardware.security.{keymint-V2,secureclock-V1,sharedsecret-V1}-ndk.so`
    and `libcrypto.so`
- `recovery/root/system/etc/init/tb336za-crypto.rc` — starts the TEE,
  KeyMint and gatekeeper, and mounts `/mnt/vendor/persist` for the TEE.
- `recovery/root/system/bin/tb336za_*.sh` — launch wrappers that set
  `LD_LIBRARY_PATH` and, for the TEE, wait for "Keymaster Unlocked".
- `recovery/root/{system,vendor}/etc/vintf/manifest.xml` — framework and
  device VINTF manifests declaring keystore2 and the crypto HALs.

`stamp-recovery-props.sh` stamps OS 16 / security patch `2026-08-05` and
`ro.crypto.*` into `prop.default`; the FBE keys are bound to that patch
level, and the Beanpod TEE applies it once per session.

## SELinux

The crypto HALs and keystore2 run as `u:r:recovery:s0`. The platform policy
only lets declared HAL domains register these services, so
`patches/system_sepolicy.patch` adds a `hal_attribute_service_recovery`
macro (and a gatekeeper hwservice / vendor-property equivalent) that also
exempts recovery. Device `sepolicy/recovery.te` grants the TEE device
nodes, the service-manager and keystore2 access, vold's metadata/FBE
access, and the `vendor.soter.*` TEE handshake properties.

## Boot-ordering issues worked around

1. **vndservicemanager hijacks the context manager.** As a coredomain,
   recovery cannot open `/dev/vndbinder`; vndservicemanager then falls back
   to `/dev/binder` and becomes the context manager first, so the real
   servicemanager loops on "Could not become context manager".
   `tb336za-crypto.rc` redefines the service to `/system/bin/true`.
2. **A stray device VINTF fragment breaks the framework manifest.** Both
   TWRP and the stock recovery ship `android.hardware.health-service.example.xml`
   (type `device`) under the framework dir `/system/etc/vintf/manifest/`.
   libvintf then fails to assemble the framework manifest, so servicemanager
   rejects keystore2's declared `IKeystoreService` and keystore2 aborts.
   The stock CPIO is extracted first, so deleting the file does not help;
   `stamp-recovery-props.sh` overwrites it with an empty framework manifest.
3. **KeyMint blocks on the TEE handshake.** The HAL waits for
   `vendor.soter.teei.init=INIT_OK`; `tb336za_teei_wait.sh` polls dmesg for
   "Keymaster Unlocked" before the HAL starts.

## Known-benign denials

`ro.crypto.fs_crypto_blkdev` / `ro.crypto.metadata.enabled` cannot be set
from recovery; TWRP falls back to `/dev/block/mapper/userdata`, so
decryption still succeeds.
