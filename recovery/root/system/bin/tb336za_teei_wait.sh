#!/system/bin/sh
# Wait (up to ~10 s) for the TEE to report "Keymaster Unlocked" before the
# KeyMint HAL starts talking to it.
i=0
while [ "$i" -lt 50 ]; do
    dmesg | grep -q "Keymaster Unlocked" && exit 0
    sleep 0.2
    i=$((i + 1))
done
exit 0
