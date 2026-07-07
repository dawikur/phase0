# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from dataclasses import dataclass
from enum import EnumType
from typing import Any, Iterator


@dataclass(order=True)
class Token:
    name: str

    @property
    def parts(self) -> list[str]:
        return self.name.split(" ")

    @property
    def id(self) -> str:
        return "".join(part.capitalize() for part in self.parts)

    @property
    def variable(self) -> str:
        return "_".join(part.lower() for part in self.parts)

    @property
    def label(self) -> str:
        return f"LABEL_{'_'.join(part.upper() for part in self.parts)}"

    def __eq__(self, other: object) -> bool:
        if isinstance(other, Token):
            return self.name == other.name
        return False

    def __hash__(self) -> int:
        return hash(self.name)


@dataclass
class Number(Token):
    default: int

    type: str = "Number"

    def __init__(self, name: str, default: int):
        super().__init__(name)
        self.default = default


@dataclass
class Boolean(Token):
    default: bool

    type: str = "Boolean"

    def __init__(self, name: str, default: bool):
        super().__init__(name)
        self.default = default


@dataclass
class Select(Token):
    default: str
    options: dict[Token, str]

    type: str = "Number"

    def __init__(self, name: str, default: Any, options: EnumType | None = None):
        super().__init__(name)
        self.options: dict[Token, str] = {
            Token(option.name): str(option.value)
            for option in (options or type(default))
        }
        self.default = self.options[Token(default.name)]

    def __iter__(self) -> Iterator[Token]:
        return self.options.__iter__()


Entry = Select | Number | Boolean


@dataclass
class Single(Token):
    entries: list[Entry]

    def __init__(self, name: str, entries: list[Entry]):
        super().__init__(name)
        self.entries = entries

    def __iter__(self) -> Iterator[Entry]:
        return self.entries.__iter__()

    def __len__(self) -> int:
        return len(self.entries)

    def __getitem__(self, idx: int) -> Entry:
        return self.entries[idx]


@dataclass
class Array(Token):
    entries: list[list[Entry]]

    def __init__(self, name: str, entries: list[list[Entry]]):
        super().__init__(name)
        self.entries = entries

        assert self.entries, "Array elements must not be empty"

    def __iter__(self) -> Iterator[list[Entry]]:
        return self.entries.__iter__()

    def __len__(self) -> int:
        return len(self.entries)

    def __getitem__(self, idx: int) -> list[Entry]:
        return self.entries[idx]
