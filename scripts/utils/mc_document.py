# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from scripts.utils.common import copyright_lines


class McDocument:
    lines: list[str]
    indent_: int

    def __init__(self, lines: list[str] | None = None, indent_: int = 0) -> None:
        self.lines = lines if lines is not None else []
        self.indent_ = indent_

    @classmethod
    def create(cls) -> "McDocument":
        lines = [f"// {line}" for line in copyright_lines()]
        lines.append("")
        return cls(lines=lines)

    def line(self, text: str | None = None) -> "McDocument":
        if text:
            indent = "\t" * self.indent_
            self.lines.append(f"{indent}{text.strip()}")
        elif self.lines[-1] != "":
            self.lines.append("")
        return self

    def raw(self, text: str) -> None:
        self.lines.extend(text.splitlines())

    def indented(self) -> "McDocument":
        self.indent_ += 1
        return self

    def dedented(self) -> "McDocument":
        assert 0 < self.indent_
        self.indent_ -= 1
        return self

    def render(self) -> str:
        return "\n".join(self.lines)


class McScope:
    MARKERS = {
        "(": ")",
        "{": "}",
        "[": "]",
        "<": ">",
    }

    def __init__(self, doc: McDocument, line: str, suffix: str | None = None):
        self.__doc = doc
        self.__line = line
        self.__suffix = suffix or ""

        assert (
            self.__line[-1] in self.MARKERS
        ), f"Unknown scope marker {self.__line[-1]}"

    def __enter__(self) -> "McScope":
        self.__doc.line()
        self.__doc.line(f"{self.__line}")
        self.__doc.indented()
        return self

    def __exit__(self, exc_type: int, exc_value: int, traceback: int) -> None:
        marker = self.MARKERS[self.__line[-1]]

        self.__doc.dedented()
        self.__doc.line(f"{marker}{self.__suffix} // {self.__line[:-1]}")
        self.__doc.line()
