# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from enum import IntEnum
from types import SimpleNamespace
from typing import Any

import pytest

from data.settings import Array, Boolean, Number, Select, Settings, Single
from scripts.utils.settings_generation import (
    apply_property_defaults,
    render_data_mc,
    render_properties_mc,
    render_properties_xml,
    render_settings_xml,
    render_widgets_mc,
)


class SampleOptions(IntEnum):
    AUTO = 1
    LARGE = 2


class SampleData(IntEnum):
    NONE = 0
    HEART_RATE = 1


def test_apply_property_defaults_updates_single_and_array_settings() -> None:
    settings = [
        Single("general", "General", [Select("accent", SampleOptions.AUTO)]),
        Array("status", "Status", [[Number("width", 2)], [Number("width", 4)]]),
        Single("clock", "Clock", [Boolean("visible", True)]),
    ]

    applied = apply_property_defaults(
        settings,
        {
            "GeneralAccent": 2,
            "StatusWidth0": 5,
            "StatusWidth1": 6,
            "ClockVisible": False,
        },
    )

    assert applied == {"GeneralAccent", "StatusWidth0", "StatusWidth1", "ClockVisible"}
    assert (
        '<property id="GeneralAccent" type="Number">2</property>'
        in render_properties_xml(settings)
    )
    assert (
        '<property id="StatusWidth0" type="Number">5</property>'
        in render_properties_xml(settings)
    )
    assert (
        '<property id="ClockVisible" type="Boolean">False</property>'
        in render_properties_xml(settings)
    )
    assert apply_property_defaults(settings, {}) == set()


@pytest.mark.parametrize(
    ("settings", "overrides", "message"),
    [
        (
            [Single("general", "General", [Select("accent", SampleOptions.AUTO)])],
            {"GeneralAccent": True},
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
                    Select("height", SampleOptions.AUTO),
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

    assert '<property id="ClockHeight" type="Number">1</property>' in xml
    assert '<property id="ClockVisible" type="Boolean">True</property>' in xml
    assert '<property id="StatusWidth0" type="Number">2</property>' in xml
    assert '<property id="StatusWidth1" type="Number">4</property>' in xml


def test_render_settings_xml_includes_setting_config_by_entry_type() -> None:
    xml = render_settings_xml(
        [
            Single(
                "clock",
                "Clock",
                [
                    Select("height", SampleOptions.AUTO),
                    Number("width", 2),
                    Boolean("visible", True),
                ],
            )
        ]
    )

    assert '<settingConfig type="list" required="true">' in xml
    assert '<listEntry value="1">@Strings.SETTING_AUTO</listEntry>' in xml
    assert '<settingConfig type="numeric" min="0" max="10" required="true" />' in xml
    assert '<settingConfig type="boolean" required="true" />' in xml


def test_render_settings_xml_handles_array_settings() -> None:
    xml = render_settings_xml([Array("status", "Status", [[Number("width", 2)]])])

    assert '<group id="Status0"' in xml
    assert 'propertyKey="@Properties.StatusWidth0"' in xml


def test_render_properties_mc_reuses_matching_property_classes() -> None:
    mc = render_properties_mc(
        [
            Single("top", "Widget", [Number("width", 2)]),
            Single("bottom", "Widget", [Number("width", 3)]),
        ],
        SampleData,
        "memory_annotation",
    )

    assert mc.count("class Widget {") == 1
    assert "var top as Widget;" in mc
    assert "var bottom as Widget;" in mc
    assert "function initialize()" in mc
    assert "self.top = new Widget(" in mc
    assert "self.bottom = new Widget(" in mc
    assert '"TopWidth") as Lang.Number' in mc
    assert '"BottomWidth") as Lang.Number' in mc


def test_render_properties_mc_handles_array_settings() -> None:
    mc = render_properties_mc(
        [Array("status", "Status", [[Number("width", 2)]])],
        SampleData,
        "memory_annotation",
    )

    assert "var status as Lang.Array<Status>;" in mc
    assert "self.status = [" in mc


def test_render_properties_mc_skips_disabled_extra_data() -> None:
    extra_data = [
        SimpleNamespace(name="Disabled", value=0),
        SimpleNamespace(name="HeartRate", value=1),
    ]
    mc = render_properties_mc([], extra_data, "memory_annotation")  # type: ignore[arg-type]

    assert "DATA_HEARTRATE" in mc
    assert "DATA_DISABLED" not in mc


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

    class ChangesBetweenPasses:  # pylint: disable=too-few-public-methods
        def __init__(self) -> None:
            self.pass_number = 0

        def __iter__(self):
            self.pass_number += 1
            if self.pass_number == 1:
                return iter([Single("sample", "Sample", [])])
            return iter([object()])

    with pytest.raises(AssertionError, match="Unsupported type"):
        render_properties_mc(
            ChangesBetweenPasses(),  # type: ignore[arg-type]
            SampleData,
            "memory_annotation",
        )


def test_render_settings_xml_rejects_unsupported_entry_type() -> None:
    unsupported: Any = SimpleNamespace(hidden=False, setting="UNKNOWN", id="Unknown")

    with pytest.raises(AssertionError, match="Unsupported type"):
        render_settings_xml([Single("sample", "Sample", [unsupported])])


def test_hidden_settings_keep_defaults_without_generated_properties() -> None:
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

    mc = render_properties_mc(settings, SampleData, "memory_annotation")
    properties_xml = render_properties_xml(settings)
    settings_xml = render_settings_xml(settings)

    assert "var icon as Lang.Boolean;" in mc
    assert "_icon as Lang.Boolean" in mc
    assert "true" in mc
    assert '"MetricWidth") as Lang.Number' in mc
    assert '"MetricIcon") as Lang.Boolean;' not in mc

    assert '<property id="MetricWidth" type="Number">2</property>' in properties_xml
    assert "MetricIcon" not in properties_xml

    assert 'propertyKey="@Properties.MetricWidth"' in settings_xml
    assert "MetricIcon" not in settings_xml
    assert "SETTING_ICON" not in settings_xml


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


def test_render_data_and_widgets_mc_include_cases_and_default() -> None:
    data = [
        SimpleNamespace(name="heart_rate", value=1),
        SimpleNamespace(name="steps", value=2),
    ]
    data_mc = render_data_mc(data)
    widgets_mc = render_widgets_mc(SampleData)

    assert "case 1: return new HeartRate();" in data_mc
    assert "case 2: return new Steps();" in data_mc
    assert "default: return null;" in data_mc
    assert "case Properties.DATA_HEART_RATE: return new HeartRate(" in widgets_mc
    assert "default: return Widgets.Base.None();" in widgets_mc
