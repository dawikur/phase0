# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import re
from dataclasses import dataclass, field
from enum import auto
from pathlib import Path
from typing import Any, Callable, Iterator, cast

from .options import StableOptions, stable_id


@dataclass(frozen=True)
class Datum:
    name: str
    value: int = field(init=False)

    has_icon: bool
    has_value_max: bool
    is_status: bool = False

    def __post_init__(self) -> None:
        object.__setattr__(self, "value", stable_id(f"DATA_{self.name}"))


class Source:
    CLASS_PARTS_RE = re.compile(r"(?<!^)(?=[A-Z])")
    CLASS_RE = re.compile(r"\bclass\s+([A-Za-z_]\w*)\s+extends Base\b")
    ANNOTATIONS_RE = re.compile(
        r"\((\s*:\w+(?:\s*,\s*:\w+)*\s*)\)\s*class\s+\w+\s+extends Base\b"
    )
    LABEL_RE = re.compile(r"LABEL_(\w+)")

    __items: list[Datum]

    def __init__(self, source: Path):
        items = []
        for data in source.iterdir():
            if not data.is_file():
                continue
            data_text = data.read_text()

            class_match = self.CLASS_RE.findall(data_text)
            if not class_match:
                continue
            assert len(class_match) == 1

            class_parts = [
                part.lower() for part in self.CLASS_PARTS_RE.split(class_match[0])
            ]
            file_parts = data.stem.split("_")

            assert class_parts == file_parts, f"{class_parts} vs {file_parts}"

            label_match = self.LABEL_RE.findall(data_text)
            assert label_match
            assert len(label_match) == 1

            label_parts = [part.lower() for part in label_match[0].split("_")]

            assert class_parts == label_parts, f"{class_parts} vs {label_parts}"

            annotation_match = self.ANNOTATIONS_RE.search(data_text)
            annotations = (
                set(re.findall(r":(\w+)", annotation_match.group(1)))
                if annotation_match
                else set()
            )

            items.append(
                (
                    "_".join(class_parts).upper(),
                    "data_icon" in annotations,
                    "data_gauge" in annotations,
                    "data_status" in annotations,
                )
            )

        self.__items = [
            Datum(name, *args)
            for name, *args in sorted(items, key=lambda item: item[0])
        ]
        ids: set[int] = set()
        for datum in self.__items:
            if datum.value in ids:
                raise ValueError(f"Metric ID collision for {datum.name}: {datum.value}")
            ids.add(datum.value)

    @property
    def all(self) -> Any:
        return self.__filter("DataAll", lambda _: True)

    @property
    def status(self) -> Any:
        return self.__filter("DataStatus", lambda d: d.is_status)

    @property
    def with_icon(self) -> Any:
        return self.__filter("DataWithIcon", lambda d: d.has_icon or d.name == "EMPTY")

    @property
    def with_value_max(self) -> Any:
        return self.__filter(
            "DataWithValueMax", lambda d: d.has_value_max or d.name == "EMPTY"
        )

    def __filter(self, name: str, predicate: Callable[[Datum], bool]) -> Any:
        return cast(
            Any,
            StableOptions(
                name,
                {
                    "NONE": auto(),
                    **{
                        datum.name: datum.value
                        for datum in self.__items
                        if predicate(datum)
                    },
                },
            ),
        )

    def __iter__(self) -> Iterator[Datum]:
        return self.__items.__iter__()

    def __len__(self) -> int:
        return len(self.__items)

    def __getattr__(self, name: str) -> int:
        for item in self.__items:
            if item.name == name:
                return item.value
        raise AttributeError(name)
