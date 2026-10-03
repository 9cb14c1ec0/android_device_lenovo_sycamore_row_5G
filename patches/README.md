# Platform patches

Changes to AOSP/TWRP platform projects needed for this device tree, on top
of the TWRP 14.1 (`twrp-14.1` manifest) tree. Apply with `git apply` in each
project, or re-create from the committed device tree.

- `system_sepolicy.patch` — recovery-domain SELinux for the Beanpod
  crypto HALs: a `hal_attribute_service_recovery` macro, its use for the
  KeyMint 2.0 / RemotelyProvisionedComponent / SecureClock / SharedSecret
  AIDL services, a recovery exemption on the HIDL gatekeeper hwservice,
  and recovery exemptions on the vendor-property `set` neverallows (the
  Beanpod TEE handshake props `vendor.soter.*`).

The generic recovery crypto enablement in `system/vold`, `system/security`,
`system/logging` and `build/make` is shared with the Lenovo TB305FU tree
(`android_device_lenovo_clove_row_wifi`) and is unchanged here.
