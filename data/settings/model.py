# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import textwrap
from dataclasses import dataclass
from enum import StrEnum
from typing import Any, Dict, Iterator, List


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

    def __eq__(self, other: object) -> bool:
        if isinstance(other, Token):
            return self.name == other.name
        return False

    def __hash__(self) -> int:
        return hash(self.name)


@dataclass
class Select:
    name: Token
    options: Dict[Token, str]
    default: str

    def __init__(self, name: str, default: Any, options: Any):
        self.name = Token(name)

        self.options = {Token(option.name): str(option.value) for option in options}

        self.default = self.options[Token(default.name)]

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
    selections: List[Select]

    def __init__(self, name: str, selections: List[Select]):
        self.name = Token(name)
        self.selections = selections

    @property
    def id(self) -> str:
        return self.name.id

    @property
    def label(self) -> str:
        return self.name.label

    def __iter__(self) -> Iterator[Select]:
        return self.selections.__iter__()
