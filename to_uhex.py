#!/usr/bin/env python3
"""
Convert a plain Intel hex (targeting nRF52833 on Micro:bit v2)
into a Micro:bit v2 Universal Hex that DAPLink will accept.
"""
import sys

V2_BOARD_ID = "9903"   # Micro:bit v2 board ID used by DAPLink
BLOCK_START_RECORD_TYPE = "0A"
BLOCK_END_RECORD_TYPE = "0B"

def ihex_checksum(record_bytes):
    s = sum(record_bytes) & 0xFF
    return (0x100 - s) & 0xFF

def make_record(byte_count, address, rec_type, data_hex):
    addr_hi = (address >> 8) & 0xFF
    addr_lo = address & 0xFF
    data_bytes = [int(data_hex[i:i+2], 16) for i in range(0, len(data_hex), 2)]
    raw = [byte_count, addr_hi, addr_lo, rec_type] + data_bytes
    cs = ihex_checksum(raw)
    body = "".join(f"{b:02X}" for b in raw)
    return f":{body}{cs:02X}"

def main(in_path, out_path):
    with open(in_path) as f:
        original_lines = [l.strip() for l in f if l.strip()]

    # Block Start record: marks the beginning of V2 data
    # Data = 2 bytes board ID
    block_start = make_record(2, 0, int(BLOCK_START_RECORD_TYPE, 16), V2_BOARD_ID)

    # Block End record: marks end of V2 data
    block_end = make_record(0, 0, int(BLOCK_END_RECORD_TYPE, 16), "")

    # Strip the EOF record (:00000001FF) from the original — we'll add one at the end
    payload = [l for l in original_lines if l.upper() != ":00000001FF"]

    output = [block_start] + payload + [block_end, ":00000001FF"]

    with open(out_path, "w") as f:
        f.write("\n".join(output) + "\n")

    print(f"Wrote {out_path} ({len(output)} records)")

if __name__ == "__main__":
    main("blink.hex", "blink-uhex.hex")
