# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from utils import copyright_lines


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

    def blank(self) -> None:
        if self.lines and self.lines[-1] != "":
            self.lines.append("")

    def line(self, text: str = "") -> None:
        if text:
            indent = "\t" * self.indent_
            self.lines.append(f"{indent}{text}")
            return

        self.lines.append("")

    def raw(self, text: str) -> None:
        self.lines.extend(text.splitlines())

    def indented(self) -> "McDocument":
        self.indent_ += 1
        return self

    def dedented(self) -> "McDocument":
        assert 0 < self.indent_
        self.indent_ -= 1
        return self

    def block(self, header: str, footer: str) -> None:
        self.line(header)
        self.indented()
        self.line(footer)
        self.dedented()

    def text(self) -> str:
        return "\n".join(self.lines)
