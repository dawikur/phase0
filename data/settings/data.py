# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import re
from dataclasses import dataclass
from enum import IntEnum
from pathlib import Path
from typing import Any, Callable, Iterator, cast


@dataclass
class Datum:
    name: str
    value: int

    has_icon: bool
    has_value_max: bool


class Data:
    CLASS_PARTS_RE = re.compile(r"(?<!^)(?=[A-Z])")
    CLASS_RE = re.compile(r"\bclass\s+([A-Za-z_]\w*)\s+extends Base\b")
    ICON_ASSIGN_RE = re.compile(r"\bself\.icon\s*=\s*Fonts\.ICON_\w+")
    INITIALIZE_RE = re.compile(
        r"function\s+initialize\s*\(\s*\)(.*?)(?=\n\s*function|\Z)", re.DOTALL
    )
    LABEL_RE = re.compile(r"LABEL_(\w+)")
    VALUE_MAX_ASSIGN_RE = re.compile(r"\bself\.value_max\s*=")

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

            items.append(
                (
                    "_".join(class_parts).upper(),
                    self.__has_icon(data_text),
                    self.__has_value_max(data_text),
                )
            )

        self.__items = [
            Datum(name, index, *args)
            for index, (name, *args) in enumerate(
                sorted(items, key=lambda item: item[0]),
                start=1,
            )
        ]

    @property
    def all(self) -> Any:
        return self.__filter("DataAll", lambda _: True)

    @property
    def with_icon(self) -> Any:
        return self.__filter("DataWithIcon", lambda d: d.has_icon)

    @property
    def with_value_max(self) -> Any:
        return self.__filter("DataWithValueMax", lambda d: d.has_value_max)

    def __filter(self, name: str, predicate: Callable[[Datum], bool]) -> Any:
        return cast(
            Any,
            IntEnum(
                name,
                {
                    "NONE": 0,
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

    def __has_value_max(self, data_text: str) -> bool:
        initialize_match = self.INITIALIZE_RE.search(data_text)
        return (
            bool(self.VALUE_MAX_ASSIGN_RE.search(initialize_match.group(1)))
            if initialize_match
            else False
        )

    def __has_icon(self, data_text: str) -> bool:
        initialize_match = self.INITIALIZE_RE.search(data_text)
        return (
            bool(self.ICON_ASSIGN_RE.search(initialize_match.group(1)))
            if initialize_match
            else False
        )
