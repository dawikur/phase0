# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import re
from enum import IntEnum
from pathlib import Path


def Data(source: Path) -> IntEnum:  # pylint: disable=invalid-name
    class_re = re.compile(r"\bclass\s+([A-Za-z_]\w*)\s+extends Base\b")
    class_parts_re = re.compile(r"(?<!^)(?=[A-Z])")
    label_re = re.compile(r"LABEL_(\w+)")

    items = []
    for data in source.iterdir():
        if not data.is_file():
            continue

        data_text = data.read_text()

        class_match = class_re.findall(data_text)
        if not class_match:
            continue

        assert len(class_match) == 1
        class_parts = [part.lower() for part in class_parts_re.split(class_match[0])]

        label_match = label_re.findall(data_text)
        assert label_match
        assert len(label_match) == 1
        label_parts = [part.lower() for part in label_match[0].split("_")]

        assert class_parts == label_parts, f"{class_parts} vs {label_parts}"

        items.append("_".join(class_parts).upper())

    return IntEnum(
        "Data", {item: index for index, item in enumerate(sorted(items), start=1)}
    )
