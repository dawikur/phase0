# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from enum import IntEnum

from data.settings import Array, Boolean, Number, Select, Single
from scripts.utils.settings_generation import (
    render_properties_mc,
    render_properties_xml,
    render_settings_xml,
)


class SampleOptions(IntEnum):
    AUTO = 1
    LARGE = 2


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
    assert '<listEntry value="1">@Strings.SET_AUTO</listEntry>' in xml
    assert '<settingConfig type="numeric" min="0" max="10" required="true" />' in xml
    assert '<settingConfig type="boolean" required="true" />' in xml


def test_render_properties_mc_reuses_matching_property_classes() -> None:
    mc = render_properties_mc(
        [
            Single("top", "Widget", [Number("width", 2)]),
            Single("bottom", "Widget", [Number("width", 3)]),
        ]
    )

    assert mc.count("class Widget {") == 1
    assert "var top as Widget;" in mc
    assert "var bottom as Widget;" in mc
    assert "function initialize()" in mc
    assert "self.top = new Widget(" in mc
    assert "self.bottom = new Widget(" in mc
    assert '"TopWidth") as Lang.Number' in mc
    assert '"BottomWidth") as Lang.Number' in mc


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

    mc = render_properties_mc(settings)
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
    assert "SET_ICON" not in settings_xml
