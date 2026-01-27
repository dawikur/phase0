// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

module Label {

class Style {
	var font as WatchUi.FontResource;
	var color as Lang.Number;

	function initialize(
		_font as WatchUi.FontResource,
		_color as Lang.Number
	) {
		self.font = _font;
		self.color = _color;
	}
}

class Base {
	var pos_x as Lang.Number = 0;
	var pos_y as Lang.Number = 0;
	var justify as Lang.Number = 0;

	var styles as Lang.Array<Style> = [];

	var label_ as Lang.String = "";

	function initialize() {
	}

	function render(_dc as Graphics.Dc) as Void {
		if (self.label_ == "") {
			self.refresh(_dc);
		}

		if (self.label_ == "") {
			return;
		}

		var label = self.label_;

		var pos_x = self.pos_x;
		var pos_y = self.pos_y;
		var justify = self.justify;

		var styles = self.styles;
		var styles_size = styles.size();

		for (var i = 0; i < styles_size; ++i) {
			var style = styles[i];

			_dc.setColor(style.color, Graphics.COLOR_TRANSPARENT);
			_dc.drawText(pos_x, pos_y, style.font, label, justify);
		}
	}

	function refresh(_dc as Graphics.Dc) as Void {
		self.label_ = self.get_();
	}

	// implement this
	function get_() as Lang.String {
		return "";
	}
}

} // module Label
