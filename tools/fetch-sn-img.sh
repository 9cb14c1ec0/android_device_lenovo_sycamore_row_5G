#!/bin/sh
# Fetch the Lenovo-signed bootloader unlock certificate (sn.img) for a
# TB336ZA from Lenovo's CDN, using the device's bootloader serial.
#
# Read the SN from the device first (in fastboot):
#   fastboot getvar Bootloader_SN_Part1 Bootloader_SN_Part2
# then concatenate the two 32-char halves into one 64-char string.
#
#   ./fetch-sn-img.sh <64-char-SN> [output.img]
set -eu
sn=${1:?usage: $0 <64-char bootloader SN> [output]}
out=${2:-sn.img}
case ${#sn} in 64) ;; *) echo "SN must be 64 hex chars, got ${#sn}"; exit 1;; esac
url="http://cdn.zui.lenovomm.com/developer/enhancedboot/$sn/sn.img"
curl -fSL -o "$out" "$url"
# A valid image starts with the Lenovo magic and is a few hundred bytes.
head -c 16 "$out" | grep -q '1a2blenovo' || { echo "Not a valid sn.img (bad magic). Request one at https://m.zui.com/iunlock"; exit 1; }
echo "Wrote $out ($(wc -c < "$out") bytes)"
sha256sum "$out"
