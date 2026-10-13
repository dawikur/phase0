# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from pathlib import Path
from xml.etree import ElementTree as ET

from scripts.utils.site_settings import (
    build_site_settings,
    display_group_id,
    is_alternative_group,
    parse_settings,
    resolve_property,
    resolve_text,
    setting_region,
    setting_summary,
    write_settings_js,
)


def test_site_settings_resolvers_handle_references_and_fallbacks() -> None:
    strings = {"KNOWN": "Known label"}

    assert resolve_text(None, strings) == ""
    assert resolve_text("", strings) == ""
    assert resolve_text("@Strings.KNOWN", strings) == "Known label"
    assert resolve_text("@Strings.UNKNOWN_VALUE", strings) == "Unknown Value"
    assert resolve_text("Plain text", strings) == "Plain text"
    assert resolve_property(None) == ""
    assert resolve_property("@Properties.Width") == "Width"
    assert resolve_property("Width") == "Width"


def test_site_settings_maps_regions_and_alternative_groups() -> None:
    assert display_group_id("TopMiddleAlternative0") == "TopMiddle"
    assert display_group_id("Custom") == "Custom"
    assert is_alternative_group("StatusAlt0")
    assert is_alternative_group("GaugesAlternative1")
    assert not is_alternative_group("Status0")
    assert setting_region("Global") == "theme"
    assert setting_region("Status0") == "status"
    assert setting_region("Unknown") == "other"
    assert setting_summary("status") == "Small system indicators shown near the clock."
    assert setting_summary("Unknown") == "Configurable watch face area."


def test_site_settings_handles_empty_and_unknown_languages(tmp_path: Path) -> None:
    manifest = tmp_path / "manifest.xml"
    manifest.write_text(
        '<iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq">'
        "<iq:application><iq:languages>"
        "<iq:language> </iq:language><iq:language>zzz</iq:language>"
        "</iq:languages></iq:application></iq:manifest>",
        encoding="utf-8",
    )
    resources = tmp_path / "resources" / "base"
    resources.mkdir(parents=True)
    resources.joinpath("strings.xml").write_text("<resources />", encoding="utf-8")
    settings = tmp_path / "settings.xml"
    settings.write_text("<settings />", encoding="utf-8")

    data = parse_settings(settings, tmp_path / "resources", manifest)

    assert data["supportedLanguages"] == [{"code": "zzz", "name": "ZZZ"}]


def test_site_settings_writers_create_javascript_outputs(tmp_path: Path) -> None:
    data = {"groups": [], "supportedDevices": [], "supportedLanguages": []}
    output = tmp_path / "nested" / "settings-data.js"

    write_settings_js(data, output)
    resources = tmp_path / "resources" / "base"
    resources.mkdir(parents=True)
    resources.joinpath("strings.xml").write_text("<resources />", encoding="utf-8")
    settings = tmp_path / "settings.xml"
    settings.write_text("<settings />", encoding="utf-8")
    manifest = tmp_path / "manifest.xml"
    manifest.write_text(
        '<iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq">'
        "<iq:application /></iq:manifest>",
        encoding="utf-8",
    )
    built = tmp_path / "built.js"
    build_site_settings(resources.parent, settings, manifest, built)

    assert "window.PHASE_SETTINGS = {" in output.read_text(encoding="utf-8")
    assert built.read_text(encoding="utf-8").startswith("window.PHASE_SETTINGS = {")


def test_site_settings_resolves_labels_and_options() -> None:
    data = parse_settings(
        Path("resources/memory/high/generated/settings.xml"),
        Path("resources"),
        Path("manifest.xml.tmpl"),
    )

    groups = {group["id"]: group for group in data["groups"]}

    assert groups["Global"]["title"] == "Global"
    assert groups["Global"]["settings"][0]["key"] == "GlobalAccent"
    assert all(
        option["value"] != "-1"
        for setting in groups["Global"]["settings"]
        for option in setting["options"]
    )
    assert groups["Clock"]["title"] == "Clock"
    assert groups["Clock"]["region"] == "clock"
    assert groups["Clock"]["settings"][0]["title"] == "Foreground"
    assert groups["Clock"]["settings"][1]["key"] == "ClockShade"
    assert groups["Clock"]["settings"][1]["title"] == "Shade"
    assert groups["Clock"]["settings"][0]["options"][0] == {
        "value": "-1",
        "label": "Global",
    }
    assert groups["Clock"]["settings"][1]["options"][0] == {
        "value": "-1",
        "label": "Global",
    }

    size = next(
        setting for setting in groups["Clock"]["settings"] if setting["title"] == "Size"
    )

    assert size["key"] == "ClockSize"
    assert size["type"] == "list"
    assert size["options"][0] == {"value": "-1", "label": "Auto"}
    assert [option["label"] for option in size["options"]] == [
        "Auto",
        "Small",
    ]


