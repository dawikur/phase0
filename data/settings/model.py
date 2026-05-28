# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import textwrap
from dataclasses import dataclass
from typing import Iterator, List


@dataclass(order=True)
class Token:
    name: str

    @property
    def parts(self) -> List[str]:
        return self.name.split(" ")

    @property
    def id(self) -> str:
        return "".join(part.capitalize() for part in self.parts)

    @property
    def label(self) -> str:
        return f"LABEL_{'_'.join(part.upper() for part in self.parts)}"


@dataclass
class Select:
    name: Token
    options: List[Token]

    def __init__(self, name: str, options: List[str]):
        self.name = Token(name)
        self.options = [Token(option) for option in options]

    @property
    def id(self) -> str:
        return self.name.id

    @property
    def label(self) -> str:
        return self.name.label

    def __iter__(self) -> Iterator[Token]:
        return self.options.__iter__()


@dataclass
class Group:
    name: Token
    selects: List[Select]

    def __init__(self, name: str, selects: List[Select]):
        self.name = Token(name)
        self.selects = selects

    @property
    def id(self) -> str:
        return self.name.id

    @property
    def label(self) -> str:
        return self.name.label

    def __iter__(self) -> Iterator[Select]:
        return self.selects.__iter__()


@dataclass
class Settings:
    groups: List[Group]
