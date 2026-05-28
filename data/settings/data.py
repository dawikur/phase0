# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import re
from pathlib import Path
from typing import List

from .model import Token


def listData(source: Path) -> List[Token]:
    CLASS_RE = re.compile(r"\bclass\s+([A-Za-z_]\w*)\s+extends Base\b")
    CLASS_PARTS_RE = re.compile(r"(?<!^)(?=[A-Z])")
    LABEL_RE = re.compile(r"LABEL_(\w+)")

    result = []

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

        result.append(Token(" ".join(classParts)))

    return sorted(result)
