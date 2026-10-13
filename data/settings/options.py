# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from enum import IntEnum
from zlib import crc32


class StableOptions(IntEnum):
    """Assign name-based IDs in the positive signed 32-bit range."""

    @staticmethod
    def _generate_next_value_(
        name: str, _start: int, _count: int, last_values: list[int]
    ) -> int:
        # Keep automatic IDs away from small numeric settings and data IDs.
        value = 0x40000000 | (crc32(name.encode("utf-8")) & 0x3FFFFFFF)
        if value in last_values:
            raise ValueError(f"Option ID collision for {name}: {value}")
        return value
