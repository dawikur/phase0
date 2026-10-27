# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

"""Read browser-facing data by executing its JavaScript, as a consumer does."""

import json
import subprocess
from pathlib import Path
from typing import Any


def window_value(path: Path, name: str) -> Any:
    result = subprocess.run(
        [
            "node",
            "-e",
            "const fs = require('node:fs'); const vm = require('node:vm');"
            "const context = {window: {}};"
            "vm.runInNewContext(fs.readFileSync(process.argv[1], 'utf8'), context);"
            "process.stdout.write(JSON.stringify(context.window[process.argv[2]]));",
            str(path),
            name,
        ],
        capture_output=True,
        text=True,
        check=True,
        timeout=10,
    )
    return json.loads(result.stdout)
