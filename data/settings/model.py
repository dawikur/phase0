# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from dataclasses import dataclass
from enum import Enum
from typing import Iterator


@dataclass(order=True)
class Token:
    name: str
    klass: str

    def __init__(self, name: str, klass: str | None = None):
        self.name = name
        self.klass = klass or self.id

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
        return f"SET_{'_'.join(part.upper() for part in self.parts)}"

    def __eq__(self, other: object) -> bool:
        if isinstance(other, Token):
            return self.name == other.name
        return False

    def __hash__(self) -> int:
        return hash(self.name)


@dataclass
class Number(Token):
    default: int
    hidden: bool

    def __init__(self, name: str, default: int, hidden: bool = False):
        super().__init__(name, "Number")
        self.default = default
        self.hidden = hidden


@dataclass
class Boolean(Token):
    default: bool
    hidden: bool

    def __init__(self, name: str, default: bool, hidden: bool = False):
        super().__init__(name, "Boolean")
        self.default = default
        self.hidden = hidden


@dataclass
class Select(Token):
    default: str
    hidden: bool

    def __init__(
        self,
        name: str,
        default: Enum,
        option_type: type[Enum] | None = None,
        hidden: bool = False,
    ):
        super().__init__(name, "Number")
        option_enum: type[Enum] = option_type or type(default)
        self.options = {Token(option.name): str(option.value) for option in option_enum}
        self.default = self.options[Token(default.name)]
        self.hidden = hidden

    def __iter__(self) -> Iterator[Token]:
        return self.options.__iter__()


Entry = Select | Number | Boolean


@dataclass
class Single(Token):
    entries: list[Entry]

    def __init__(self, name: str, klass: str, entries: list[Entry]):
        super().__init__(name, klass)
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

    def __init__(
        self,
        name: str,
        klass: str,
        entries: list[list[Entry]],
    ):
        super().__init__(name, klass)
        self.entries = entries

        assert self.entries, "Array elements must not be empty"

        reference = self.entries[0]

        for row_index, element in enumerate(self.entries[1:], start=1):
            if len(element) != len(reference):
                raise AssertionError(
                    f"Array '{self.name}' row {row_index} has length "
                    f"{len(element)}, expected {len(reference)}"
                )

            for col_index, (item, expected) in enumerate(zip(element, reference)):
                if type(item) is not type(expected):
                    raise AssertionError(
                        f"Array '{self.name}' row {row_index}, column {col_index} "
                        f"has type {type(item).__name__}, expected "
                        f"{type(expected).__name__}"
                    )

                if item.name != expected.name:
                    raise AssertionError(
                        f"Array '{self.name}' row {row_index}, column {col_index} "
                        f"has name '{item.name}', expected '{expected.name}'"
                    )

    def __iter__(self) -> Iterator[list[Entry]]:
        return self.entries.__iter__()

    def __len__(self) -> int:
        return len(self.entries)

    def __getitem__(self, idx: int) -> list[Entry]:
        return self.entries[idx]


class Settings:
    def __init__(self, *items: Single | Array):
        self._items = list(items)
        self._by_name = {item.name: item for item in self._items}

    def __getitem__(self, key: int | str) -> Single | Array:
        if isinstance(key, int):
            return self._items[key]

        return self._by_name[key]

    def get(
        self,
        name: str,
        default: Single | Array | None = None,
    ) -> Single | Array | None:
        return self._by_name.get(name, default)

    def extend(self, name: str, *entries: list[Entry]) -> "Settings":
        current = self.get(name)
        if not isinstance(current, Array):
            raise ValueError(f"Setting '{name}' is not an array")

        current.entries.extend(entries)

        return self

    def __iter__(self) -> Iterator[Single | Array]:
        return iter(self._items)

    def __len__(self) -> int:
        return len(self._items)
