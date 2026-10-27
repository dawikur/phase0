# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import json
import shutil
import subprocess
from pathlib import Path

import pytest


@pytest.mark.parametrize(
    ("flags", "output", "failure"),
    [
        (["--device", "fr955", "--simulator"], "nested/watch.prg", ""),
        (["--release"], "nested/store.iq", ""),
        (["--device", "fr955", "--unit-test"], "tests.prg", ""),
        ([], "failure.prg", "optimizer"),
        ([], "failure.prg", "launch"),
        ([], "failure.prg", "compiler"),
        ([], "failure.prg", "output"),
        ([], "failure.prg", "postbuild"),
    ],
)
def test_optimizer_command(
    tmp_path: Path, flags: list[str], output: str, failure: str
) -> None:
    """Exercise the CLI with a CommonJS optimizer and a harmless Node compiler."""
    shutil.copyfile("scripts/optimizedc.mjs", tmp_path / "optimizedc.mjs")
    package = tmp_path / "node_modules/@markw65/monkeyc-optimizer"
    package.mkdir(parents=True)
    (package / "package.json").write_text(
        json.dumps({"main": "index.cjs"}), encoding="utf-8"
    )
    (package / "sdk-util.js").write_text(
        "exports.optimizeProgram = async (input, key, output, options) => {\n"
        "  console.log('postbuild:', JSON.stringify({input, key, output, options}));\n"
        + ("  throw new Error('postbuild failed');\n" if failure == "postbuild" else "")
        + "};\n",
        encoding="utf-8",
    )
    compiler = tmp_path / "compiler.cjs"
    compiler.write_text(
        "console.log('compiler args:', JSON.stringify(process.argv.slice(2)));\n"
        f"process.exitCode = {7 if failure == 'compiler' else 0};\n",
        encoding="utf-8",
    )
    (package / "index.cjs").write_text(
        "exports.buildOptimizedProject = async (device, options) => {\n"
        "  console.log('options:', JSON.stringify({device, ...options}));\n"
        + ("  throw new Error('optimizer failed');\n" if failure == "optimizer" else "")
        + "  return {\n"
        + (
            "    exe: '/nonexistent/phase0-compiler',\n"
            if failure == "launch"
            else "    exe: process.execPath,\n"
        )
        + f"    args: [{json.dumps(str(compiler))}, "
        + ("'--invalid'" if failure == "output" else "'-o', 'wrong.prg'")
        + ", '-f', options.jungleFiles, '-y', options.developerKeyPath],\n"
        "  };\n"
        "};\n",
        encoding="utf-8",
    )
    result = subprocess.run(
        [
            "node",
            str(tmp_path / "optimizedc.mjs"),
            "--jungles",
            "first.jungle;second.jungle",
            "--private-key",
            "developer key.der",
            "--output",
            output,
            "--warn",
            *flags,
        ],
        cwd=tmp_path,
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == (1 if failure else 0), result.stderr
    assert ("OPTIMIZATION SUCCESSFUL" in result.stdout) == (not failure)
    options = json.loads(result.stdout.splitlines()[0].removeprefix("options: "))
    assert options["returnCommand"] is True
    assert options["device"] == ("fr955" if "--device" in flags else None)
    assert options.get("releaseBuild", False) == ("--release" in flags)
    assert options.get("testBuild", False) == ("--unit-test" in flags)
    assert options.get("simulatorBuild", False) == ("--simulator" in flags)
    assert options["outputPath"] == str((tmp_path / output).parent / "optimized")
    if failure in ("", "compiler", "postbuild"):
        arguments = json.loads(
            result.stdout.splitlines()[1].removeprefix("compiler args: ")
        )
        assert arguments == [
            "-o",
            str(tmp_path / output),
            "-f",
            f"{tmp_path}/first.jungle;{tmp_path}/second.jungle",
            "-y",
            str(tmp_path / "developer key.der"),
        ]
    if failure:
        assert result.stderr

    for option in (
        "extraReferenceTypeChecks",
        "iterateOptimizer",
        "minimizeModules",
        "postBuildOptimizer",
        "postBuildPRE",
        "removeArgc",
    ):
        assert options[option] is True
    postbuild_lines = [
        line.removeprefix("postbuild: ")
        for line in result.stdout.splitlines()
        if line.startswith("postbuild: ")
    ]
    assert len(postbuild_lines) == (1 if failure in ("", "postbuild") else 0)
    if postbuild_lines:
        postbuild = json.loads(postbuild_lines[0])
        assert postbuild["input"] == postbuild["output"] == str(tmp_path / output)
        assert postbuild["key"] == str(tmp_path / "developer key.der")
        assert postbuild["options"]["postBuildPRE"] is True
