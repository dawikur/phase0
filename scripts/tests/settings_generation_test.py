# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import json
import runpy
import xml.etree.ElementTree as ET
from enum import IntEnum
from pathlib import Path
from types import SimpleNamespace
from typing import Any

import pytest

from data.settings import Array, Boolean, Number, Select, Settings, Single, Source
from data.settings.data import MemoryLow, Widgets
from data.settings.source import Datum
from scripts.utils.args_parse import Folders
from scripts.utils.settings_generation import (
    apply_property_defaults,
    render_properties_mc,
    render_properties_xml,
    render_settings_xml,
)
from scripts.utils.site_settings import parse_settings


class SampleOptions(IntEnum):
    AUTO = 1
    LARGE = 2


class SampleData(IntEnum):
    NONE = 0
    HEART_RATE = 1


# Preserve the exact external name handled by the generator's disabled option.
ExportWidgets = IntEnum("ExportWidgets", {"Disabled": 0, "NONE": 1, "HEART_RATE": 2})


def test_apply_property_defaults_updates_single_and_array_settings() -> None:
    settings = [
        Single("global", "Global", [Select("accent", SampleOptions.AUTO)]),
        Array("status", "Status", [[Number("width", 2)], [Number("width", 4)]]),
        Single("clock", "Clock", [Boolean("visible", True)]),
    ]

    applied = apply_property_defaults(
        settings,
        {
            "GlobalAccent": 2,
            "StatusWidth0": 5,
            "StatusWidth1": 6,
            "ClockVisible": False,
        },
    )

    assert applied == {"GlobalAccent", "StatusWidth0", "StatusWidth1", "ClockVisible"}
    properties = ET.fromstring(render_properties_xml(settings))
    assert {item.get("id"): (item.get("type"), item.text) for item in properties} == {
        "GlobalAccent": ("Number", "2"),
        "StatusWidth0": ("Number", "5"),
        "StatusWidth1": ("Number", "6"),
        "ClockVisible": ("Boolean", "False"),
    }
    assert apply_property_defaults(settings, {}) == set()


@pytest.mark.parametrize(
    ("settings", "overrides", "message"),
    [
        (
            [Single("global", "Global", [Select("accent", SampleOptions.AUTO)])],
            {"GlobalAccent": True},
            "expects int",
        ),
        (
            [Single("clock", "Clock", [Number("width", 2)])],
            {"ClockWidth": False},
            "expects int",
        ),
        (
            [Single("clock", "Clock", [Boolean("visible", True)])],
            {"ClockVisible": 0},
            "expects bool",
        ),
    ],
)
def test_apply_property_defaults_rejects_wrong_types(
    settings: list[Single | Array], overrides: dict[str, int | bool], message: str
) -> None:
    with pytest.raises(ValueError, match=message):
        apply_property_defaults(settings, overrides)


def test_render_properties_xml_handles_single_and_array_settings() -> None:
    xml = render_properties_xml(
        [
            Single(
                "clock",
                "Clock",
                [
                    Select("size", SampleOptions.AUTO),
                    Boolean("visible", True),
                ],
            ),
            Array(
                "status",
                "Status",
                [
                    [Number("width", 2)],
                    [Number("width", 4)],
                ],
            ),
        ]
    )

    root = ET.fromstring(xml)
    assert {item.get("id"): (item.get("type"), item.text) for item in root} == {
        "ClockSize": ("Number", "1"),
        "ClockVisible": ("Boolean", "True"),
        "StatusWidth0": ("Number", "2"),
        "StatusWidth1": ("Number", "4"),
    }


def test_render_settings_xml_includes_setting_config_by_entry_type() -> None:
    xml = render_settings_xml(
        [
            Single(
                "clock",
                "Clock",
                [
                    Select("size", SampleOptions.AUTO),
                    Number("width", 2),
                    Boolean("visible", True),
                ],
            )
        ]
    )

    root = ET.fromstring(xml)
    configs = root.findall(".//settingConfig")
    assert [config.attrib for config in configs] == [
        {"type": "list", "required": "true"},
        {"type": "numeric", "min": "0", "max": "10", "required": "true"},
        {"type": "boolean", "required": "true"},
    ]
    assert [(entry.get("value"), entry.text) for entry in configs[0]] == [
        ("1", "@Strings.SETTING_AUTO"),
        ("2", "@Strings.SETTING_LARGE"),
    ]


