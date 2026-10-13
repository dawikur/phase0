# Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

from pathlib import Path

import pytest
from PIL import Image

from scripts.utils.args_parse import Folders
from scripts.utils.burn_in import (
    find_cycle,
    generate_burn_in,
    minimal_masks,
    translate,
    with_shadow,
)
from scripts.utils.font_generation import generate_fonts


def test_three_diagonal_positions_leave_a_lit_pixel() -> None:
    square = frozenset((x, y) for x in range(3) for y in range(3))
    assert frozenset.intersection(*(translate(square, (p, p)) for p in (-1, 0, 1))) == {
        (1, 1)
    }
    with pytest.raises(ValueError, match="No burn-in cycle"):
        find_cycle([square], max_offset=1)
    cycle = find_cycle([square])
    assert not frozenset.intersection(*(translate(square, offset) for offset in cycle))
    assert 2 <= len(cycle) <= 4
    assert all(abs(x) <= 2 and abs(y) <= 2 for x, y in cycle)
    assert find_cycle([square]) == cycle


@pytest.mark.parametrize(
    "masks, limit", [([], 2), ([frozenset()], 2), ([frozenset({(0, 0)})], -1)]
)
def test_invalid_search_inputs(masks, limit) -> None:
    with pytest.raises(ValueError, match="Expected nonempty"):
        find_cycle(masks, limit)


def test_shadow_is_part_of_the_lit_mask() -> None:
    assert with_shadow(frozenset({(0, 0)}), 1) == {(0, 0), (1, 1)}
    assert translate(frozenset({(-3, -4)}), (2, 1)) == {(-1, -3)}
    with pytest.raises(ValueError, match="No burn-in cycle"):
        find_cycle([frozenset({(-3, -4)})], max_offset=0)


def test_generation_recomputes_cycle_from_actual_amoled_fonts(tmp_path: Path) -> None:
    folders = Folders(tmp_path / "build", tmp_path / "resources", tmp_path / "source")
    generate_fonts(folders, "0123456789dhm")
    output = folders.source("generated", "burn_in.mc")
    original = output.read_text()
    icons_folder = folders.resources("memory/high/generated/fonts/amoled")
    cycle = generate_burn_in(
        folders.resources("fonts/amoled/generated"), output, 1, icons_folder
    )
    assert output.read_text() == original
    assert len(cycle) == 4
    masks = minimal_masks(folders.resources("fonts/amoled/generated"), 1, icons_folder)
    assert all(
        not frozenset.intersection(*(translate(mask, offset) for offset in cycle))
        for mask in masks
    )
    assert "const PHASE_COUNT = 4;" in original
    assert "Lang.Array<Lang.Number>" in original
    # An incompatible replacement atlas must stop generation, without
    # overwriting a previously validated set of offsets.

    atlas_path = folders.resources("fonts/amoled/generated", "digits_regular.png")
    with Image.open(atlas_path) as atlas:
        Image.new("1", atlas.size, 1).save(atlas_path)
    with pytest.raises(ValueError, match="No burn-in cycle"):
        generate_burn_in(
            folders.resources("fonts/amoled/generated"), output, 1, icons_folder
        )
    assert output.read_text() == original
