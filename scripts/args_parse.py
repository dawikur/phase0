# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import argparse
from pathlib import Path


class Folders:
    build_: Path
    resources_: Path
    source_: Path

    def __init__(self, build: Path, resources: Path, source: Path) -> None:
        self.build_ = build
        self.resources_ = resources
        self.source_ = source

    @staticmethod
    def get_(path: Path, folder: str | None = None, file: str | None = None) -> Path:
        if folder:
            path = path / folder
            path.mkdir(parents=True, exist_ok=True)
        if file:
            path = path / file
        return path

    def build(self, folder: str | None = None, file: str | None = None) -> Path:
        return Folders.get_(self.build_, folder, file)

    def resources(self, folder: str | None = None, file: str | None = None) -> Path:
        return Folders.get_(self.resources_, folder, file)

    def source(self, folder: str | None = None, file: str | None = None) -> Path:
        return Folders.get_(self.source_, folder, file)


def parse_folders() -> Folders:
    parser = argparse.ArgumentParser(description="Generate fnt fonts")
    parser.add_argument("--build", type=Path, help="Build directory", required=True)
    parser.add_argument(
        "--resources", type=Path, help="Resources directory", required=True
    )
    parser.add_argument("--source", type=Path, help="Source directory", required=True)

    args = parser.parse_args()

    return Folders(args.build, args.resources, args.source)
