# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import re
from enum import StrEnum
from pathlib import Path


def Data(source: Path) -> StrEnum:
    CLASS_RE = re.compile(r"\bclass\s+([A-Za-z_]\w*)\s+extends Base\b")
    CLASS_PARTS_RE = re.compile(r"(?<!^)(?=[A-Z])")
    LABEL_RE = re.compile(r"LABEL_(\w+)")

    items = []
    for data in source.iterdir():
        if not data.is_file():
            continue

        data_text = data.read_text()

        classMatch = CLASS_RE.findall(data_text)
        if not classMatch:
            continue

        assert len(classMatch) == 1
        classParts = [part.lower() for part in CLASS_PARTS_RE.split(classMatch[0])]

        labelMatch = LABEL_RE.findall(data_text)
        assert labelMatch
        assert len(labelMatch) == 1
        labelParts = [part.lower() for part in labelMatch[0].split("_")]

        assert classParts == labelParts, f"{classParts} vs {labelParts}"

        items.append("_".join(classParts).upper())

    return StrEnum(
        "Data", {item: str(index) for index, item in enumerate(sorted(items), start=1)}
    )
