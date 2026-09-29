# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

"""Read data shared by build and website tools from a Connect IQ manifest."""

import xml.etree.ElementTree as ET
from pathlib import Path

CONNECT_IQ_NAMESPACE = {"iq": "http://www.garmin.com/xml/connectiq"}


def supported_connect_iq_ids(manifest_xml: Path) -> list[str]:
    """Return supported product IDs in manifest order."""
    root = ET.parse(manifest_xml).getroot()
    return [
        product_id
        for product in root.findall(".//iq:products/iq:product", CONNECT_IQ_NAMESPACE)
        if (product_id := product.get("id"))
    ]