def test_render_settings_xml_handles_array_settings() -> None:
    xml = render_settings_xml(
        [
            Array("status", "Status", [[Number("width", 2)], [Number("width", 4)]]),
            Array(
                "gauges",
                "Gauge",
                [
                    [
                        Select("data", SampleOptions.AUTO),
                        Select("accent", SampleOptions.LARGE),
                    ],
                    [
                        Select("data", SampleOptions.LARGE),
                        Select("accent", SampleOptions.AUTO),
                    ],
                ],
            ),
        ]
    )
    root = ET.fromstring(xml)
    groups = root.findall("group")

    assert [group.get("id") for group in groups] == ["Status", "Gauges"]
    assert [setting.get("title") for setting in groups[0].findall("setting")] == [
        "@Strings.SETTING_STATUS_1",
        "@Strings.SETTING_STATUS_2",
    ]
    assert [setting.get("title") for setting in groups[1].findall("setting")] == [
        "@Strings.SETTING_GAUGE_1_DATA",
        "@Strings.SETTING_GAUGE_1_ACCENT",
        "@Strings.SETTING_GAUGE_2_DATA",
        "@Strings.SETTING_GAUGE_2_ACCENT",
    ]
    assert [setting.get("propertyKey") for setting in groups[0].findall("setting")] == [
        "@Properties.StatusWidth0",
        "@Properties.StatusWidth1",
    ]


def test_array_setting_labels_are_translated() -> None:
    expected = {
        f"SETTING_{name}_{index}{suffix}"
        for name, suffixes in (
            ("STATUS", ("",)),
            ("GAUGE", ("_DATA", "_ACCENT")),
            ("METRIC", ("_DATA", "_WIDTH")),
        )
        for index in range(1, 5)
        for suffix in suffixes
    }
    paths = [
        Path("resources/base/strings.xml"),
        *Path("resources/lang").glob("*/strings.xml"),
    ]

    for path in paths:
        strings = {
            element.get("id") for element in ET.parse(path).getroot().findall("string")
        }
        assert expected <= strings, path


def test_render_generators_reject_unsupported_types() -> None:
    unsupported = SimpleNamespace(klass="Unsupported")

    with pytest.raises(AssertionError, match="Unsupported type"):
        render_properties_mc(
            [unsupported],  # type: ignore[arg-type]
            SampleData,
            "memory_annotation",
        )
    with pytest.raises(AssertionError, match="Unsupported type"):
        render_properties_xml([unsupported])  # type: ignore[list-item]
    with pytest.raises(AssertionError, match="Unsupported type"):
        render_settings_xml([unsupported])  # type: ignore[list-item]


def test_render_settings_xml_rejects_unsupported_entry_type() -> None:
    unsupported: Any = SimpleNamespace(hidden=False, setting="UNKNOWN", id="Unknown")

    with pytest.raises(AssertionError, match="Unsupported type"):
        render_settings_xml([Single("sample", "Sample", [unsupported])])


def test_hidden_settings_are_not_exposed_in_device_configuration() -> None:
    settings = [
        Single(
            "metric",
            "Metric",
            [
                Number("width", 2),
                Boolean("icon", True, hidden=True),
            ],
        )
    ]

    properties_xml = render_properties_xml(settings)
    settings_xml = render_settings_xml(settings)

    properties = ET.fromstring(properties_xml)
    assert [(item.get("id"), item.get("type"), item.text) for item in properties] == [
        ("MetricWidth", "Number", "2"),
    ]
    settings_root = ET.fromstring(settings_xml)
    assert [
        item.get("propertyKey") for item in settings_root.findall(".//setting")
    ] == [
        "@Properties.MetricWidth",
    ]


def test_settings_extend_appends_array_entries() -> None:
    settings = Settings(Array("status", "Status", [[Number("width", 2)]]))

    extended = settings.extend("status", [Number("width", 4)])

    assert extended is settings
    status = settings["status"]
    assert isinstance(status, Array)
    assert [row[0].default for row in status] == [2, 4]


def test_settings_extend_rejects_non_array_settings() -> None:
    settings = Settings(Single("clock", "Clock", [Number("width", 2)]))

    with pytest.raises(ValueError, match="is not an array"):
        settings.extend("clock", [Number("width", 4)])


def test_empty_metric_is_selectable_without_icon_or_gauge() -> None:
    data = Source(Path("source/data"))
    empty_id = Datum("EMPTY", False, False).value
    assert data.all.EMPTY.value == empty_id
    assert empty_id != data.all.NONE.value
    assert "EMPTY" in data.with_icon.__members__
    assert "EMPTY" in data.with_value_max.__members__
    settings = MemoryLow(data, Widgets(data))
    for section in ("top middle", "bottom middle"):
        metrics = settings[section]
        assert isinstance(metrics, Array)
        for entries in metrics.entries:
            select = entries[0]
            assert isinstance(select, Select)
            assert any(
                token.name == "EMPTY" and value == str(empty_id)
                for token, value in select.options.items()
            )


