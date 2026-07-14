#!/usr/bin/env python3
# Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import textwrap
from collections.abc import Sequence
from typing import Any

from data.settings import Array, Boolean, Entry, Number, Options, Select, Single
from scripts.utils.mc_document import McDocument, McScope
from scripts.utils.xml_document import XmlDocument

Top = Single | Array
Widget = Single | list[Entry]


def render_data_mc(data: Any) -> str:
    doc = McDocument.create()
    doc.line("import Toybox.Lang;")
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

    return doc.render()


def render_widgets_mc(extra_data: Any) -> str:
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

                    if datum_name == "Disabled":
                        continue

                    doc.line(
                        f"case {datum.value}: return new {datum_name}("
                        f"_properties, _on_top"
                        ");"
                    )

                doc.line()
                doc.line("default: return new Widgets.Base(null);")

    return doc.render()


def render_properties_mc(  # pylint: disable=too-many-branches,too-many-locals,too-many-statements
    settings: Sequence[Single | Array],
) -> str:
    doc = McDocument.create()
    doc.line("import Toybox.Application;")
    doc.line("import Toybox.Lang;")
    with McScope(doc, "module Properties {") as _module:
        for opt in Options:
            doc.line(f"const {opt.name.upper()} = {opt.value};")

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
                with McScope(
                    doc,
                    f"var {single_or_array.variable} as {single_or_array.klass} = "
                    f"new {single_or_array.klass}(",
                    ";",
                ) as _field:
                    for idx, entry in enumerate(single_or_array):
                        comma = "," if idx != len(single_or_array) - 1 else ""
                        doc.line(f"{str(entry.default).lower()}{comma}")
                continue

            if isinstance(single_or_array, Array):
                with McScope(
                    doc,
                    f"var {single_or_array.variable} as Lang.Array<{single_or_array.klass}> = [",
                    ";",
                ) as _field:
                    for idx, widget in enumerate(single_or_array):
                        with McScope(
                            doc,
                            f"new {single_or_array.klass}(",
                            "," if idx != len(single_or_array) - 1 else "",
                        ) as _entry:
                            for idx, entry in enumerate(widget):
                                comma = "," if idx != len(widget) - 1 else ""
                                doc.line(f"{str(entry.default).lower()}{comma}")
                continue

            assert False, f"Unsupported type {type(single_or_array)}"

        doc.line("// refresh")

        with McScope(doc, "function refresh() as Void {") as _refresh:
            for single_or_array in settings:

                def render_widget(
                    top: Top, widget: Widget, idx: int | None = None
                ) -> None:
                    arr_id = f"[{idx}]" if idx is not None else ""
                    prop_id = f"{idx}" if idx is not None else ""

                    for entry in widget:
                        if entry.hidden:
                            continue

                        doc.line(
                            f"self.{top.variable}{arr_id}.{entry.variable} = "
                            "Application.Properties.getValue("
                            f'"{top.id}{entry.id}{prop_id}") '
                            f"as Lang.{entry.klass};"
                        )

                if isinstance(single_or_array, Single):
                    render_widget(single_or_array, single_or_array)
                    continue

                if isinstance(single_or_array, Array):
                    for idx, widget in enumerate(single_or_array):
                        render_widget(single_or_array, widget, idx)
                    continue

                assert False, f"Unsupported type {type(single_or_array)}"

    return doc.render()


def render_properties_xml(settings: Sequence[Single | Array]) -> str:
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


def render_settings_xml(settings: Sequence[Single | Array]) -> str:
    root = XmlDocument.resource("settings")

    for single_or_array in settings:

        def render_widget(top: Top, widget: Widget, idx: int | None = None) -> None:
            prop_id = f"{idx}" if idx is not None else ""

            group_xml = root.subelement(
                root.root,
                "group",
                id=f"{top.id}{prop_id}",
                title=f"@Strings.{top.label}",
            )

            for entry in widget:
                if entry.hidden:
                    continue

                setting = root.subelement(
                    group_xml,
                    "setting",
                    propertyKey=f"@Properties.{top.id}{entry.id}{prop_id}",
                    title=f"@Strings.{entry.label}",
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
                        list_entry.text = f"@Strings.{option.label}"
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
