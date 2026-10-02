#!/usr/bin/env python3
"""Build a TWRP vendor_boot for the TB336ZA from a stock vendor_boot.

Stock vendor_boot v4 on this device has exactly one unnamed PLATFORM
ramdisk entry. That entry is one LZ4-legacy stream holding a single newc
CPIO with both the first-stage vendor ramdisk (lib/modules, fstab) and
Lenovo's stock recovery.

The output keeps the stock header fields, DTB and empty bootconfig, and
replaces the ramdisk with one LZ4-legacy stream of two concatenated CPIO
archives: the stock CPIO followed by the TWRP recovery CPIO. The kernel
extracts them in order, so TWRP files replace stock recovery files while
everything TWRP does not ship (modules, first-stage fstab, stock
init.recovery.*.rc) is kept.

The AVB hash footer is re-added with the stock salt and properties.

  repack_vendor_boot.py info IMAGE
  repack_vendor_boot.py build STOCK RECOVERY OUTPUT [--avbtool PATH]

RECOVERY is a newc CPIO, optionally LZ4 compressed (legacy or frame),
for example out/.../vendor_ramdisk_fragments_intermediates/recovery.cpio.lz4.
"""

import argparse
import hashlib
import re
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

MAGIC = b"VNDRBOOT"
LZ4_LEGACY = b"\x02\x21\x4c\x18"
LZ4_FRAME = b"\x04\x22\x4d\x18"
CPIO_NEWC = b"070701"
PLATFORM = 1
TYPES = {1: "PLATFORM", 2: "RECOVERY", 3: "DLKM"}


def align(n, a):
    return (n + a - 1) // a * a


class VendorBoot:
    def __init__(self, path):
        d = path.read_bytes()
        if d[:8] != MAGIC:
            raise ValueError(f"{path}: not a vendor_boot image")
        version, self.page = struct.unpack_from("<II", d, 8)
        if version != 4:
            raise ValueError(f"{path}: vendor_boot header v{version}, expected v4")
        ramdisk_size = struct.unpack_from("<I", d, 24)[0]
        self.header_size, dtb_size = struct.unpack_from("<II", d, 2096)
        table_size, count, self.entry_size, bootconfig_size = struct.unpack_from("<IIII", d, 2112)
        roff = align(self.header_size, self.page)
        doff = align(roff + ramdisk_size, self.page)
        toff = align(doff + dtb_size, self.page)
        boff = align(toff + table_size, self.page)
        self.header = bytearray(d[:self.header_size])
        self.ramdisk = d[roff:roff + ramdisk_size]
        self.dtb = d[doff:doff + dtb_size]
        self.bootconfig = d[boff:boff + bootconfig_size]
        self.entries = []
        for i in range(count):
            rec = d[toff + i * self.entry_size:toff + (i + 1) * self.entry_size]
            size, off, kind = struct.unpack_from("<III", rec, 0)
            name = rec[12:44].split(b"\0", 1)[0].decode(errors="replace")
            self.entries.append((size, off, kind, name))
        self.cmdline = self.header[28:28 + 2048].split(b"\0", 1)[0].decode()

    def image(self, ramdisk):
        header = bytearray(self.header)
        struct.pack_into("<I", header, 24, len(ramdisk))
        struct.pack_into("<IIII", header, 2112, self.entry_size, 1,
                         self.entry_size, len(self.bootconfig))
        record = bytearray(self.entry_size)
        struct.pack_into("<III", record, 0, len(ramdisk), 0, PLATFORM)
        out = bytearray()
        for part in (header, ramdisk, self.dtb, record, self.bootconfig):
            out += part
            out += b"\0" * (align(len(out), self.page) - len(out))
        return bytes(out)


def lz4_cli(args, data):
    return subprocess.run(["lz4", *args], input=data, stdout=subprocess.PIPE,
                          check=True).stdout


def to_cpio(data, what):
    if data.startswith(LZ4_LEGACY) or data.startswith(LZ4_FRAME):
        data = lz4_cli(["-dc"], data)
    if not data.startswith(CPIO_NEWC):
        raise ValueError(f"{what}: not a newc CPIO (starts with {data[:8].hex()})")
    return data


def avb_footer(avbtool, image):
    info = subprocess.run([avbtool, "info_image", "--image", str(image)],
                          stdout=subprocess.PIPE, text=True, check=True).stdout
    salt = re.search(r"Salt:\s+([0-9a-f]+)", info).group(1)
    size = int(re.search(r"^Image size:\s+(\d+)", info, re.M).group(1))
    props = re.findall(r"Prop: (\S+) -> '(.*)'", info)
    return salt, size, props


def cmd_info(args):
    vb = VendorBoot(args.image)
    data = args.image.read_bytes()
    print(f"file:       {args.image}")
    print(f"size:       {len(data)}")
    print(f"sha256:     {hashlib.sha256(data).hexdigest()}")
    print(f"page size:  {vb.page}")
    print(f"cmdline:    {vb.cmdline}")
    print(f"dtb size:   {len(vb.dtb)}")
    print(f"bootconfig: {len(vb.bootconfig)} bytes")
    for i, (size, off, kind, name) in enumerate(vb.entries):
        print(f"ramdisk[{i}]: type={TYPES.get(kind, kind)} name={name!r} "
              f"size={size} offset={off} magic={vb.ramdisk[off:off + 4].hex()}")
    return 0


def cmd_build(args):
    stock = VendorBoot(args.stock)
    if len(stock.entries) != 1 or stock.entries[0][2] != PLATFORM:
        raise ValueError("stock vendor_boot must have exactly one PLATFORM ramdisk")
    if not stock.ramdisk.startswith(LZ4_LEGACY):
        raise ValueError("stock ramdisk is not LZ4 legacy")
    stock_cpio = to_cpio(stock.ramdisk, "stock ramdisk")
    recovery_cpio = to_cpio(args.recovery.read_bytes(), str(args.recovery))
    ramdisk = lz4_cli(["-l", "-12", "-c"], stock_cpio + recovery_cpio)
    if not ramdisk.startswith(LZ4_LEGACY):
        raise ValueError("lz4 did not produce a legacy stream")

    salt, partition_size, props = avb_footer(args.avbtool, args.stock)
    image = stock.image(ramdisk)
    if len(image) > partition_size:
        raise ValueError(f"image is {len(image)} bytes, partition is {partition_size}")

    with tempfile.NamedTemporaryFile(dir=args.output.parent, delete=False) as tmp:
        tmp.write(image)
    tmp_path = Path(tmp.name)
    footer = [args.avbtool, "add_hash_footer", "--image", str(tmp_path),
              "--partition_name", "vendor_boot",
              "--partition_size", str(partition_size), "--salt", salt]
    for key, value in props:
        footer += ["--prop", f"{key}:{value}"]
    subprocess.run(footer, check=True)
    tmp_path.replace(args.output)

    print(f"stock cpio:    {len(stock_cpio)} bytes")
    print(f"recovery cpio: {len(recovery_cpio)} bytes")
    print(f"ramdisk lz4:   {len(ramdisk)} bytes")
    cmd_info(argparse.Namespace(image=args.output))
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("info")
    p.add_argument("image", type=Path)
    p.set_defaults(func=cmd_info)
    p = sub.add_parser("build")
    p.add_argument("stock", type=Path)
    p.add_argument("recovery", type=Path)
    p.add_argument("output", type=Path)
    p.add_argument("--avbtool", default="avbtool")
    p.set_defaults(func=cmd_build)
    args = ap.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
