# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from pathlib import Path

from scripts.utils.docs_settings import parse_settings


def test_docs_settings_resolves_labels_and_options() -> None:
    data = parse_settings(
        Path("resources/generated/settings.xml"),
        Path("resources"),
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
        "Large",
        "Small",
    ]


def test_docs_settings_preserves_numeric_boolean_and_regions() -> None:
    data = parse_settings(
        Path("resources/generated/settings.xml"),
        Path("resources"),
    )

    groups = {group["id"]: group for group in data["groups"]}
    top_middle = groups["TopMiddle"]
    settings = {setting["title"]: setting for setting in top_middle["settings"]}

    assert top_middle["region"] == "top"
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
    assert settings["Data"]["options"][0]["label"] == "Disabled"
    assert "Wind Bearing" in [option["label"] for option in settings["Data"]["options"]]


def test_docs_settings_collapses_alternative_middle_groups(tmp_path: Path) -> None:
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

    data = parse_settings(settings_xml, tmp_path / "resources")

    assert [group["id"] for group in data["groups"]] == ["TopMiddle"]
    assert data["groups"][0]["title"] == "Top Middle"
