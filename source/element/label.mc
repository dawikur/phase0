// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

module Element {

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
	var label as Lang.String = "";

	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;

	var padding_x as Lang.Number = 0;

	var styles as Lang.Array<Style> = [];

	function initialize() {
	}

	function render(_dc as Graphics.Dc) as Void {
		if (self.label == "") {
			self.refresh();
		}

		if (self.label == "") {
			return;
		}

		var styles = self.styles;
		var styles_size = styles.size();
		var pos_x = self.pos_x + self.padding_x;
		var pos_y = self.pos_y;
		var label = self.label;

		for (var i = 0; i < styles_size; ++i) {
			var style = styles[i];

			_dc.setColor(style.color, Graphics.COLOR_TRANSPARENT);
			style.typeface.render(_dc, pos_x, pos_y, label, style.style);
		}
	}

	function refresh() as Void {
		self.label = self.get_();
	}

	function get_() as Lang.String {
		return "";
	}
}

} // module Element
