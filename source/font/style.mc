// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Lang;

module Font {

class Style {
	var size as Lang.Number;
	var weight as Lang.Number;

	function initialize(_size as Lang.Number, _weight as Lang.Number) {
		self.size = _size;
		self.weight = _weight;
	}
}

const STYLE_REGULAR_BOLD = new Style(3, 3);
const STYLE_REGULAR      = new Style(3, 2);
const STYLE_REGULAR_THIN = new Style(3, 1);

const STYLE_SMALL_BOLD = new Style(2, 2);
const STYLE_SMALL      = new Style(2, 1);

const STYLE_MICRO = new Style(1, 1);

} // module Font
