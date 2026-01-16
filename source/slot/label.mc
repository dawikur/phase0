// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Slot {

typedef Data as Lang.Dictionary<Lang.Symbol, Lang.Object>;

class Style {
	var typeface as Font.Typeface;
	var style as Font.Style;
	var color as Lang.Number;

	function initialize(
		_typeface as Font.Typeface,
		_style as Font.Style,
		_color as Lang.Number
	) {
		self.typeface = _typeface;
		self.style = _style;
		self.color = _color;
	}
}

class Label {
	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;
	var size_x as Lang.Number = 0;
	var size_y as Lang.Number = 0;

	var label as Lang.String = "";

	var styles as Lang.Array<Style> = [];

	function initialize() {
	}

	function render(_dc as Graphics.Dc) as Void {
		if (self.label == "") {
			return;
		}

		for (var i = 0; i < self.styles.size(); ++i) {
			var style = self.styles[i];

			_dc.setColor(style.color, Graphics.COLOR_TRANSPARENT);
			style.typeface.render(_dc, self.pos_x, self.pos_y, self.label, style.style);
		}
	}

	function refresh() as Void;
}

} // module Slot
