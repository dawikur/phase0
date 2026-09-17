#!/usr/bin/env python3
# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import textwrap
from collections.abc import Iterable
from enum import IntEnum
from typing import Any

from data.settings import Array, Boolean, Entry, Number, Options, Select, Single
from scripts.utils.mc_document import McDocument, McScope
from scripts.utils.xml_document import XmlDocument

Top = Single | Array
Widget = Single | list[Entry]


def render_data_mc(data: Any) -> str:
    doc = McDocument.create()
    doc.line("import Toybox.Lang;")
    doc.line("import Toybox.Test;")
    with McScope(doc, "module Data {") as _module:
        with McScope(doc, "function get(_id as Lang.Number) as Base? {") as _get:
            with McScope(doc, "switch (_id) {") as _switch:
                for datum in data:
                    datum_name = "".join(
                        part.capitalize() for part in datum.name.split("_")
                    )
                    doc.line(f"case {datum.value}: return new {datum_name}();")

                doc.line()
                doc.line("default: return null;")

        doc.line("(:test)")
        with McScope(
            doc, "function SmokeTest(_logger as Test.Logger) as Lang.Boolean {"
        ) as _smoke_test:
            with McScope(doc, "for (var i = 1; ; ++i) {") as _for:
                doc.line("var data = Data.get(i);")
                with McScope(doc, "if (data == null) {") as _if:
                    doc.line("break;")

                doc.line("data.refresh();")
                doc.line("data.refreshRevision();")

            doc.line("return true;")

    return doc.render()


def render_widgets_mc(extra_data: type[IntEnum]) -> str:
    doc = McDocument.create()
    doc.line("import Toybox.Complications;")
    doc.line("import Toybox.Lang;")
    with McScope(doc, "module Widgets {") as _module:
        with McScope(
            doc,
            "function get("
            "_properties as Properties.Widget, _on_top as Lang.Boolean"
            ") as Base {",
        ) as _get:
            with McScope(doc, "switch (_properties.data) {") as _switch:
                for datum in extra_data:
                    datum_name = "".join(
                        part.capitalize() for part in datum.name.split("_")
                    )

                    if datum_name == "None":
                        continue

                    doc.line(
                        f"case Properties.DATA_{datum.name.upper()}: return new {datum_name}("
                        f"_properties, _on_top"
                        ");"
                    )

                doc.line()
                doc.line("default: return Widgets.Base.None();")

    return doc.render()


def render_properties_mc(  # pylint: disable=too-many-branches,too-many-locals,too-many-statements
    settings: Iterable[Single | Array],
    extra_data: type[IntEnum],
    annotation: str,
) -> str:
    doc = McDocument.create()
    doc.line("import Toybox.Application;")
    doc.line("import Toybox.Lang;")
    doc.line()
    doc.line(f"(:{annotation})")
    with McScope(doc, "class Properties {") as _module:
        doc.line()
        doc.line("// options")
        doc.line()

        for opt in Options:
            doc.line(f"static const {opt.name.upper()} = {opt.value};")

        doc.line()
        doc.line("// extra data")
        doc.line()

        for datum in extra_data:
            if datum.name == "Disabled":
                continue

            doc.line(f"static const DATA_{datum.name.upper()} = {datum.value};")

        doc.line()
        doc.line("// fields")
        doc.line()

        generated_klasses: dict[str, list[str]] = {}

        for single_or_array in settings:
            entries = []
            if isinstance(single_or_array, Single):
                entries = single_or_array.entries
            if isinstance(single_or_array, Array):
                entries = single_or_array[0]

            klass_entries = list(
                f"{entry.variable}: {entry.klass}" for entry in entries
            )

            if single_or_array.klass in generated_klasses:
                assert (
                    generated_klasses[single_or_array.klass] == klass_entries
                ), textwrap.dedent(
                    f"""\
                        Klass mismatch '{single_or_array.klass}'
                        Expected: {generated_klasses[single_or_array.klass]}
                             Got: {klass_entries}
                        """
                )
            else:
                generated_klasses[single_or_array.klass] = klass_entries

                with McScope(doc, f"class {single_or_array.klass} {{") as _class:
                    for entry in entries:
                        doc.line(f"var {entry.variable} as Lang.{entry.klass};")

                    with McScope(doc, "function initialize(") as _args:
                        for idx, entry in enumerate(entries):
                            comma = "," if idx != len(entries) - 1 else ""
                            doc.line(f"_{entry.variable} as Lang.{entry.klass}{comma}")

                    with McScope(doc, "{") as _body:
                        for entry in entries:
                            doc.line(f"self.{entry.variable} = _{entry.variable};")

            if isinstance(single_or_array, Single):
                doc.line(f"var {single_or_array.variable} as {single_or_array.klass};")
                continue

            if isinstance(single_or_array, Array):
                doc.line(
                    f"var {single_or_array.variable} as Lang.Array<{single_or_array.klass}>;"
                )
                continue

            assert False, f"Unsupported type {type(single_or_array)}"

        with McScope(doc, "function initialize() {") as _refresh:
            for single_or_array in settings:

                def render_widget(
                    top: Top, widget: Widget, widget_idx: int | None = None
                ) -> None:
                    prop_id = f"{widget_idx}" if widget_idx is not None else ""

                    for entry_idx, entry in enumerate(widget):
                        comma = "," if entry_idx != len(widget) - 1 else ""

                        if entry.hidden:
                            doc.line(f"{str(entry.default).lower()}{comma}")
                        else:
                            doc.line(
                                "Application.Properties.getValue("
                                f'"{top.id}{entry.id}{prop_id}") '
                                f"as Lang.{entry.klass}{comma}"
                            )

                if isinstance(single_or_array, Single):
                    with McScope(
                        doc,
                        f"self.{single_or_array.variable} = "
                        f"new {single_or_array.klass}(",
                        ";",
                    ) as _field:
                        render_widget(single_or_array, single_or_array)
                    continue

                if isinstance(single_or_array, Array):
                    with McScope(
                        doc,
                        f"self.{single_or_array.variable} = [",
                        ";",
                    ) as _field:
                        for idy, widget in enumerate(single_or_array):
                            with McScope(
                                doc,
                                f"new {single_or_array.klass}(",
                                "," if idy != len(single_or_array) - 1 else "",
                            ) as _entry:
                                render_widget(single_or_array, widget, idy)
                    continue

                assert False, f"Unsupported type {type(single_or_array)}"

    return doc.render()