def test_site_settings_preserves_metric_width_options_and_regions() -> None:
    data = parse_settings(
        Path("resources/memory/high/generated/settings.xml"),
        Path("resources"),
        Path("manifest.xml.tmpl"),
    )

    groups = {group["id"]: group for group in data["groups"]}
    top_middle = groups["TopMiddle"]
    settings = {setting["title"]: setting for setting in top_middle["settings"]}
    gauges = groups["Gauges"]["settings"]

    assert top_middle["region"] == "top"
    assert top_middle["title"] == "Top Metrics"
    assert top_middle["hasAlternative"] is False
    assert groups["TopOuter"]["region"] == "top_outer"
    assert groups["TopOuter"]["title"] == "Top"
    assert groups["TopOuter"]["settings"][0]["title"] == "Content"
    assert groups["BottomOuter"]["region"] == "bottom_outer"
    assert groups["BottomOuter"]["title"] == "Bottom"
    assert groups["BottomOuter"]["settings"][0]["title"] == "Content"
    assert groups["BottomMiddle"]["title"] == "Bottom Metrics"
    assert "TopMiddle0" not in groups
    assert "TopMiddleAlt0" not in groups
    assert "Status0" not in groups
    assert "Gauges0" not in groups
    assert "BottomMiddle0" not in groups
    assert "BottomMiddleAlt0" not in groups
    assert len(top_middle["settings"]) == 2
    assert [setting["title"] for setting in gauges] == ["Gauge N", "Gauge N Accent"]
    assert [setting["title"] for setting in groups["Status"]["settings"]] == [
        "Status N"
    ]
    assert [setting["title"] for setting in groups["BottomMiddle"]["settings"]] == [
        "Metric N",
        "Metric N Width",
    ]
    assert gauges[1]["options"][0] == {"value": "-1", "label": "Global"}
    assert settings["Metric N Width"]["type"] == "list"
    assert settings["Metric N Width"]["options"] == [
        {"label": "Auto", "value": "-1"},
        {"label": "None", "value": "0"},
        *({"label": str(width), "value": str(width)} for width in range(1, 11)),
    ]
    assert settings["Metric N"]["options"]
    assert settings["Metric N"]["options"][0]["label"] == "None"
    assert "Wind" in [option["label"] for option in settings["Metric N"]["options"]]


def test_metric_width_defaults_are_auto_in_every_memory_profile() -> None:
    for memory in ("low", "medium", "high"):
        settings = ET.parse(
            Path(f"resources/memory/{memory}/generated/settings.xml")
        ).getroot()
        properties = ET.parse(
            Path(f"resources/memory/{memory}/generated/properties.xml")
        ).getroot()
        widths = [
            prop
            for prop in properties.findall("property")
            if prop.get("id", "").startswith(("TopMiddleWidth", "BottomMiddleWidth"))
        ]

        assert len(widths) == (4 if memory == "low" else 8)
        assert all(
            prop.get("type") == "Number" and prop.text == "-1" for prop in widths
        )

        width_settings = [
            setting
            for setting in settings.iter("setting")
            if setting.get("propertyKey", "").startswith(
                ("@Properties.TopMiddleWidth", "@Properties.BottomMiddleWidth")
            )
        ]
        assert len(width_settings) == len(widths)
        for setting in width_settings:
            config = setting.find("settingConfig")
            assert config is not None and config.get("type") == "list"
            assert [entry.get("value") for entry in config.findall("listEntry")] == [
                "-1",
                *(str(width) for width in range(0, 11)),
            ]


def test_local_colors_can_inherit_from_global_in_every_memory_profile() -> None:
    for memory in ("low", "medium", "high"):
        settings = ET.parse(
            Path(f"resources/memory/{memory}/generated/settings.xml")
        ).getroot()
        global_group = settings.find("group[@id='Global']")
        assert global_group is not None
        assert all(
            entry.get("value") != "-1" for entry in global_group.iter("listEntry")
        )

        local_colors = [
            setting
            for setting in settings.iter("setting")
            if setting.get("propertyKey", "").startswith(
                (
                    "@Properties.ClockForeground",
                    "@Properties.ClockShade",
                    "@Properties.GaugesAccent",
                )
            )
        ]
        assert len(local_colors) == (5 if memory == "low" else 6)
        for setting in local_colors:
            config = setting.find("settingConfig")
            assert config is not None
            first = config.find("listEntry")
            assert first is not None
            assert first.get("value") == "-1"
            assert first.text == "@Strings.SETTING_GLOBAL"