@pytest.mark.parametrize(
    ("overrides", "error"),
    [
        (None, None),
        ({"TopWidth": 7}, None),
        ([], "must be an object"),
        ({"TopWidth": "invalid"}, "numbers or booleans"),
        ({"Unknown": 2}, "Unknown screenshot setting properties"),
        ({123: 2}, "keys must be property IDs"),
    ],
)
def test_settings_export_produces_consumable_resources_and_source_artifacts(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, overrides: Any, error: str | None
) -> None:
    folders = Folders(tmp_path / "build", tmp_path / "resources", tmp_path / "source")
    folders.source("data", "steps.mc").write_text(
        "class Steps extends Base { const LABEL_STEPS = 1; }"
    )
    folders.resources("base", "strings.xml").write_text("<resources />")

    def settings_for_export(_data, _widgets):
        return Settings(
            Single("top", "Widget", [Number("width", 2)]),
            Single("bottom", "Widget", [Number("width", 3)]),
            Array("status", "Status", [[Number("width", 2)], [Number("width", 4)]]),
            Single("clock", "Clock", [Boolean("visible", True, hidden=True)]),
        )

    monkeypatch.setattr("scripts.utils.args_parse.parse_folders", lambda: folders)
    monkeypatch.setattr("data.settings.Widgets", lambda _data: ExportWidgets)
    for profile in ("Low", "Medium", "High"):
        monkeypatch.setattr(f"data.settings.data.Memory{profile}", settings_for_export)
    if overrides is not None:
        monkeypatch.setenv("PHASE0_STORE_SCREENSHOT_OVERRIDES", json.dumps(overrides))
        if isinstance(overrides, dict) and any(
            not isinstance(key, str) for key in overrides
        ):
            # JSON keys are strings. Simulate an invalid decoder result at the
            # input boundary to exercise the command's defensive validation.
            monkeypatch.setattr(json, "loads", lambda _payload: overrides)
    else:
        monkeypatch.delenv("PHASE0_STORE_SCREENSHOT_OVERRIDES", raising=False)

    if error is not None:
        with pytest.raises(ValueError, match=error):
            runpy.run_path("scripts/generate_resources_settings", run_name="__main__")
        assert not folders.resources("memory/high/generated", "settings.xml").exists()
        return
    runpy.run_path("scripts/generate_resources_settings", run_name="__main__")

    # These are public build artifacts. Runtime behaviour of the Monkey C
    # artifacts still belongs to CIQ tests; do not infer it from source text.
    artifacts = folders.source("generated")
    assert {path.name for path in artifacts.iterdir()} == {
        "data.mc",
        "widgets.mc",
        "properties_memory_low.mc",
        "properties_memory_medium.mc",
        "properties_memory_high.mc",
    }
    assert all(path.stat().st_size for path in artifacts.iterdir())
    for profile in ("low", "medium", "high"):
        output = folders.resources(f"memory/{profile}/generated")
        properties = ET.parse(output / "properties.xml").getroot()
        assert {item.get("id"): item.text for item in properties} == {
            "TopWidth": "7" if overrides else "2",
            "BottomWidth": "3",
            "StatusWidth0": "2",
            "StatusWidth1": "4",
        }
        website = parse_settings(output / "settings.xml", folders.resources())
        by_group = {group["id"]: group for group in website["groups"]}
        assert by_group["Top"]["settings"][0]["key"] == "TopWidth"
        assert by_group["Bottom"]["settings"][0]["key"] == "BottomWidth"
        assert [item["key"] for item in by_group["Status"]["settings"]] == [
            "StatusWidth0"
        ]
        assert by_group["Clock"]["settings"] == []


def test_property_generation_rejects_incompatible_shared_types() -> None:
    settings = [
        Single("top", "Widget", [Number("width", 2)]),
        Single("bottom", "Widget", [Boolean("visible", True)]),
    ]
    with pytest.raises(AssertionError, match="Klass mismatch"):
        render_properties_mc(settings, SampleData, "memory_low")


def test_property_generation_accepts_single_pass_iterables() -> None:
    settings = [Single("top", "Widget", [Number("width", 2)])]
    assert render_properties_mc(iter(settings), SampleData, "memory_low") == (
        render_properties_mc(settings, SampleData, "memory_low")
    )
