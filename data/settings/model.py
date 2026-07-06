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
    def label(self) -> str:
        return f"LABEL_{'_'.join(part.upper() for part in self.parts)}"

    def __eq__(self, other: object) -> bool:
        if isinstance(other, Token):
            return self.name == other.name
        return False

    def __hash__(self) -> int:
        return hash(self.name)


@dataclass
class Number:
    name: Token
    default: int

    type: str = "number"

    def __init__(self, name: str, default: int):
        self.name = Token(name)
        self.default = default

    @property
    def id(self) -> str:
        return self.name.id

    @property
    def label(self) -> str:
        return self.name.label


@dataclass
class Boolean:
    name: Token
    default: bool

    type: str = "boolean"

    def __init__(self, name: str, default: bool):
        self.name = Token(name)
        self.default = default

    @property
    def id(self) -> str:
        return self.name.id

    @property
    def label(self) -> str:
        return self.name.label


@dataclass
class Select:
    name: Token
    default: str
    options: dict[Token, str]

    type: str = "number"

    def __init__(self, name: str, default: Any, options: EnumType | None = None):
        self.name = Token(name)
        self.options: dict[Token, str] = {
            Token(option.name): str(option.value)
            for option in (options or type(default))
        }
        self.default = self.options[Token(default.name)]

    def __iter__(self) -> Iterator[Token]:
        return self.options.__iter__()

    @property
    def id(self) -> str:
        return self.name.id

    @property
    def label(self) -> str:
        return self.name.label


Entry = Select | Number | Boolean


@dataclass
class Single:
    name: Token
    entries: list[Entry]

    def __init__(self, name: str, entries: list[Entry]):
        self.name = Token(name)
        self.entries = entries

    @property
    def id(self) -> str:
        return self.name.id

    @property
    def label(self) -> str:
        return self.name.label

    def __iter__(self) -> Iterator[Entry]:
        return self.entries.__iter__()

    def __len__(self) -> int:
        return len(self.entries)

    def __getitem__(self, idx: int) -> Entry:
        return self.entries[idx]


@dataclass
class Array:
    name: Token
    entries: list[list[Entry]]

    def __init__(self, name: str, entries: list[list[Entry]]):
        self.name = Token(name)
        self.entries = entries

        assert self.entries, "Array elements must not be empty"

    @property
    def id(self) -> str:
        return self.name.id

    @property
    def label(self) -> str:
        return self.name.label

    def __iter__(self) -> Iterator[list[Entry]]:
        return self.entries.__iter__()

    def __len__(self) -> int:
        return len(self.entries)

    def __getitem__(self, idx: int) -> list[Entry]:
        return self.entries[idx]