def test_site_settings_collapses_alternatives_and_reads_numeric_ranges(
    tmp_path: Path,
) -> None:
    resources = tmp_path / "resources" / "base"
    resources.mkdir(parents=True)
    resources.joinpath("strings.xml").write_text(
        """
        <resources>
            <string id="SET_TOP_MIDDLE">Top Middle</string>
            <string id="SET_TOP_MIDDLE_ALTERNATIVE">Top Middle Alternative</string>
            <string id="SET_DATA">Data</string>
            <string id="SET_WIDTH">Width</string>
        </resources>
        """,
        encoding="utf-8",
    )

    settings_xml = tmp_path / "settings.xml"
    settings_xml.write_text(
        """
        <settings>
            <group id="TopMiddle0" title="@Strings.SET_TOP_MIDDLE">
                <setting propertyKey="@Properties.TopMiddleData0" title="@Strings.SET_DATA">
                    <settingConfig type="list" required="true" />
                </setting>
                <setting propertyKey="@Properties.TopMiddleWidth0" title="@Strings.SET_WIDTH">
                    <settingConfig type="numeric" min="1" max="9" required="true" />
                </setting>
            </group>
            <group
                id="TopMiddleAlternative0"
                title="@Strings.SET_TOP_MIDDLE_ALTERNATIVE"
            >
                <setting
                    propertyKey="@Properties.TopMiddleAlternativeData0"
                    title="@Strings.SET_DATA"
                >
                    <settingConfig type="list" required="true" />
                </setting>
            </group>
        </settings>
        """,
        encoding="utf-8",
    )

    manifest_xml = tmp_path / "manifest.xml"
    manifest_xml.write_text(
        """
        <iq:manifest version="3" xmlns:iq="http://www.garmin.com/xml/connectiq">
            <iq:application>
                <iq:products>
                    <iq:product id="fr255" />
                </iq:products>
                <iq:languages>
                    <iq:language>eng</iq:language>
                </iq:languages>
            </iq:application>
        </iq:manifest>
        """,
        encoding="utf-8",
    )

    data = parse_settings(settings_xml, tmp_path / "resources", manifest_xml)

    assert [group["id"] for group in data["groups"]] == ["TopMiddle"]
    assert data["groups"][0]["title"] == "Top Middle"
    assert data["groups"][0]["hasAlternative"] is True
    assert data["groups"][0]["settings"][1]["min"] == "1"
    assert data["groups"][0]["settings"][1]["max"] == "9"


def test_site_settings_includes_supported_devices_and_languages(tmp_path: Path) -> None:
    resources = tmp_path / "resources" / "base"
    resources.mkdir(parents=True)
    resources.joinpath("strings.xml").write_text("<resources />", encoding="utf-8")

    settings_xml = tmp_path / "settings.xml"
    settings_xml.write_text("<settings />", encoding="utf-8")

    manifest_xml = tmp_path / "manifest.xml"
    manifest_xml.write_text(
        """
        <iq:manifest version="3" xmlns:iq="http://www.garmin.com/xml/connectiq">
            <iq:application>
                <iq:products>
                    <iq:product id="fr255" />
                    <iq:product id="fenix7x" />
                </iq:products>
                <iq:languages>
                    <iq:language>deu</iq:language>
                    <iq:language>eng</iq:language>
                    <iq:language>fre</iq:language>
                    <iq:language>ita</iq:language>
                    <iq:language>pol</iq:language>
                    <iq:language>por</iq:language>
                    <iq:language>spa</iq:language>
                </iq:languages>
            </iq:application>
        </iq:manifest>
        """,
        encoding="utf-8",
    )

    data = parse_settings(settings_xml, tmp_path / "resources", manifest_xml)

    assert data["supportedDevices"] == [
        "Forerunner 255",
        "Fenix 7X / tactix 7 / quatix 7X / Enduro 2",
    ]
    assert data["supportedLanguages"] == [
        {"code": "deu", "name": "German"},
        {"code": "eng", "name": "English"},
        {"code": "fre", "name": "French"},
        {"code": "ita", "name": "Italian"},
        {"code": "pol", "name": "Polish"},
        {"code": "por", "name": "Portuguese"},
        {"code": "spa", "name": "Spanish"},
    ]
