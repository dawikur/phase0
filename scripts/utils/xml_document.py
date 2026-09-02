# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import xml.etree.ElementTree as ET

from .common import copyright_lines

XSI_NAMESPACE = "http://www.w3.org/2001/XMLSchema-instance"
SVG_NAMESPACE = "http://www.w3.org/2000/svg"
RESOURCE_SCHEMA = "https://developer.garmin.com/downloads/connect-iq/resources.xsd"

ET.register_namespace("xsi", XSI_NAMESPACE)
ET.register_namespace("", SVG_NAMESPACE)


class XmlDocument:
    root: ET.Element
    comments: list[str] | tuple[str, ...] | None

    def __init__(
        self,
        root: ET.Element,
        comments: list[str] | tuple[str, ...] | None = None,
    ) -> None:
        self.root = root
        self.comments = comments

    @classmethod
    def create(
        cls,
        root: ET.Element,
        comments: list[str] | tuple[str, ...] | None = None,
    ) -> "XmlDocument":
        return cls(root=root, comments=comments)

    @classmethod
    def resource(
        cls,
        tag: str,
        comments: list[str] | tuple[str, ...] | None = None,
    ) -> "XmlDocument":
        root = ET.Element(tag)
        root.set(f"{{{XSI_NAMESPACE}}}noNamespaceSchemaLocation", RESOURCE_SCHEMA)
        return cls.create(root, comments)

    @classmethod
    def svg(cls, width: int, height: int) -> "XmlDocument":
        root = ET.Element(
            f"{{{SVG_NAMESPACE}}}svg",
            width=str(width),
            height=str(height),
            viewBox=f"0 0 {width} {height}",
        )
        return cls.create(root, comments=())

    @staticmethod
    def element(tag: str, **attributes: str) -> ET.Element:
        return ET.Element(tag, attributes)

    @staticmethod
    def subelement(parent: ET.Element, tag: str, **attributes: str) -> ET.Element:
        return ET.SubElement(parent, tag, attributes)

    def render(
        self,
        *,
        comments: list[str] | tuple[str, ...] | None = None,
        blank_line_after_comments: bool = True,
        blank_lines_between_root_children: bool = False,
    ) -> str:
        ET.indent(self.root, space="\t")
        if blank_lines_between_root_children and len(self.root):
            for child in self.root[:-1]:
                child.tail = "\n\n\t"
            self.root[-1].tail = "\n\n"

        body = ET.tostring(self.root, encoding="unicode", short_empty_elements=True)

        if comments is None:
            comments = self.comments
        if comments is None:
            comments = copyright_lines()

        if not comments:
            return body

        prefix = "\n".join(f"<!-- {line} -->" for line in comments) + "\n"
        if blank_line_after_comments:
            prefix += "\n"
        return prefix + body
