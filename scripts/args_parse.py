# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


class Folders:
    build_: Path
    resources_: Path

    def __init__(self, build: Path, resources: Path) -> None:
        self.build_ = build
        self.resources_ = resources

    def build(self, folder: Optional[str] = None, file: Optional[str] = None) -> Path:
        result = self.build_

        if folder:
            result = result / folder
            result.mkdir(parents=True, exist_ok=True)
        if file:
            result = result / file
        return result

    def resources(
        self, folder: Optional[str] = None, file: Optional[str] = None
    ) -> Path:
        result = self.resources_

        if folder:
            result = result / folder
            result.mkdir(parents=True, exist_ok=True)
        if file:
            result = result / file
        return result


def parse_folders() -> Folders:
    parser = argparse.ArgumentParser(description="Generate fnt fonts")
    parser.add_argument("--build", type=Path, help="Build directory")
    parser.add_argument("--resources", type=Path, help="Resources directory")

    args = parser.parse_args()

    return Folders(args.build, args.resources)