def render_properties_xml(settings: Iterable[Single | Array]) -> str:
    root = XmlDocument.resource("properties")

    for single_or_array in settings:

        def render_widget(top: Top, widget: Widget, idx: int | None = None) -> None:
            prop_id = f"{idx}" if idx is not None else ""

            for entry in widget:
                if entry.hidden:
                    continue

                property_ = root.subelement(
                    root.root,
                    "property",
                    id=f"{top.id}{entry.id}{prop_id}",
                    type=entry.klass,
                )
                property_.text = str(entry.default)

        if isinstance(single_or_array, Single):
            render_widget(single_or_array, single_or_array)
            continue

        if isinstance(single_or_array, Array):
            for idx, widget in enumerate(single_or_array):
                render_widget(single_or_array, widget, idx)
            continue

        assert False, f"Unsupported type {type(single_or_array)}"

    return root.render()


def render_settings_xml(settings: Iterable[Single | Array]) -> str:
    root = XmlDocument.resource("settings")

    for single_or_array in settings:

        def render_widget(top: Top, widget: Widget, idx: int | None = None) -> None:
            prop_id = f"{idx}" if idx is not None else ""

            group_xml = root.subelement(
                root.root,
                "group",
                id=f"{top.id}{prop_id}",
                title=f"@Strings.{top.setting}",
            )

            for entry in widget:
                if entry.hidden:
                    continue

                setting = root.subelement(
                    group_xml,
                    "setting",
                    propertyKey=f"@Properties.{top.id}{entry.id}{prop_id}",
                    title=f"@Strings.{entry.setting}",
                )

                if isinstance(entry, Select):
                    setting_config = root.subelement(
                        setting,
                        "settingConfig",
                        type="list",
                        required="true",
                    )

                    for option, value in entry.options.items():
                        list_entry = root.subelement(
                            setting_config,
                            "listEntry",
                            value=value,
                        )
                        list_entry.text = f"@Strings.{option.setting}"
                    continue

                if isinstance(entry, Number):
                    setting_config = root.subelement(
                        setting,
                        "settingConfig",
                        type="numeric",
                        min="0",
                        max="10",
                        required="true",
                    )
                    continue

                if isinstance(entry, Boolean):
                    setting_config = root.subelement(
                        setting,
                        "settingConfig",
                        type="boolean",
                        required="true",
                    )
                    continue

                assert False, f"Unsupported type {type(entry)}"

        if isinstance(single_or_array, Single):
            render_widget(single_or_array, single_or_array)
            continue

        if isinstance(single_or_array, Array):
            for idx, widget in enumerate(single_or_array):
                render_widget(single_or_array, widget, idx)
            continue

        assert False, f"Unsupported type {type(single_or_array)}"

    return root.render()
