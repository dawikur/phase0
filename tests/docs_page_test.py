# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

from html.parser import HTMLParser
from pathlib import Path


class DocsParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.tags: list[tuple[str, dict[str, str | None]]] = []

    def handle_starttag(
        self,
        tag: str,
        attrs: list[tuple[str, str | None]],
    ) -> None:
        self.tags.append((tag, dict(attrs)))


def parse_docs_page() -> DocsParser:
    parser = DocsParser()
    parser.feed(Path("docs/index.html").read_text(encoding="utf-8"))
    return parser


def attrs_for(
    parser: DocsParser,
    tag: str,
    attr: str,
    value: str,
) -> dict[str, str | None]:
    matches = [
        attrs
        for item_tag, attrs in parser.tags
        if item_tag == tag and attrs.get(attr) == value
    ]

    assert matches, f"Missing <{tag} {attr}={value!r}>"
    return matches[0]


def values_for(
    parser: DocsParser,
    tag: str,
    attr: str,
) -> list[str]:
    return [
        value
        for item_tag, attrs in parser.tags
        if item_tag == tag
        for value in [attrs.get(attr)]
        if value is not None
    ]


def test_docs_page_loads_assets_in_expected_order() -> None:
    parser = parse_docs_page()

    assert values_for(parser, "script", "src") == [
        "settings-data.js",
        "theme.js",
        "app.js",
    ]
    assert "styles.css" in values_for(parser, "link", "href")
    assert "assets/icon.svg" in values_for(parser, "link", "href")

    assert Path("docs/theme.js").is_file()
    assert Path("docs/styles.css").is_file()
    assert Path("docs/app.js").is_file()


def test_docs_page_links_to_mip64_palette() -> None:
    parser = parse_docs_page()

    assert attrs_for(parser, "a", "href", "mip64-palette/")["class"] == (
        "action-link action-link--primary"
    )


def test_docs_page_exposes_theme_view_and_accessible_regions() -> None:
    parser = parse_docs_page()

    assert values_for(parser, "button", "data-theme-mode") == [
        "auto",
        "light",
        "dark",
    ]
    assert values_for(parser, "button", "data-watch-view") == ["normal", "aod"]

    assert attrs_for(parser, "section", "class", "hero")["aria-labelledby"] == (
        "page-title"
    )
    assert attrs_for(parser, "p", "id", "pageLede")["class"] == "lede"
    assert attrs_for(parser, "aside", "id", "detailPanel").get("aria-live") is None
    assert attrs_for(parser, "div", "class", "theme-control")["role"] == "group"
    assert attrs_for(parser, "div", "class", "view-control")["role"] == "group"
    assert attrs_for(parser, "article", "id", "supportCard")["class"] == "support-card"
    assert "support-list" in (
        attrs_for(parser, "ul", "id", "supportedDevices")["class"] or ""
    )
    assert (
        attrs_for(parser, "ul", "id", "supportedLanguages")["class"] == "support-list"
    )
    assert attrs_for(parser, "p", "id", "languageTranslationNote")["class"] == (
        "support-note"
    )


def test_docs_page_hotspots_match_documented_features() -> None:
    parser = parse_docs_page()

    assert values_for(parser, "button", "data-feature") == [
        "general",
        "top",
        "status",
        "clock",
        "gauges",
        "bottom",
        "battery",
    ]

    for feature in values_for(parser, "button", "data-feature"):
        hotspot = attrs_for(parser, "button", "data-feature", feature)
        assert hotspot["class"] == "hotspot"
        aria_label = hotspot["aria-label"]
        assert aria_label is not None
        assert aria_label.startswith("Explore ")
        assert hotspot["aria-controls"] == "detailPanel"


def test_docs_page_watch_images_have_stable_ids_sources_and_alt_text() -> None:
    parser = parse_docs_page()

    watch_face = attrs_for(parser, "img", "id", "watchFace")
    assert watch_face["src"] == "assets/normal.png"
    assert watch_face["alt"] == "phase0 normal watch face"

    overlay_sources = {
        attrs["src"]
        for tag, attrs in parser.tags
        if tag == "img" and "watch-overlay" in (attrs.get("class") or "")
    }

    assert overlay_sources == {
        "assets/fr955-light.png",
        "assets/fr955-dark.png",
    }


def test_docs_alternative_metric_copy_matches_source_wiring() -> None:
    docs_js = Path("docs/app.js").read_text(encoding="utf-8")

    assert "long-pressing the clock switches" in docs_js
