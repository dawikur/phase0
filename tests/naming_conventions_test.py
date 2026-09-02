# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import re
from pathlib import Path

HIDDEN_MEMBER_RE = re.compile(
    r"^\s*(?=[^\n]*\bhidden\b)[^\n]*\b(?:var|function)\s+([A-Za-z_][A-Za-z0-9_]*)",
    re.MULTILINE,
)
STATIC_METHOD_RE = re.compile(
    r"^\s*(?=[^\n]*\bstatic\b)[^\n]*\bfunction\s+([A-Za-z_][A-Za-z0-9_]*)",
    re.MULTILINE,
)
COMMENT_RE = re.compile(r"//[^\n]*|/\*.*?\*/", re.DOTALL)
DECLARATION_KEYWORD_RE = re.compile(
    r"\b(?:module|class|enum|typedef|const|var|function)\b"
)
DECLARATION_TOKEN_RE = re.compile(
    r"\(:[^)]*\)|\b(?:hidden|protected|private|public|static|module|class|enum|"
    r"typedef|const|var|function)\b"
)
DECLARATION_TOKEN_ORDER = {
    "annotation": 0,
    "hidden": 1,
    "protected": 1,
    "private": 1,
    "public": 1,
    "static": 2,
    "module": 3,
    "class": 3,
    "enum": 3,
    "typedef": 3,
    "const": 3,
    "var": 3,
    "function": 3,
}


def declaration_order_violations(source: str) -> list[tuple[int, str]]:
    """Return declaration lines whose modifiers are out of canonical order."""
    violations: list[tuple[int, str]] = []
    annotations: list[int] = []
    uncommented_source = COMMENT_RE.sub(
        lambda match: "\n" * match.group().count("\n"), source
    )

    for line_number, line in enumerate(uncommented_source.splitlines(), start=1):
        declaration = DECLARATION_KEYWORD_RE.search(line)
        tokens = DECLARATION_TOKEN_RE.findall(line)

        if declaration is None:
            if tokens and all(token.startswith("(:") for token in tokens):
                annotations.extend(
                    [DECLARATION_TOKEN_ORDER["annotation"]] * len(tokens)
                )
            elif line.strip():
                annotations = []
            continue

        declaration_header = line.split("{", maxsplit=1)[0]
        declaration_tokens = DECLARATION_TOKEN_RE.findall(declaration_header)
        order = annotations + [
            DECLARATION_TOKEN_ORDER["annotation" if token.startswith("(:") else token]
            for token in declaration_tokens
        ]
        if order != sorted(order):
            violations.append((line_number, line.strip()))
        annotations = []

    return violations


def test_hidden_members_use_private_suffix() -> None:
    invalid_members: list[str] = []

    for path in Path("source").rglob("*.mc"):
        members = HIDDEN_MEMBER_RE.findall(path.read_text(encoding="utf-8"))
        invalid_members.extend(
            f"{path}:{member}" for member in members if not member.endswith("_")
        )

    assert not invalid_members, "Hidden members without '_':\n" + "\n".join(
        invalid_members
    )


def test_static_methods_start_with_uppercase() -> None:
    invalid_methods: list[str] = []

    for path in Path("source").rglob("*.mc"):
        methods = STATIC_METHOD_RE.findall(path.read_text(encoding="utf-8"))
        invalid_methods.extend(
            f"{path}:{method}" for method in methods if not method[0].isupper()
        )

    assert (
        not invalid_methods
    ), "Static methods without uppercase prefix:\n" + "\n".join(invalid_methods)


def test_declaration_keywords_follow_canonical_order() -> None:
    violations: list[str] = []

    for path in Path("source").rglob("*.mc"):
        violations.extend(
            f"{path}:{line_number}: {line}"
            for line_number, line in declaration_order_violations(
                path.read_text(encoding="utf-8")
            )
        )

    assert not violations, "Declarations with unordered keywords:\n" + "\n".join(
        violations
    )


def test_declaration_keyword_order_accepts_annotations_and_modifiers() -> None:
    source = """
(:test)
hidden static function Example_() as Void {}
public static const VALUE = 1;
protected var value_;
function refresh() as Void {}
"""

    assert not declaration_order_violations(source)


def test_declaration_keyword_order_rejects_reversed_modifiers() -> None:
    source = """
static hidden function Example_() as Void {}
function static Example() as Void {}
var protected value_;
static (:test) function TestExample() as Void {}
"""

    assert declaration_order_violations(source) == [
        (2, "static hidden function Example_() as Void {}"),
        (3, "function static Example() as Void {}"),
        (4, "var protected value_;"),
        (5, "static (:test) function TestExample() as Void {}"),
    ]
