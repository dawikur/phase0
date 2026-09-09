# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from pathlib import Path

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
    assert setting_region("General") == "theme"
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
        Path("manifest.xml"),
    )

    groups = {group["id"]: group for group in data["groups"]}

    assert groups["Clock"]["title"] == "Clock"
    assert groups["Clock"]["region"] == "clock"
    assert groups["Clock"]["settings"][0]["title"] == "Foreground"

    height = next(
        setting
        for setting in groups["Clock"]["settings"]
        if setting["title"] == "Height"
    )

    assert height["type"] == "list"
    assert [option["label"] for option in height["options"]] == [
        "Auto",
        "Small",
    ]


def test_site_settings_preserves_numeric_boolean_and_regions() -> None:
    data = parse_settings(
        Path("resources/memory/high/generated/settings.xml"),
        Path("resources"),
        Path("manifest.xml"),
    )

    groups = {group["id"]: group for group in data["groups"]}
    top_middle = groups["TopMiddle"]
    settings = {setting["title"]: setting for setting in top_middle["settings"]}

    assert top_middle["region"] == "top"
    assert top_middle["hasAlternative"] is False
    assert groups["BottomOuter"]["region"] == "battery"
    assert "TopMiddle0" not in groups
    assert "TopMiddleAlt0" not in groups
    assert "Status0" not in groups
    assert "Gauges0" not in groups
    assert "BottomMiddle0" not in groups
    assert "BottomMiddleAlt0" not in groups
    assert settings["Width"]["type"] == "numeric"
    assert settings["Width"]["min"] == "0"
    assert settings["Width"]["max"] == "10"
    assert settings["Data"]["options"]
    assert settings["Data"]["options"][0]["label"] == "None"
    assert "Wind" in [option["label"] for option in settings["Data"]["options"]]


def test_site_settings_collapses_alternative_middle_groups(tmp_path: Path) -> None:
    resources = tmp_path / "resources" / "base"
    resources.mkdir(parents=True)
    resources.joinpath("strings.xml").write_text(
        """
        <resources>
            <string id="SET_TOP_MIDDLE">Top Middle</string>
            <string id="SET_TOP_MIDDLE_ALTERNATIVE">Top Middle Alternative</string>
            <string id="SET_DATA">Data</string>
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
